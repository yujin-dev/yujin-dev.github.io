---
title: "Postgresql documentation 살펴보기 - Server Conf"
category: "db"
---
Server Configuration의 주요 요소를 살펴보기로 한다.

## Connections
#### `max_connections`
동시에 접속할 수 있는 최대 연결 갯수. 기본값은 100이다. standby server에서는 master server의 max_connections 이상은 설정되어야 한다.

## Memory
#### `shared_buffers`
서버가 사용하는 shared memory buffers 크기. 기본값은 128MB이다.
RAM이 1GB 이상이라면 `shared_buffers` 는 RAM 크기의 25% 설정하는 것이 적당하다.
PostgreSQL 서버는 OS 캐시에도 의존하기에 RAM 의 40% 이상은 `shared_buffers`에 할당되지 않는다. `shared_buffers` 설정에 따라 `max_wal_size`도 크기를 조정하는 것이 필요하다. 새로운 데이터를 write 할때 시간을 늘려서 작업을 수행하기 위함이다. 

#### `temp_buffers`
DB 세션의 temporary buffers에 사용되는 메모리의 최대값. 임시 테이블 접근에만 사용된다.

#### `work_mem`
임시 디스크 파일에 write 전에 쿼리 수행을 위한 메모리 최대치. 기본값은 4MB이다.
복잡한 쿼리일수록 sort(`ORDER BY`, `DISTINCT`, merge joins)나 hash(hash joins, hash-based aggregation, `IN` subquires ) 연산이 병렬로 실행되는데 세션마다 최대로 사용할 수 있는 메모리 값이다. 따라서, 전체 메모리는 `work_mem`값의 몇 배가 될 수 있다. `work_mem`은 세션 갯수와 연관되어 1/(`max_connections` * 2)로 설정하는 것이 적당하다.

#### `maintenance_work_mem`
`VACUUM`, `CREATE INDEX`, `ALTER TABLE ADD FOREIGH KEY`와 같은 maintenance 연산에 사용되는 메모리의 최대값. 기본값은 64MB이다. 이러한 연산은 한번에 한번만 수행될 수 있고 동시에 돌아가는 경우가 없기에 `work_mem`보다 크게 설정하는 것이 안전하다. 

`autovacuum_max_worker`만큼 곱해 메모리가 할당될 수 있으므로 너무 크게 잡지 않는 것이 중요하다.

#### `autovacuum_max_mem`
autovacuum worker 프로세스에서 사용할 수 있는 메모리 최대치. 

## Disk
## Kernel Resource Usage
## Cost-based Vacuum Delay
`VACUUM`, `ANALYZE` 실행 중, I/O 연산 수행에 수반되는 cost를 추적과 관련된다.
## Background Writer
dirty shared buffers와 관련된 작업인데 clean shared buffers가 충분하지 않으면 background writer는 파일 시스템에 dirty buffers를 write하여 clean shared buffers를 생성한다.(?) 

## Asynchronous Behavior
#### `max_worker_processes`
backgroun process 최대 갯수. 기본값은 8이다. 
`max_parallel_workers`, `max_parallel_maintenance_workers`, `max_parallel_workers_per_gather`도 함께 조정해야 한다.

## Write Ahead Log
#### `wal_buffers`
디스크에 write되기 전 WAL 데이터에 사용되는 shared memory 크기. 기본값은 -1로 `shared_buffers`의 1/32을 의미한다. 매 transaction commit마다 WAL buffers는 disk에 write된다. 

#### `checkpoint_timeout`
자동 WAL checkpoints의 최대 시간. 기본값은 `5min`으로 단위가 없으면 기본적으로 seconds이다. 

## Logging
#### `log_min_duration_statement`
statement가 최소 일정 시간동안 실행된 경우 로그를 남길 때의 duration. 예를 들어 `250ms`라고 설정하면 `250ms` 이상인 statement만 로그가 남는다. 최적화되지 않은 쿼리를 추적할 때 유용하다. 기본값은 -1로 비활성화 상태이다. `log_min_duration_sample`를 override하여 적용된다.

#### `log_connection`
서버에 연결을 시도한 connection을 로그로 남긴다. 기본값은 `off`
#### `log_duration`
완료된 statement의 duration을 로그로 남긴다.
#### `log_statement`
로그 남길 SQL statement를 설정한다.
- `none`: 기본값
- `ddl`: 모든 definition statements.(`CREATE`, `ALTER`, `DROP`)
- `mod`: 모든 `ddl` statements + data-modifying statemtns(`INSERT`, `UPDATE`, `DELETE`, `TRUNCATE`, `COPY FROM`, `PREPARE`, `EXECUTE`, `EXPLAIN ANALYZE`)
- `all`: 모든 statements

#### Log Output as CSV
`log_destination`에 `csvlog`를 포함시켜 CSV 형태로 로그 파일을 생성할 수 있다.
```sql
COPY postgres_log FROM '/full_path/logfile.csv' WITH csv;
```

## Automatic Vacuuming
#### `autovacuum`
autovacuum을 실행할지 여부를 설정한다. 개별 테이블마다 autovacuum을 비활성화할 수 있다.

## Client Connection
#### `idle_in_transaction_session_timeout`
정해진 시간보다 `idle` 상태인 세션은 끊는다. 

