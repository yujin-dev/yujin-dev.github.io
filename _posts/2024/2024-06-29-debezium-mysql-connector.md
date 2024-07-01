---
layout: post
title: MySQL CDC with Debezium MySQL Source Connector
date: 2024-06-29
categories: [CDC]
---

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

```java
public class MySqlConnector extends BinlogConnector<MySqlConnectorConfig>
```

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
- `before`: 변경되기 전의 레코드 데이터
- `after`: 변경된 후의 레코드 데이터
- `source`: 이벤트가 발생한 소스 데이터베이스에 대한 메타데이터
    - `version`: Debezium 커넥터 버전
    - `connector`: 사용된 커넥터 타입
    - `name`: 커넥터 이름
    - `ts_ms`: 이벤트 발생 시간(밀리초 단위)
    - `db`: 데이터베이스 이름
    - `table`: 테이블 이름
    - `server_id`: MySQL 서버 ID
    - `file`: 바이너리 로그 파일 이름
    - `pos`: 바이너리 로그 파일에서의 위치
- `op`: 이벤트 타입 (c: create, u: update, d: delete)
- `ts_ms`: 이벤트의 타임스탬프(밀리초 단위)
- `transaction`: 트랜잭션 정보(존재하는 경우)

binlog 기반으로 이루어지는 변경 사항 캡쳐는 원본 테이블 스키마 변경에는 취약한데, 테이블의 레코드 변경만 반영이 되고 실제 스키마는 자동으로 변환되지 않기 때문이다. 

## Snapshot
MySQL CDC에서는 Consistent Snapshot을 수행한다. Consistent Snapshot은 데이터베이스 트랜잭션 격리 수준 중 하나인 Repeatable Read나 Serializable 격리 수준에서 사용되는 개념이다. REPEATABLE READ 격리 수준은 트랜잭션 내에서 일관된 읽기를 보장한다. 트랜잭션이 시작될 때의 데이터 상태를 기준으로 스냅샷을 생성하고, 트랜잭션이 종료될 때까지 동일한 데이터를 읽도록 한다. 반면 READ COMMITTED의 경우, 트랜잭션 내에서 최신 스냅샷을 읽어온다. 

## Initial snapshot
처음 커넥터를 실행하면 Initial Consistent Snapshot을 생성한다. 모든 변경 사항의 로그를 재생하여 데이터베이스 전체 상태를 재구성하는데 global read lock 또는 table-level lock이 수행된다. 

global read lock 또는 table-level lock 기반의 초기 스냅샷은 다음과 같이 구성한다.
1. DB를 연결한다.
2. 대상 테이블 선정한다.  
> [잠금] 캡처할 테이블에 대한 global read lock 또는 table-level lock을 설정하여 다른 데이터베이스 클라이언트의 write을 차단한다.
3. repeatable read semantics으로 트랜잭션을 시작한다.
4. 현재 시점의 binlog 포지션을 읽는다.
5. 선정한 모든 테이블의 구조를 캡처한다.
> [잠금 해제] global read lock인 경우 잠금을 해제한다.
6. binlog 위치에서 커넥터는 테이블을 스캔하여 캡쳐한다. : 스냅샷이 생성되었는지 확인하여 binlog에 대한 읽기 이벤트를 카프카 토픽으로 전송한다. 이후 테이블 잠금을 해제한다.
7. 트랜잭션을 커밋한다.  
> [잠금 해제] table-levle lock인 경우 잠금을 해제한다.
8. 커넥터 오프셋에 스냅샷이 성공적으로 완료되었음을 기록한다. 

```java
public abstract class BinlogSnapshotChangeEventSource<P extends BinlogPartition, O extends BinlogOffsetContext<?>>
    public BinlogSnapshotChangeEventSource(BinlogConnectorConfig connectorConfig,
                                           MainConnectionProvidingConnectionFactory<BinlogConnectorConnection> connectionFactory,
                                           BinlogDatabaseSchema<P, O, ?, ?> schema,
                                           EventDispatcher<P, TableId> dispatcher,
                                           Clock clock,
                                           BinlogSnapshotChangeEventSourceMetrics<P> metrics,
                                           BlockingConsumer<Function<SourceRecord, SourceRecord>> lastEventProcessor,
                                           Runnable preSnapshotAction,
                                           NotificationService<P, O> notificationService,
                                           SnapshotterService snapshotterService)
    private void globalLock()

    private void globalUnlock()

    @Override
    protected void lockTablesForSchemaSnapshot(ChangeEventSourceContext sourceContext,
                                               RelationalSnapshotContext<P, O> snapshotContext)
        connection.connection().setTransactionIsolation(Connection.TRANSACTION_REPEATABLE_READ);

    @Override
    protected void determineSnapshotOffset(RelationalSnapshotContext<P, O> ctx, O previousOffset) throws Exception

    @Override
    protected void readTableStructure(ChangeEventSourceContext sourceContext,
                                      RelationalSnapshotContext<P, O> snapshotContext,
                                      O offsetContext,
                                      SnapshottingTask snapshottingTask)

    @Override
    protected void releaseSchemaSnapshotLocks(RelationalSnapshotContext<P, O> snapshotContext) throws SQLException {

    @Override
    protected Optional<String> getSnapshotSelect(RelationalSnapshotContext<P, O> snapshotContext,
                                                 TableId tableId,
                                                 List<String> columns) {
        return getSnapshotSelect(tableId, columns);
    }
```
### Incremental snapshot
증분 스냅샷에서는 초기 스냅샷처럼 데이터베이스의 전체 상태를 한 번에 캡처하는 대신 각 테이블을 일련의 chunk로 단계적으로 캡쳐한다. chunk 크기는 스냅샷이 수집하는 row 수를 결정하는데, 기본 크기는 1024개이다. 
증분 스냅샷이 진행되면 Debezium은 워터마크를 사용하여 진행 상황을 추적하고 캡처하는 각 테이블 row에 대해 기록한다.  
커넥터는 스냅샷 프로세스 내내 변경 로그를 실시간으로 캡쳐하며 다른 작업을 차단하지 않는다. 프로세스가 재개되면 처음부터가 아닌, 중단 시점부터 스냅샷을 시작하게 되어 데이터 손실없이 재시작이 가능한다. 

증분 스냅샷을 실행하면 각 테이블을 PRIMARY KEY 별로 정렬하여 chunk 크기에 따라 분할하여 크기만큼 캡쳐한다.

```java
public abstract class AbstractIncrementalSnapshotChangeEventSource<P extends Partition, T extends DataCollectionId>
    public void closeWindow(P partition, String id, OffsetContext offsetContext) throws InterruptedException

    protected String getSignalTableName(String dataCollectionId) 

    protected void sendWindowEvents(P partition, OffsetContext offsetContext) throws InterruptedException {
        LOGGER.debug("Sending {} events from window buffer", window.size());
        offsetContext.incrementalSnapshotEvents();
        for (Object[] row : window.values()) {
            sendEvent(partition, dispatcher, offsetContext, row);
        }
        offsetContext.postSnapshotCompletion();
        window.clear();
    }

    protected void deduplicateWindow(DataCollectionId dataCollectionId, Object key)
        if (context.currentDataCollectionId() == null || !context.currentDataCollectionId().getId().equals(dataCollectionId)) {
            return;
        }
        if (key instanceof Struct) {
            if (window.remove((Struct) key) != null) {
                LOGGER.info("Removed '{}' from window", key);
            }
        }
    }

    protected void readChunk(P partition, OffsetContext offsetContext) throws InterruptedException

public abstract class BinlogReadOnlyIncrementalSnapshotChangeEventSource<P extends BinlogPartition, O extends BinlogOffsetContext>
        extends AbstractIncrementalSnapshotChangeEventSource<P, TableId>
      
    @Override
    public void processMessage(P partition, DataCollectionId dataCollectionId, Object key, OffsetContext offsetContext)
            throws InterruptedException {
        if (getContext() == null) {
            LOGGER.warn("Context is null, skipping message processing");
            return;
        }
        LOGGER.trace("Checking window for table '{}', key '{}', window contains '{}'", dataCollectionId, key, window);
        boolean windowClosed = getContext().updateWindowState(offsetContext);
        if (windowClosed) {
            sendWindowEvents(partition, offsetContext);
            readChunk(partition, offsetContext);
        }
        else if (!window.isEmpty() && getContext().deduplicationNeeded()) {
            deduplicateWindow(dataCollectionId, key);
        }
    }
```

스냅샷이 진행될 때 다른 프로세스에서  INSERT, UPDATE 또는 DELETE 작업이 발생하면서 테이블을 수정하는데, 이러한 변경 사항은 로그에 커밋되고 해당 이벤트 레코드를 Debezium은 카프카에 계속 전송한다.

로그 수집에서 Debezium은 2가지 이벤트를 발생시켜 카프카 토픽에 저장한다.
- READ : 테이블에 직접 캡쳐하는 스냅샷 레코드는 READ 이벤트로 발생한다.
- DELETE / UPDATE : 테이블이 수정되면서 각 커밋이 트랜잭션 로그에 반영되면, 이러한 변경 사항은 DELETE, UPDATE 이벤트로 발생한다.

#### Snapshot window
스냅샷에서 뒤늦게 발생하는 이벤트와 충돌하지 않기 위해 윈도우를 적용한다. 윈도우가 열리면 chunk를 처리하는데 Debeizum은 스냅샷 레코드를 메모리 버퍼로 전달한다. 
메모리 버퍼에 저장된 데이터의 PK와 유입되는 이벤트의 PK를 비교하여, 일치하는 것이 없으면 카프카 토픽에 전송된다. 일치하는 레코드가 있으면 버퍼의 READ 이벤트를 버리고 새로 유입된 데이터를 카프카 토픽에 넣는다. 윈도우가 끝난 후에는 관련된 트랜잭션이 없는 READ 이벤트만 남으므로 남은 이벤트를 카프카 토픽에 전송한다.


#### Trigger incremental snapshots
현재 증분 스냅샷을 시작하는 유일한 방법은 소스 데이터베이스의 signaling 테이블에 임시 스냅샷 신호를 보내는 것이다. `INSERT` 이벤트가 발생하면 Debezium은 signaling 테이블의 신호를 감지하여 스냅샷 작업을 실행한다.

signaling 데이터 수집은
- 소스 데이터베이스에 존재하고
- `signal.data.collection` 에서 지정된다.

예를 들어 데이터 수집을 실행하려면 아래와 같이 이벤트가 발생한다.
```sql
INSERT INTO myschema.debezium_signal(id, type, data)
values ('ad-hoc-1',  
        'execute-snapshot',  
        '{"data-collections": ["schema1.table1", "schema2.table2"],  
        'type':"incremental", 
        'additional-conditions':[{"data-collection":"schema1.table1" ,"filter":"color=\'blue\'"}]}'
        ); 
```

데이터 수집을 중단하려면
```sql
INSERT INTO <signalTable> (id, type, data)
values ('<id>', 
        'stop-snapshot', 
        '{"data-collections": ["schema1.table1", "schema2.table2"],  
        "type":"incremental"}');
```

#### Read-only incremental snapshots 
MySQL 커넥터를 사용하면 데이터베이스에 대한 Read-only 연결로 증분 스냅샷을 실행할 수 있다. Read-only 액세스로 증분 스냅샷을 실행하기 위해 커넥터는 실행된 **Global Transaction ID(GTID)를 low, high 워터마크**로 사용한다. binlog 이벤트나 서버의 heartbeats의 GTID와 low, high 워터마크를 비교하여 chunk의 윈도우를 업데이트한다.

```java
public abstract class BinlogReadOnlyIncrementalSnapshotChangeEventSource<P extends BinlogPartition, O extends BinlogOffsetContext>
        extends AbstractIncrementalSnapshotChangeEventSource<P, TableId>
    public BinlogReadOnlyIncrementalSnapshotChangeEventSource(BinlogConnectorConfig            connectorConfig,
                                                              JdbcConnection jdbcConnection,
                                                              EventDispatcher<P, TableId> dispatcher,
                                                              DatabaseSchema<?> databaseSchema,
                                                              Clock clock,
                                                              SnapshotProgressListener<P> progressListener,
                                                              DataChangeEventListener<P> dataChangeEventListener,
                                                              NotificationService<P, O> notificationService) {
        super(connectorConfig, jdbcConnection, dispatcher, databaseSchema, clock, progressListener, dataChangeEventListener, notificationService);
        this.gtidSetFactory = connectorConfig.getGtidSetFactory();
    }

    @Override
    public void processHeartbeat(P partition, OffsetContext offsetContext) throws InterruptedException {
        readUntilGtidChange(partition, offsetContext);
    }

    private void readUntilGtidChange(P partition, OffsetContext offsetContext) throws InterruptedException {
        String currentGtid = getContext().getCurrentGtid(offsetContext);
        while (getContext().snapshotRunning() && getContext().reachedHighWatermark(currentGtid)) {
            getContext().closeWindow();
            sendWindowEvents(partition, offsetContext);
            readChunk(partition, offsetContext);
            if (currentGtid == null && getContext().watermarksChanged()) {
                return;
            }
        }
    }

    private void updateLowWatermark() {
        getExecutedGtidSet(getContext()::setLowWatermark);
    }

    private void updateHighWatermark() {
        getExecutedGtidSet(getContext()::setHighWatermark);
    }

public class MySqlReadOnlyIncrementalSnapshotChangeEventSource extends BinlogReadOnlyIncrementalSnapshotChangeEventSource<MySqlPartition, MySqlOffsetContext> 

    @Override
    protected void getExecutedGtidSet(Consumer<GtidSet> watermark)
```



---
### Reference
- [Debezium MySQL Source connector](https://debezium.io/documentation/reference/stable/connectors/mysql.html)
- 데이터중심어플리케이션

추가로 [Debezium Design Documents](https://github.com/debezium/debezium-design-documents/tree/3c0423e7cae884f54d45171ef47c07101ed67afd)를 참고하면 좋을 것 같다.