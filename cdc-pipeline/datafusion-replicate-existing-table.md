---
title: "Data Fusion - replication( existing table reload )"
category: "cdc-pipeline"
---
Data Fusion에서 source 데이터베이스에서 존재하는 테이블을 BigQuery로 복제할 때 이미 기존에 테이블이 있는 경우에 대해 살펴본다.

![Untitled](img/replicate-existing.png)  
Replication Existing Data가 True로 설정되어 있는 경우, 테이블 복제 시에 기존 데이터를 전부 복제한다. 복제 작업이 이미 진행된 source 데이터베이스에 존재하는 테이블을 다시 복제한다면 데이터가 중복되어 오류가 발생할지, 자동으로 누락된 데이터를 채워넣을지 테스트한다.

- target dataset : `compustat_raw`
- target table : `spind_dly`

![Untitled](img/sample.png)

BigQuery에서 진행되는 작업을 아래와 진행된다.
1. Raw data source에서 테이블 전체를 복제하여 로드한다. 
2. 로드된 데이터는 GCS에 임시로 JSONL파일로 저장된다. 파일은 빅쿼리에 로드되면 삭제된다.
3. GCS에서 BigQuery로 데이터가 로드된다. ( Data Fusion job을 생성할 때 throughput은 1GB/1h으로 미리 설정되어 있는 상태이다. )  
  ![Untitled](img/load-log.png)

### MERGE 쿼리
기존 테이블의 `_sequence_num` 가장 큰 값과 임시 저장된 raw data 테이블의 `_sequence_num` 과 비교하여 기존의 Max값 이상의 데이터를 MERGE하여 업데이트한다.
    
```sql
MERGE compustat_raw.spind_dly as T
    USING (SELECT A.* FROM
    (SELECT * FROM compustat_raw._staging_spind_dly WHERE _batch_id = 1651460467442 AND _sequence_num > 14710639) as A
    LEFT OUTER JOIN
    (SELECT * FROM compustat_raw._staging_spind_dly WHERE _batch_id = 1651460467442 AND _sequence_num > 14710639) as B
    ON A.{key_column} = B._before_{key_column} AND A.{date_column} = B._before_{date_column} AND A._sequence_num < B._sequence_num
    WHERE B._before_{key_column} IS NULL AND B._before_{date_column} IS NULL) as D
    ON T.{key_column} = D._before_{key_column} AND T.{date_column} = D._before_{date_column}
    WHEN MATCHED AND D._op = "DELETE" THEN
      DELETE
    WHEN MATCHED AND D._op IN ("INSERT", "UPDATE") THEN
      UPDATE SET ...
    WHEN NOT MATCHED AND D._op IN ("INSERT", "UPDATE") THEN
      INSERT ...
```