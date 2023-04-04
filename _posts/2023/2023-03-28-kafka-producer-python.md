---
layout: post
title: Python Kafka Producer
date: 2023-03-28
categories: [Kafka]
---

`kafka.KafkaProducer`는 kafka 클러스터에 record를 publish하는 Kafka 클라이언트이다.

## Source Code
보통 Producer는 여러 스레드에서 하나의 인스턴스를 공유하는 것이 여러 인스턴스를 생성해서 사용하는 것보다 빠르다.

Kafka Producer는 record를 저장하는 buffer 공간과 클러스터로 record를 전송하는 backgroud I/O 스레드로 구성된다.
### buffer usage

정해진 `batch_size`만큼 producer는 각 파티션의 아직 전송되지 않은 record를 buffer에 유지한다. 사이즈를 크게 하면 한번에 더 많은 데이터를 보낼 수 있으나, 메모리 사용량이 늘어날 수 있다. default는 16KiB(16384)이다.

초기화할 때 `kafka.KafkaProducer` 내부적으로 ` self._accumulator = RecordAccumulator(message_version=message_version, metrics=self._metrics, **self.config)`를 실행하여 `RecordAccumulator` 인스턴스로 서버로 전송할 메시지로 큐로 관리한다.

메시지를 발행할 때 `producer.send(self.topic, msg)`를 실행한다.

`send` 로직은 대략 아래와 같다.
```python
    """
    Returns:
                FutureRecordMetadata: resolves to RecordMetadata
    """            
            partition = self._partition(topic, partition, key, value,
                                        key_bytes, value_bytes)
            ...

            tp = TopicPartition(topic, partition)
            ...
            result = self._accumulator.append(tp, timestamp_ms,
                                              key_bytes, value_bytes, headers,
                                              self.config['max_block_ms'],
                                              estimated_size=message_size)
            future, batch_is_full, new_batch_created = result
            if batch_is_full or new_batch_created:
                log.debug("Waking up the sender since %s is either full or getting a new batch", tp)
                self._sender.wakeup()

            return future
```
전송할 메시지와 그에 할당된 토픽 파티션을 매개변수로 `send`를 실행한다. 

`self._accumulator.append`는 메시지를 추가하고 결과를 반환한다. 결과에는 future metadata가 포함되어 배치가 꽉 찼는지, 배치가 새로 생성되었는지에 대한 flag를 포함한다. 대략적인 로직은 아래와 같다.
```python
        """
        Returns:
                tuple: (future, batch_is_full, new_batch_created)
        """         
        try:
            # 토픽 파티션에 lock을 걸어준다
            if tp not in self._tp_locks:
                with self._tp_locks[None]:
                    if tp not in self._tp_locks:
                        self._tp_locks[tp] = threading.Lock()

            with self._tp_locks[tp]:
                # 현재 진행중인 배치가 있는지 확인하여 적용한다.
                dq = self._batches[tp]
                if dq:
                    last = dq[-1]
                    future = last.try_append(timestamp_ms, key, value, headers)
                    # future metadata가 있으면 바로 결과를 반환한다.
                    if future is not None:
                        batch_is_full = len(dq) > 1 or last.records.is_full()
                        return future, batch_is_full, False

            # 메모리를 할당한다.
            size = max(self.config['batch_size'], estimated_size)
            log.debug("Allocating a new %d byte message buffer for %s", size, tp)
            buf = self._free.allocate(size, max_time_to_block_ms)
            with self._tp_locks[tp]:
                # dequeue lock을 획득한 이후에 producer가 닫혔는지 확인한다.
                assert not self._closed, 'RecordAccumulator is closed'

                if dq:
                    last = dq[-1]
                    future = last.try_append(timestamp_ms, key, value, headers)
                    if future is not None:
                        # future metadata가 있으면 메모리를 해제하고 결과를 반환한다.
                        self._free.deallocate(buf)
                        batch_is_full = len(dq) > 1 or last.records.is_full()
                        return future, batch_is_full, False

                records = MemoryRecordsBuilder(
                    self.config['message_version'],
                    self.config['compression_attrs'],
                    self.config['batch_size']
                )
                
                # 현재 진행 중인 배치가 없으므로(if dq에서 걸러짐) 배치를 새로 생성하여 dequeue에 추가한다.
                batch = ProducerBatch(tp, records, buf)
                future = batch.try_append(timestamp_ms, key, value, headers)
                if not future:
                    raise Exception()

                dq.append(batch)
                self._incomplete.add(batch)
                batch_is_full = len(dq) > 1 or batch.records.is_full()
                return future, batch_is_full, True
        finally:
            self._appends_in_progress.decrement()
```

### send message
`kafka.KafkaProducer`를 초기화할 때 메시지를 전송하기 위한 `Sender` 인스턴스를 생성하면서 비동기 요청 및 응답에 대응하는 네트워크 I/O를 위한 `KafkaClient`를 생성한다.

```python
        client = KafkaClient(metrics=self._metrics, metric_group_prefix='producer',
                                    wakeup_timeout_ms=self.config['max_block_ms'],
                                    **self.config)
        ...
        self._sender = Sender(client, self._metadata,
                              self._accumulator, self._metrics,
                              guarantee_message_order=guarantee_message_order,
                              **self.config)
```
`KafkaClient`는 특정 노드에 요청을 보내는 클래스이고, 실제 네트워크 I/O는 socket으로 데이터를 read/write하는 함수인 `.poll()` 호출로 발생한다. 

`KafkaClient.send` 내부적으로 다음과 같이 명시되어 있다. 네트워크 I/O는 `send_pending_requests`를 호출하여 트리거하는데, 실제로는 `send_pending_requests_v2`를 실행하는 것으로 보인다.

```python
        # conn.send will queue the request internally
        # we will need to call send_pending_requests()
        # to trigger network I/O
        future = conn.send(request, blocking=False)
        self._sending.add(conn)
```

`send_pending_requests_v2`는 non-blocking I/O를 통해 요청을 전송한다. non-block I/O 방식으로 처리가 완료되지 않으면 에러를 발생시켜 block 상태를 만들지 않는다.
```python
 def send_pending_requests_v2(self):
        """Attempts to send pending requests messages via non-blocking IO
        If all requests have been sent, return True
        Otherwise, if the socket is blocked and there are more bytes to send,
        return False.
        """
        try:
            with self._lock:
                if not self._can_send_recv():
                    return False

                # _protocol.send_bytes()에서 인코딩된 요청을 반환하고, 실제로 _send_bytes()로 전송한다. 남은 바이트는 _send_buffer로 홀드
                if not self._send_buffer:
                    self._send_buffer = self._protocol.send_bytes()

                total_bytes = 0
                if self._send_buffer:
                    total_bytes = self._send_bytes(self._send_buffer)
                    self._send_buffer = self._send_buffer[total_bytes:]

            if self._sensors:
                self._sensors.bytes_sent.record(total_bytes)
            # Return True iff send buffer is empty
            return len(self._send_buffer) == 0

        except (ConnectionError, TimeoutError, Exception) as e:
            log.exception("Error sending request data to %s", self)
            error = Errors.KafkaConnectionError("%s: %s" % (self, e))
            self.close(error=error)
            return False
```