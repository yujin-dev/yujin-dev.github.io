---
title: "CDC pipeline"
category: "cdc-pipeline"
---

## CDC pipeline

CDC 파이프라인을 통해 데이터의 point-in-time access가 가능하도록 한다. 
1. TRIGGER 기반 : 테이블에 **트리거**를 걸어 쿼리 이력을 관리한다.
2. UPDATE TIMESTAMP 사용 : **업데이트 시간에 대한 칼럼**을 추가하여 쿼리 실행 시간을 기반으로 관리한다.
3. LOG 기반 : PostgreSQL의 경우 **WAL**, MySQL의 경우 **binlog**를 활용하여 관리한다.

위와 같이 사용하는데 LOG기반의 CDC가 가장 많이 활용된다.

![Untitled](img/postgres-cdc.png)

## Data Fusion : BigQuery sync with RDBMS
Cloud SQL과 BigQuery 데이터를 동기화하기 위해 Data Fusion을 사용하여 파이프라인을 [A Deep dive into Cloud Data Fusion "Replication" Feature | CDC pipeline from MS SQL Server to](https://blog.searce.com/a-deep-dive-into-cloud-data-fusion-replication-feature-cdc-pipeline-from-ms-sql-server-to-5534ef58f074)를 참고한다.

Cloud SQL에서 MySQL를 사용하는 경우 binary log를 활성화하여 Data Fusion에서 CDC를 기반으로 동기화된다.

### MySQL - BigQuery Replication

> 참고 : [Database replication to BigQuery using change data capture | Cloud Architecture Center | Google Cloud](https://cloud.google.com/architecture/database-replication-to-bigquery-using-change-data-capture)

초기 데이터는 BigQuery에 덤프해놓고 이후에 변경 사항은 CDC에서 처리한다. 변경된 데이터를 Delta table에 올리고 기존의 Main Table과 MERGE한다.

다음과 같은 조인 방식이 있다.

- **즉각적 일관성 방식**: 쿼리는 복제된 데이터의 현재 상태를 반영합니다. 즉각적 일관성에는 기본 테이블과 델타 테이블을 조인하는 쿼리가 필요하며 각 기본 키에 대한 최신 행을 선택합니다.
    
    ```bash
    bq mk --view \
    "SELECT * EXCEPT(change_type, row_num)
    FROM (
      SELECT *, ROW_NUMBER() OVER (PARTITION BY id ORDER BY change_id DESC) AS row_num
      FROM (
        SELECT * EXCEPT(change_type), change_type
        FROM \`$(gcloud config get-value project).cdc_tutorial.session_delta\` UNION ALL
        SELECT *, 'I'
        FROM \`$(gcloud config get-value project).cdc_tutorial.session_main\`))
    WHERE
      row_num = 1
      AND change_type <> 'D'" cdc_tutorial.session_latest_v
    ```
    
- **비용 최적화 방식**: 데이터 가용성이 약간 지연되는 대신 더 빠르고 저렴한 쿼리가 실행됩니다. 주기적으로 데이터를 기본 테이블에 병합할 수 있습니다.
    
    ```bash
    bq query \
    'MERGE `cdc_tutorial.session_main` m
    USING
      (
      SELECT * EXCEPT(row_num)
      FROM (
        SELECT *, ROW_NUMBER() OVER(PARTITION BY delta.id ORDER BY delta.change_id DESC) AS row_num
        FROM `cdc_tutorial.session_delta` delta )
      WHERE row_num = 1) d
    ON  m.id = d.id
      WHEN NOT MATCHED
    AND change_type IN ("I", "U") THEN
    INSERT (id, username, change_id)
    VALUES (d.id, d.username, d.change_id)
      WHEN MATCHED
      AND d.change_type = "D" THEN
    DELETE
      WHEN MATCHED
      AND d.change_type = "U"
      AND (m.change_id < d.change_id) THEN
    UPDATE
    SET username = d.username, change_id = d.change_id'
    ```
    
- **하이브리드 방식**: 요구사항 및 예산에 따라 즉각적 일관성 방식 또는 비용 최적화 방식을 사용합니다.