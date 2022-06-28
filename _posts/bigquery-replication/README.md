---
title: "Cloud SQL - Data Fusion - BigQuery"
category: "bigquery"
---

Cloud SQL과 BigQuery 데이터를 동기화하기 위해 Data Fusion을 사용하여 파이프라인을 [A Deep dive into Cloud Data Fusion "Replication" Feature | CDC pipeline from MS SQL Server to](https://blog.searce.com/a-deep-dive-into-cloud-data-fusion-replication-feature-cdc-pipeline-from-ms-sql-server-to-5534ef58f074)
와 같이 설계하였다.

Cloud SQL에서 MySQL의 경우 binary log를 활성화하여 Data Fusion에서 CDC를 기반으로 업데이트가 진행될 수 있도록 한다.

## MySQL - BigQuery Replication

[Database replication to BigQuery using change data capture | Cloud Architecture Center | Google Cloud](https://cloud.google.com/architecture/database-replication-to-bigquery-using-change-data-capture)

![Untitled](Untitled.png)

초기 데이터는 BigQuery에 덤프해놓고 이후에 변경 사항은 CDC에서 처리한다. 변경된 데이터를 Delta table에 올리고 기존의 Main Table과 MERGE 한다.

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

## Data Fusion
data fusion replication으로 BigQuery로 데이터를 복사할 수 있는데 postgresql 은 없다. 

![Untitled](Untitled%201.png)

MySQL로 연동하려면 binary log를 활성화시켜야 한다.

```
$ gcloud config set projectyour-project-id
$ gcloud sql instances patch --enable-bin-logyour-instance-name
```

## Enabling replication of a Cloud SQL instance

*To enable replication of a Cloud SQL instance, do the following:*

*1) Enable access to the instance from the slave.*  
    Specifically, you need to add the slave's IP address to the list of authorized IP ranges that can access the instance. For more information, see [Configuring access control for non-App Engine applications](https://download.huihoo.com/google/gdgdevkit/DVD1/developers.google.com/cloud-sql/docs/access_control.html#appaccess)

*2) Enable the binary log using the Cloud SQL API.*  
    Cloud SQL Admin Command LinecURL  
    Uses the `sql` command line tool in the [Google Cloud SDK](https://download.huihoo.com/google/gdgdevkit/DVD1/developers.google.com/cloud/sdk/index.html) 
    ```bash
    $ gcloud config set projectyour-project-id
    $ gcloud sql instances patch --enable-bin-logyour-instance-name    
    ```

![Untitled](Untitled%202.png)

## Bug Report

### Error on Provisioning 
Data Fusion에서 파이프라인을 배포하고 시작하니 provisioning이 실패하였다.   

```bash
PROVISION task failed in REQUESTING_CREATE state for program run program_run:default.test-2.-SNAPSHOT.worker.DeltaWorker.f10567d8-b0e7-11ec-a3f1-42bae283f4a8 due to Dataproc operation failure: INVALID_ARGUMENT: Insufficient 'CPUS' quota. Requested 1.0, available 0.0..

```  
compute engine을 설정하는데 있어 할당량에 비해 오버 스펙으로 설정해서 할당량이 초과되는 문제가 있었다. 확인해보니 실제로 모니터링에서 CPUS가 100% 차지하는 현상이 있었다.

![Untitled](Untitled%2011.png)


#### Quotas
할당량 제도로 인해 리전마다, 리소스마다 할당량이 정해져 있어 그 이상을 넘어서는 사용할 수 없다. 할당량이 남아도 어떤 리전의 리소스를 쓰고자 할 때 전부 사용 중이라면 쓸 수가 없다. 

> 참고: [Resource quotas | Compute Engine Documentation | Google Cloud](https://cloud.google.com/compute/quotas#gcloud)

### Error on DeltaWorker
해당 이슈는 DB jar파일 관련한 드라이버 문제로 추측된다.

```
2022-03-31 12:38:59,551 - ERROR [worker-DeltaWorker-0:i.c.c.i.a.r.ProgramControllerServiceAdapter@92] - Worker Program 'DeltaWorker' failed.
java.lang.IllegalArgumentException:
	at com.google.api.client.json.JsonParser.parseValue(JsonParser.java:900) ~[na:na]
	at com.google.api.client.json.JsonParser.parse(JsonParser.java:360) ~[na:na]
	at com.google.api.client.json.JsonParser.parse(JsonParser.java:335) ~[na:na]
	at com.google.api.client.json.JsonObjectParser.parseAndClose(JsonObjectParser.java:79) ~[na:na]
	at com.google.api.client.json.JsonObjectParser.parseAndClose(JsonObjectParser.java:73) ~[na:na]
	at com.google.auth.oauth2.GoogleCredentials.fromStream(GoogleCredentials.java:157) ~[na:na]
	at com.google.auth.oauth2.GoogleCredentials.fromStream(GoogleCredentials.java:134) ~[na:na]
	at io.cdap.delta.bigquery.BigQueryTarget$Conf.getCredentials(BigQueryTarget.java:277) ~[na:na]
	at io.cdap.delta.bigquery.BigQueryTarget$Conf.access$000(BigQueryTarget.java:184) ~[na:na]
	at io.cdap.delta.bigquery.BigQueryTarget.initialize(BigQueryTarget.java:82) ~[na:na]
	at io.cdap.delta.app.DeltaWorker.initialize(DeltaWorker.java:187) ~[na:na]
	at io.cdap.delta.app.DeltaWorker.initialize(DeltaWorker.java:75) ~[na:na]
	at io.cdap.cdap.internal.app.runtime.AbstractContext.lambda$initializeProgram$6(AbstractContext.java:602) ~[na:na]
	at io.cdap.cdap.internal.app.runtime.AbstractContext.execute(AbstractContext.java:562) ~[na:na]
	at io.cdap.cdap.internal.app.runtime.AbstractContext.initializeProgram(AbstractContext.java:599) ~[na:na]
	at io.cdap.cdap.internal.app.runtime.worker.WorkerDriver.startUp(WorkerDriver.java:77) ~[na:na]
	at com.google.common.util.concurrent.AbstractExecutionThreadService$1$1.run(AbstractExecutionThreadService.java:47) ~[com.google.guava.guava-13.0.1.jar:na]
	at java.lang.Thread.run(Thread.java:750) [na:1.8.0_322]
Caused by: java.lang.IllegalArgumentException: expected primitive class, but got: class com.google.api.client.json.GenericJson
	at com.google.api.client.util.Data.parsePrimitiveValue(Data.java:478) ~[na:na]
	at com.google.api.client.json.JsonParser.parseValue(JsonParser.java:869) ~[na:na]
	... 17 common frames omitted
2022-03-31 12:38:59,564 - ERROR [worker-DeltaWorker-0:i.c.c.i.a.r.ProgramControllerServiceAdapter@93] - Worker program 'DeltaWorker' failed with error: expected primitive class, but got: class com.google.api.client.json.GenericJson. Please check the system logs for more details.
```