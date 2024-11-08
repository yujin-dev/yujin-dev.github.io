---
layout: post
title: How to Sync Data from MySQL to Clickhouse
date: 2024-09-30
categories: [Clickhouse]
---

MySQL에서 Clickhouse로 실시간 동기화(CDC)를 하려면 2가지 방법이 있다.

1. [clickhouse-kafka-connector](https://github.com/ClickHouse/clickhouse-kafka-connect/tree/main)
를 활용하여 Kafka에서 클릭하우스로 바로 데이터를 입수한다.
2. Clickhouse Kafka 테이블 엔진을 통해 들어오는 데이터를 Materialized View를 거쳐 테이블에 적재한다.

각각의 방법으로 데이터 입수를 테스트하면서 과정을 확인해보고자 한다.

여기서 알아야 할 점은
- Materialized view, clickhouse-sink-connector에서는 DELETE operation이 불가하다. INSERT로만 데이터가 갱신된다고 보면 된다.(append-only)
- CollapsingMergeTree 나 ReplacingMergeTree 테이블 엔진을 함께 활용해야 한다.

싱크하려는 테스트용 MySQL 소스 테이블은 아래와 같이 구성하였다.

```sql
create table person  ( 
	 created_at DATETIME default current_timestamp, 
	 id int primary key, 
	 name varchar(255)
)
```

## clickhouse-kafka-connector 활용

### MySQL Source Connector

```bash
curl --location --request POST 'http://kafka-broker-01:8083/connectors' --header 'Content-Type: application/json' --data-raw '
{
"name": "mysql_person",
"config": {
    "name": "mysql_person",
    "connector.class": "io.debezium.connector.mysql.MySqlConnector",
    "tasks.max": "2",
    "database.hostname": "{MYSQL_HOST}",
    "snapshot.mode": "initial",
    "database.port": "3306",
    "database.user": "{USER}",
    "database.password": "{PASSWORD}",
    "database.server.id": "5",
    "database.server.name": "mysql_person",
    "database.whitelist": "testdb",
    "database.history.kafka.bootstrap.servers": "kafka-broker-01:9092,kafka-broker-02:9092,kafka-broker-03:9092",
    "database.history.kafka.topic": "test-history",
    "database.serverTimezone": "Asia/Seoul",
    "table.whitelist": "testdb.person",
    "key.converter": "org.apache.kafka.connect.json.JsonConverter",
    "key.converter.schemas.enable": "false",
    "value.converter": "org.apache.kafka.connect.json.JsonConverter",
    "value.converter.schemas.enable": "false",
    "transforms": "unwrap,addTopicPrefix",
    "transforms.unwrap.type": "io.debezium.transforms.ExtractNewRecordState",
    "transforms.unwrap.delete.handling.mode": "rewrite",    
    "transforms.addTopicPrefix.type": "org.apache.kafka.connect.transforms.RegexRouter",
    "transforms.addTopicPrefix.regex": "(.*)\\.(.*)\\.(.*)",
    "transforms.addTopicPrefix.replacement": "$3",
    "topic.creation.default.replication.factor": -1,
    "topic.creation.default.partitions": -1,
    "topic.creation.enable": "true"
    }
}'
```

- `io.debezium.transforms.ExtractNewRecordState` 를 적용해서 변경 사항 레코드에서 after 필드에 해당되는 값만 추출한다.
- `transforms.unwrap.delete.handling.mode=false` 를 적용해서 삭제 레코드에 대한 `__deleted` 플래그를 표시한다.

### Clickhouse Target Connector

싱크하려는 MySQL 테이블 스키마와 동일하게 클릭하우스에도 생성한다.
```sql
CREATE TABLE person ON CLUSTER dp
(
    `created_at` DateTime64,
    `id` Int64,
    `name` Nullable(String),
    `__deleted` UInt8
)
ENGINE = ReplicatedReplacingMergeTree(created_at, __deleted)
ORDER BY id
SETTINGS allow_experimental_replacing_merge_with_cleanup = 1
```

- `allow_experimental_replacing_merge_with_cleanup` 세팅값을 추가하여 `__deleted` 플래그를 통해 삭제 레코드가 생기면, CLEAN UP하여 정리하도록 한다.
- id를 고유키로 하여 중복을 제거하고, `created_at` 을 버저닝 칼럼으로 활용한다.

Clickhouse 커넥터를 생성한다.

```bash
curl --location --request POST 'http://kafka-broker-01:8083/connectors' --header 'Content-Type: application/json' --data-raw '
{
    "name": "clickhouse_person",
    "config": {
      "connector.class": "com.clickhouse.kafka.connect.ClickHouseSinkConnector",
      "tasks.max": "1",
      "consumer.override.max.poll.records": "5000",
      "consumer.override.max.partition.fetch.bytes": "5242880",
      "database": "test",
      "errors.retry.timeout": "60",
      "exactlyOnce": "true",
      "hostname": "{CLICKHOUSE_HOST}",
      "port": "8123",
      "ssl": "false",
      "username": "{USER}",
      "password": "{PASSWORD}",
      "topics": "person",
      "transforms": "flatten", 
      "transforms.flatten.type": "org.apache.kafka.connect.transforms.Flatten$Value",
      "transforms.flatten.delimiter": "_",
      "key.converter": "org.apache.kafka.connect.json.JsonConverter",
      "key.converter.schemas.enable": "false",
      "value.converter": "org.apache.kafka.connect.json.JsonConverter",
      "value.converter.schemas.enable": "false",
      "clickhouseSettings": ""
    }
  }' | jq -r

```
- nested json에서 nested 형태를 해체하기 위해 flatten 설정 추가하였다.

여기서 주의할 점은 클릭하우스 커넥터에서 exatly once를 활성화하려면 클릭하우스 서버 설정에서 keeper map 경로가 명시되어 있어야 한다.

```xml
<clickhouse>
    <keeper_map_path_prefix>/keeper_map_tables</keeper_map_path_prefix>
</clickhouse>
```

### 결과(테스트)

- DELETE 이벤트 발생시킬 경우

```sql
SELECT *
FROM test.person

   ┌──────────────created_at─┬─id─┬─name─┬─__deleted─┐
1. │ 2024-10-15 07:22:26.000 │  3 │ mary │         0 │
   └─────────────────────────┴────┴──────┴───────────┘
   ┌──────────────created_at─┬─id─┬─name─┬─__deleted─┐
2. │ 2024-10-15 06:53:32.000 │  1 │ mary │         1 │
   └─────────────────────────┴────┴──────┴───────────┘
```

- UPDATE 이벤트 발생시킬 경우

```sql

SELECT * FROM test.person
   ┌──────────────created_at─┬─id─┬─name──┬─__deleted─┐
1. │ 2024-10-15 07:20:10.000 │  6 │ mary1 │         0 │
   └─────────────────────────┴────┴───────┴───────────┘
   ┌──────────────created_at─┬─id─┬─name──┬─__deleted─┐
2. │ 2024-10-15 07:22:26.000 │  3 │ mary1 │         0 │
   └─────────────────────────┴────┴───────┴───────────┘
   ┌──────────────created_at─┬─id─┬─name─┬─__deleted─┐
3. │ 2024-10-15 07:22:26.000 │  3 │ mary │         0 │
   └─────────────────────────┴────┴──────┴───────────┘

OPTIMIZE TABLE person FINAL CLEANUP

SELECT * FROM test.person
   ┌──────────────created_at─┬─id─┬─name──┬─__deleted─┐
1. │ 2024-10-15 07:22:26.000 │  3 │ mary1 │         0 │
2. │ 2024-10-15 07:20:10.000 │  6 │ mary1 │         0 │
   └─────────────────────────┴────┴───────┴───────────┘

```

실제 쿼리 이력을 확인하면 JSONEachRow 형식으로 데이터가 삽입된 것으로 확인할 수 있다.

```sql
query:           INSERT INTO `persons` FORMAT JSONEachRow
Settings:        {'receive_timeout':'1000000','send_timeout':'1000000','send_progress_in_http_headers':'1','http_send_timeout':'1000','http_receive_timeout':'1000','allow_nondeterministic_mutations':'1','insert_deduplication_token':'persons-2-2-2'}
http_user_agent: clickhouse-kafka-connect/v1.2.3 ClickHouse-JavaClient/0.6.3 (OpenJDK 64-Bit Server VM/(Red_Hat-11.0.23.0.9-2); Apache-HttpClient/5.2.4)
```

MySQL 소스 테이블에서 datetime 타입의 이벤트가 유입되면 커넥터에서 숫자 형식으로 들어오지만, 클릭하우스 타겟 테이블에서 DateTime으로 설정되어 있으면 데이터 타입에 맞게 삽입된다. 또한 `__deleted` 칼럼에서 boolean값이 true 또는 false인 string으로 들어오는데, 실제 타겟 테이블에서 UInt8 타입으로 설정하면 오류없이 잘 들어가는 것으로 확인된다. 이는 `value.converter.schemas.enable=false` 로 적용하여 타입 validation을 하지 않도록 설정해서 가능했던 것으로 예상된다.

> 테이블 생성 및 설정에서 몇 가지 주의사항이 있다.

- `topic2TableMap` 설정을 적용하지 않는다면 토픽명 = 클릭하우스 테이블명이여야 한다.
- `value.converter.schemas.enable=true`를 적용하면 소스-타켓간 스키마 데이터 타입이 일치하는지를 확인한다. 타입이 맞지 않을 경우 `java.lang.RuntimeException: Data schema validation failed` 에러가 발생할 수 있다. 대신 false로 설정하면 타입 체크 validation을 하지 않고 적재된다. 



##  Materialized View 활용

위에서 언급했듯이 MySQL 커넥터에서 받으면 따로 변환을 적용하지 않는 이상, DateTime → unix timstamp로 변환되어서 들어온다. 클릭하우스에서 DateTime 타입으로 들어오는 데이터는 Materialized View에서 UTC 기준 DateTime으로 변환하고, 타겟 테이블 DateTime 칼럼에 저장하였다.

### MySQL Source Connector

```bash
curl --location --request POST 'http://kafka-broker-01:8083/connectors' --header 'Content-Type: application/json' --data-raw '
{
"name": "mysql_person",
"config": {
    "connector.class": "io.debezium.connector.mysql.MySqlConnector",
    "tasks.max": "2",
    "database.hostname": "{MYSQL_HOST}",
    "database.port": "3306",
    "database.user": "{USER}",
    "database.password": "{PASSWORD}",
    "database.server.id": "2",
    "database.server.name": "mysql_person",
    "database.allowPublicKeyRetrieval": "true",
    "database.whitelist": "testdb",
    "database.history.kafka.bootstrap.servers": "kafka-broker-01:9092,kafka-broker-02:9092,kafka-broker-03:9092",
    "database.history.kafka.topic": "testdb-cdc-history",
    "database.serverTimezone": "Asia/Seoul",
    "table.whitelist": "testdb.person",
    "key.converter": "org.apache.kafka.connect.json.JsonConverter",
    "key.converter.schemas.enable": "true",
    "value.converter": "org.apache.kafka.connect.json.JsonConverter",
    "value.converter.schemas.enable": "true",
    "transforms": "unwrap,addTopicPrefix",
    "transforms.unwrap.type": "io.debezium.transforms.ExtractNewRecordState",
    "transforms.addTopicPrefix.type": "org.apache.kafka.connect.transforms.RegexRouter",
    "transforms.addTopicPrefix.regex": "(.*)\\.(.*)\\.(.*)",
    "transforms.addTopicPrefix.replacement": "$2.$3",
    "topic.creation.default.replication.factor": -1,
    "topic.creation.default.partitions": -1,
    "topic.creation.enable": "true"
    }
}'
```

## Clickhouse Materialied View 및 Target Table

클릭하우스에서 이벤트를 컨슈밍할 Kafka 테이블 엔진과 실제 데이터가 적재될 테이블 Materialized View 생성한다.

1. Kafka 테이블 엔진 기반의 테이블 생성

```sql
CREATE TABLE testdb._kafka_person on cluster dp
(
    `msg_json_str` String
)
Engine=Kafka('kafka-broker-01:9092,kafka-broker-02:9092,kafka-broker-03:9092', 'testdb.person', 'clickhouse-testdb', 'JSONAsString')
```

2. 실제 데이터가 저장될 타겟 테이블 생성
```sql
CREATE TABLE person ON CLUSTER dp
(
    `created_at` DateTime64,
    `id` Int64,
    `name` Nullable(String),
    `__deleted` UInt8
)
ENGINE = ReplicatedReplacingMergeTree(created_at, __deleted)
ORDER BY id
SETTINGS allow_experimental_replacing_merge_with_cleanup = 1
````

3. 데이터를 입수하여 처리하고 적재할 Materialized View 생성

```sql
CREATE MATERIALIZED VIEW testdb._mv_person on cluster dp TO testdb.person
AS
SELECT
toString(toDateTime(toUInt64(JSONExtractString(msg_json_str,'payload', 'created_at'))/1000, 'UTC')) as created_at,
JSONExtractString(msg_json_str,'payload', 'id') as id,
JSONExtractString(msg_json_str,'payload', 'name') as name,
toUInt64(JSONExtractString(msg_json_str,'payload', '__deleted')) as __deleted
FROM testdb._kafka_person
```

테스트 결과는 스킵하도록 한다.

## Summary
우선 공통적으로 lightwegith DELETE나 리파티셩을 통한 DELETE 적용이 자동으로 이루어지지 않으므로 INSERT로만 데이터를 입수하고, 타겟 테이블 엔진을 적절하게 설정하여 중복을 제거하는 방식으로 사용해야 한다.

clickhouse-sink-connector를 활용할 때와 Kafka 테이블 엔진과 MV 활용할 때와 다른 점은,
- 클릭하우스 커넥터에서 exactly once 옵션을 통해 이를 활성화할지 말지 정할 수 있다는 것
- datetime 타입이 MySQL debezium 커넥터에서 integer 형식으로 들어오는데, 클릭하우스 커넥터에선 타겟 테이블 타입만 datetime으로 설정하면 알아서 타입에 맞게 적재 가능하지만 Materialized view 에서는 toDateTime으로 변환해서 넣어줘야 한다는 것

그 외에도 파악해야할 내용이 많겠지만, 우선 내가 테스트하여 파악한 내용은 이 정도로 마무리한다.
