## [23.02.13]
```
java.lang.IllegalArgumentException: Error creating broker listeners from 'PLAINTEXT_HOST://0.0.0.0:29092': No security protocol defined for listener PLAINTEXT_HOST


java.lang.IllegalArgumentException: requirement failed: inter.broker.listener.name must be a listener name defined in advertised.listeners. The valid options based on currently configured listeners are PLAINTEXT_HOST
```
- ```
    broker1:
      ...
      KAFKA_ADVERTISED_LISTENERS: INTERNAL://broker1:9092,EXTERNAL://{external-ip}:29092
      KAFKA_LISTENERS: INTERNAL://broker1:9092,EXTERNAL://0.0.0.0:29092
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: INTERNAL:PLAINTEXT,EXTERNAL:PLAINTEXT
  ```
  - `INTERNAL`: 내부적으로 접근할 시( 도커로 실행 중이므로, 도커 내에서 접근 할 때 )
  - `EXTERNAL`: 외부에서 접근할 시(전체 인터페이스를 수신하며, 0.0.0.0:29092로 접근하면 {external-ip}:29092 를 반환하도록 함)
  - `PLAINTEXT` : 인코딩하지 않고 문자 그대로

## [23.02.24]
### Kafka to clickhouse with kafka connect
```
java.lang.RuntimeException: com.clickhouse.client.ClickHouseException: Code: 36. DB::Exception: KeeperMap is disabled because 'keeper_map_path_prefix' config is not defined. (BAD_ARGUMENTS) (version 23.2.1.1637 (official build)) , server ClickHouseNode 
```
- Clickhouse에 **keeper_map_path_prefix**를 설정해야 한다고 나옴 :  `keeper_map_path_prefix`는 zookeeper 클러스터를 reads, writes에 대해 key-value store로 사용하기 위한 엔진이다.
- [KeeperMap](https://clickhouse.com/docs/en/engines/table-engines/special/keeper-map/)
```
java.lang.RuntimeException: com.clickhouse.client.ClickHouseException: Code: 999. Coordination::Exception: No hosts passed to ZooKeeper constructor. (Bad arguments). (KEEPER_EXCEPTION) 
```
