# MySQL CDC with Debezium MySQL Source Connector

## Logical replication in MySQL
MySQL에서 복제는 여러 복제 방식 중 물리적인 스토리지 엔진과 분리되어 논리적 로그를 기반으로 이루어진다.
논리적 로그는 보통 row-based이고, 이는 테이블 write에 대한 일련의 레코드를 나타낸다.

각 DML 이벤트에 대해 레코드에서 포함해야 되는 정보는 다음과 같다. 
- INSERT : row의 새로운 값이 모두 포함된다.
- DELETE : 삭제한 row를 식별할 수 있는 고유 정보가 필요한데, 보통 PRIMARY KEY를 기반으로 한다. PK가 없는 경우, 타겟이 되는 row의 모든 값을 포함해야 한다.
- UPDATE : 업데이트 대상인 row를 판별할 수 있는 정보와 row의 새로운 값을 포함한다.

논리적 복제는 내부 스토리지 엔진과 분리되어 있기 때문에 이전 버전과도 잘 호환되어 리더, 팔로워가 서로 다른 버전이어도 복제가 가능하다. 또한 외부 어플리케이션에도 구문 분석이 수월하여 외부 시스템으로 전송하는 경우에도 유용하다.
따라서 DW에서 데이터를 적재하여 오프라인 분석을 할 때도 유용하게 활용되는데 이를 Change Data Capture(CDC)라고 한다.

## MySQL CDC with debezium connector
Debezium connector는 MySQL, PostgreSQL 같은 여러 데이터 소스에서 실시간으로 발생하는 이벤트를 캡쳐하여 전송하는 카프카 커넥터이다. Debezium  connector를 통해 CDC 기술을 구현하여 웨어하우스에 실시간으로 데이터를 적재할 수 있다.

MySQL Debezium source connector는 논리적 복제를 활용하는 binlog를 파싱하여 이루어진다. MYSQL에서 변경 사항을 적재하고자 하는 테이블은 각 토픽으로 생성되어 INSERT/DELETE/UPDATE 이벤트를 실시간으로 캡쳐하여 각 테이블에 1:1 매핑되어 생성되는 토픽으로 레코드를 전송한다.

위에서 언급한 각 DML 이벤트에 대에서 포함해야 하는 데이터는 커넥터에서 실제로 수집되는 다음과 같이 보여질 수 있다.
- INSERT
```json
{
  "before": null,
  "after": {
    "id": 101,
    "name": "Alice",
    "email": "alice@example.com",
    "created_at": "2023-01-01T12:00:00Z"
  },
  "source": {
    "version": "1.5.0.Final",
    "connector": "mysql",
    "name": "dbserver1",
    "ts_ms": 1672531200000,
    "snapshot": "false",
    "db": "mydb",
    "table": "users",
    "server_id": 1,
    "gtid": null,
    "file": "mysql-bin.000001",
    "pos": 154,
    "row": 0,
    "thread": null,
    "query": null
  },
  "op": "c",
  "ts_ms": 1672531200000,
  "transaction": null
}
```
- DELETE
```json
{
  "before": {
    "id": 101,
    "name": "Alice Johnson",
    "email": "alice.johnson@example.com",
    "created_at": "2023-01-01T12:00:00Z"
  },
  "after": null,
  "source": {
    "version": "1.5.0.Final",
    "connector": "mysql",
    "name": "dbserver1",
    "ts_ms": 1672531400000,
    "snapshot": "false",
    "db": "mydb",
    "table": "users",
    "server_id": 1,
    "gtid": null,
    "file": "mysql-bin.000001",
    "pos": 512,
    "row": 0,
    "thread": null,
    "query": null
  },
  "op": "d",
  "ts_ms": 1672531400000,
  "transaction": null
}
```
- UPDATE
```json
{
  "before": {
    "id": 101,
    "name": "Alice",
    "email": "alice@example.com",
    "created_at": "2023-01-01T12:00:00Z"
  },
  "after": {
    "id": 101,
    "name": "Alice Johnson",
    "email": "alice.johnson@example.com",
    "created_at": "2023-01-01T12:00:00Z"
  },
  "source": {
    "version": "1.5.0.Final",
    "connector": "mysql",
    "name": "dbserver1",
    "ts_ms": 1672531300000,
    "snapshot": "false",
    "db": "mydb",
    "table": "users",
    "server_id": 1,
    "gtid": null,
    "file": "mysql-bin.000001",
    "pos": 256,
    "row": 0,
    "thread": null,
    "query": null
  },
  "op": "u",
  "ts_ms": 1672531300000,
  "transaction": null
}
```

필드는 다음과 같다.
- "before": 변경되기 전의 레코드 데이터
- "after": 변경된 후의 레코드 데이터
- "source": 이벤트가 발생한 소스 데이터베이스에 대한 메타데이터
        - "version": Debezium 커넥터 버전
        - "connector": 사용된 커넥터 타입
        - "name": 커넥터 이름
        - "ts_ms": 이벤트 발생 시간(밀리초 단위)
        - "db": 데이터베이스 이름
        - "table": 테이블 이름
        - "server_id": MySQL 서버 ID
        - "file": 바이너리 로그 파일 이름
        - "pos": 바이너리 로그 파일에서의 위치
- "op": 이벤트 타입 (c: create, u: update, d: delete)
- "ts_ms": 이벤트의 타임스탬프(밀리초 단위)
- "transaction": 트랜잭션 정보(존재하는 경우)

binlog 기반으로 이루어지는 변경 사항 캡쳐는 원본 테이블 스키마 변경에는 취약한데, 테이블의 레코드 변경만 반영이 되고 실제 스키마는 자동으로 변환되지 않기 때문이다. 

## 스냅샷
MySQL CDC에서는 Consistent Snapshot을 수행한다. Consistent Snapshot은 데이터베이스 트랜잭션 격리 수준 중 하나인 Repeatable Read나 Serializable 격리 수준에서 사용되는 개념이다. 특정 시점의 스냅샷을 생성할 때 REPEATABLE READ 의 경우, 트랜잭션 내에서 처음 시작할 때의 스냅샷을 읽어온다. 이에 반해 READ COMMITTED의 경우, 트랜잭션 내에서 최신 스냅샷을 읽어온다.

카프카 커넥터는 MYSQL 서버의 binlog 포지션을 기록하여 스냅샷을 추적하므로 각 커넥터는 하나의 MYSQL 서버 인스턴스를 바라봐야한다. 
