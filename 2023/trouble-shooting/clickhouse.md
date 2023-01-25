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