## [23.01.25]
```
Code: 252. DB::Exception: Received from localhost:9000. DB::Exception: Too many partitions for single INSERT block (more than 100). The limit is controlled by 'max_partitions_per_insert_block' setting. Large number of partitions is a common misconception. It will lead to severe negative performance impact, including slow server startup, slow INSERT queries and slow SELECT queries. Recommended total number of partitions for a table is under 1000..10000. Please note, that partitioning is not intended to speed up SELECT queries (ORDER BY key is sufficient to make range queries fast). Partitions are intended for data manipulation (DROP PARTITION, etc).. (TOO_MANY_PARTS)
```
- `max_partitions_per_insert_block` : Limits the maximum number of partitions in a single inserted block. (Default value: 100)
- 해결 : `set max_partitions_per_insert_block = 0`으로 제한을 걸지 않음 

```
DB::Exception: Received from localhost:9000. DB::Exception: Memory limit (total) exceeded: would use 13.91 GiB (attempt to allocate chunk of 4239119 bytes), maximum: 13.90 GiB. OvercommitTracker decision: Query was selected to stop by OvercommitTracker.. (MEMORY_LIMIT_EXCEEDED)
```
- `max_memory_usage` : The maximum amount of RAM to use for running a query on a single server
- `max_memory_usage_for_user` : The maximum amount of RAM to use for running a user’s queries on a single server.

## [23.01.30]
```
2023.01.30 10:28:00.096308 [ 2841 ] {} <Error> Application: Code: 214. DB::ErrnoException: Could not calculate available disk space (statvfs), errno: 13, strerror: Permission denied. (CANNOT_STATVFS), Stack trace (when copying this message, always include the lines below):

0. ./build_docker/../src/Common/Exception.cpp:91: DB::Exception::Exception(DB::Exception::MessageMasked&&, int, bool) @ 0xdd7a815 in /usr/bin/clickhouse
```
- 해결 : user 'clickhouse'로 실행하지 않고 `sudo  /usr/bin/clickhouse-server --config-file /etc/clickhouse-server/config.xml --pid-file /var/run/clickhouse-server/clickhouse-server.pid --daemon`로 실행

## [23.01.31]
```
Code: 202. DB::Exception: Received from localhost:9000. DB::Exception: Too many simultaneous queries. Maximum: 100. (TOO_MANY_SIMULTANEOUS_QUERIES)
```

## [23.02.07]
```
DB::Exception: Direct select is not allowed. To enable use setting `stream_like_engine_allow_direct_select`. (QUERY_NOT_ALLOWED)
```
- kafka engine table을 사용할 때 따로 설정이 필요함
- 해결 : `set stream_like_engine_allow_direct_select=1`

## [23.02.09]
```
remote connection error
```
- [Connecting to ClickHouse from external network](https://groups.google.com/g/clickhouse/c/T8sSPOEqOMk)
- 해결 : uncomment `<listen_host>0.0.0.0</listen_host>`