---
layout: post
title: Task Queue(Celery)
date: 2022-02-13
---

*Task queue*는 HTTP 응답 성능을 저하시키는 경우에 비동기로 태스크를 처리하기 위해 사용된다.  

task queue의 종류는 간략하게 살펴보면 다음과 같이 존재한다.

- Redis Queue(RQ) : 간단한 python 라이브러리
- Taskmaster : 대량의 일회성 작업을 처리하기 위한 경량의 task queue
- Hey
- Kuyruk
- Dramatiq

# Celery
Celery는 Python의 표준 Task queue이다.

Celery는 분산 메시지 전달을 기반으로 하는 비동기 task queue이다.
API 서버에서 처리하기 힘든 작업을 Task로 정의하여 Worker( consumer )를 통해 비동기적으로 처리하는 방식이다. 

## Architecture
![Untitled](Untitled.png)

**Celery publisher**가 태스크를 생성하면 **Broker**를 통해 **Consumer**에서 받아 해당 task를 실행하게 한다. 
- Broker는 태스크를 전달하기 위해 클라이언트와 Worker 사이를 중재하는 역할이다.
- Celery producer가 Broker queue에 메시지를 추가하고, Broker는 해당 메시지를 Worker에 전달한다.
- Worker와 Broker는 여러 개로 구성하여 고가용성과 확장성을 제어할 수 있다.

Celery는 python으로 작성되었지만 프로토콜은 javascript에서도 [Node-celery](https://github.com/mher/node-celery)를 통해 사용할 수 있다.

### Message Broker

메시지를 주고 받기 위해 브로커는 다음과 같이 사용할 수 있다.

- RabbitMQ( 확장성에 대한 한계가 있을 수 있음 )
- Redis
- AWS SQS
- Kafka

### Result Backend

작업을 수행한 결과물은 다양한 형식의 저장소에 저장된다.

- Redis, AMQP
- Memcached
- Cassandra, MongoDB

결과물은 serialized 형태로 저장되는데 파일 형식은 pickle, json, yaml, zlib 등으로 저장될 수 있다. pickle은 다른 언어에서 호환될 수 없는 가능성이 있으므로 json 같은 다른 포맷을 사용하는 것이 좋을 것 같다. 사용하게 되면 네트워크 지연 시간을 줄이기 위해 압축해서 저장할 필요가 있을 것이다.

## 메시지 큐를 이용한 비동기 처리

서버에서 요청을 처리하는 방식에는 동기식과 비동기식으로 구분으로 할 수 있다.
- **동기식**은 응답이 올 때까지 <u>클라이언트가 대기</u>하는 방식이다.
- **비동기식**은 요청을 보내고, 응답과 상관없이 다음 로직을 수행한다. 비동기로 요청한 작업이 완료되면 <u>콜백을 호출</u>하여 알려주게 된다.

비동기식은 주로 시간이 오래 걸리는 작업, 동영상 인코딩 같은 작업이나 계산이 오래 걸리는 경우에 사용된다. 보통 비동기식은 메시지 큐를 사용하여 로직이 구현된다.

### 에러 핸들링
전달된 메시지는 요청이 잘 처리되었는지에 대한 응답이 제대로 이루어져야 한다. 

참고 메시지 처리 중에 오류가 나는 경우 크게 4가지 정책 중 사용된다. 
- Retry : 재처리
- Ignore : 오류 무시하여 메시지 삭제
- Notify : 오류에 대한 알람
- Human Interaction : 직접 처리

---
#### Reference
- https://www.fullstackpython.com/task-queues.html
- https://kimdoky.github.io/tech/2019/01/23/celery-rabbitmq-tuto/
- https://jonnung.dev/python/2018/12/22/celery-distributed-task-queue/
- https://dongwooklee96.github.io/post/2021/03/29/%EB%A9%94%EC%8B%9C%EC%A7%80-%ED%81%90%EB%A5%BC-%EC%9D%B4%EC%9A%A9%ED%95%9C-%EB%B9%84%EB%8F%99%EA%B8%B0%EC%B2%98%EB%A6%AC-%EB%B0%8F-%EC%97%90%EB%9F%AC-%EC%B2%98%EB%A6%AC/