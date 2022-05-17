# Debezium

Debezium 은 Kakfa connect용 소스 커넥터 세트이다.  
Debezium에서 구현되는 log-based CDC는 다음과 같다.
- 모든 데이터 변경 사항이 캡쳐되었는지 확인한다.
- CPU 사용량 증가를 피하면서 매우 짧은 지연으로 변경 이벤트를 생성한다.
- `Last Updated` 칼럼 같은 데이터 모데리 변경이 필요없다.
- `DELETE`를 캡쳐 가능하다.
- 이전 레코드 상태 및 transaction ID 및 causing query와 같은 추가 메타데이터를 캡쳐 가능하다.

### [Debezium Connector Features](https://debezium.io/documentation/reference/stable/features.html)
- Snapshot 
- Filter
- Masking
- Monitoring
- Message Transformation

## [Architecture](https://debezium.io/documentation/reference/stable/architecture.html)

일반적으로는 **Kafka Connect**를 통해 Debezium을 배포한다.   
Kafka Connect는 Apache Kafka와 다른 시스템 간에 데이터를 확장 가능하고 안정적으로 스트리밍하기 위한 툴이다.
Kafka 토픽으로 수집하여 데이터를 짧은 대기 시간으로 스트리밍할 수 있또록 한다.

![](https://debezium.io/documentation/reference/stable/_images/debezium-architecture.png)

- MySQL connector의 경우 binlog를 사용한다.
- PostgreSQL connector의 경우 logical replication stream에서 읽어온다.

기본적으로 DB 데이터 변경 사항은 테이블명과 동일한 Kafka 토픽에 기록된다. 
변경 이벤트 레코드가 Kafka에 들어가면 Kafka Connect 에코시스템의 커넥터가 스트리밍할 수 있다. 선택한 싱크 커넥터에 따라 레코드 상태를 변환해야 한다.

또는 **Debezium Server**를 사용하여 Debezium을 배포한다. Debezium Server는 Source DB에서 다양한 메시징 인프라로 변경 이벤트를 스트링할 수 있도록 한다.

![](https://debezium.io/documentation/reference/stable/_images/debezium-server-architecture.png)

Debezium source connecter 중 하나를 통해 Source DB의 변경 사항을 캡쳐한다.
변경 이벤트는 JSON이나 Apache Avro 같은 여러 형식으로 serialize할 수 있으며 Kinesis, Pub/Sub같은 여러 메시징 인프라로 전송된다.

추가적으로 Debezium Connector를 사용하는 다른 방법은 임베디드 엔진이다.

## Configuration
### [Serialization](https://debezium.io/documentation/reference/stable/configuration/avro.html)

Debezium connector는 Kafka Connect에서 동작하여 DB의 각 row 레벨 변경 사항을 캡쳐한다.  
Debezium connector는 각 변경 이벤트에 대해 다음과 같이 작업한다.

1. transformation 적용
2. Kafka Connect converters를 통해 레코드 key, value를 binary로 serialize한다.
3. 레코드를 타겟 Kafka 토픽에 전송한다.

- 레코드를 JSON으로 serialize하려면 `key.converter.schemas.enable = False`, `value.converter.schemas.enable = False`로 설정해야 한다.
- 또는 Avro Serialization를 사용하여 레코드 key, value를 serialize한다.

### [Kafka Topic auto creation](https://debezium.io/documentation/reference/stable/configuration/topic-auto-create-config.html)
Kafka Connecr와 Broker 구성은 서로 독립적이다.
- Kafka Broker에서 `auto.create.topics.enable`을 사용하여 topic 자동 생성을 제어한다. 
- Kafka Connect에서 `topic.creation.enable`을 사용하여 topic 자동 생성을 제어한다.
topic을 자동 생성이 활성화되면 target DB에 존재하지 않는 테이블에 대한 변경 이벤트 레코드를 내보내면 런타임시 topic이 생성된다.



#### 추가
[Deploying Debezium on Kubernetes](https://debezium.io/documentation/reference/stable/operations/kubernetes.html)  
[Debezium connector for PostgreSQL](https://debezium.io/documentation/reference/stable/connectors/postgresql.html)  