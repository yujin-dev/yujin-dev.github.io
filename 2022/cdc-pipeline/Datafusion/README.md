---
title: "Data Fusion - replication"
category: "cdc-pipeline"
---

## Concept
Cloud Data Fusion is a fully managed service created by Google on the Google Cloud that supports data integration of multiple sources at any scale. It enables **code-free deployment of ETL and ELT pipelines in a visual point and click environment**, while the execution happens automatically in a Cloud Dataproc environment. No code is required to blend environments from multiple cloud sources and on-premises databases, either batch or streaming sources. Furthermore, the pipeline created can be easily validated, shared and reused across various teams in your organization.  
Data fusion is built on [CDAP](https://cdap.io/), an open-source framework for building data analytics applications that combine a user interface with a back-end stack of services in a Hadoop cluster.
> 출처 : [Introduction to Cloud Data Fusion](https://datadice.medium.com/introduction-to-cloud-data-fusion-1e2a3c2bf5ca)

요약하자면, Data Fusion이란 코드없이 설계할 수 있는 ETL(ELT) 파이프라인 서비스이다. CDAP기반으로 구축되어 백엔드에서 하둡과 연동되어 작동한다.

#### *Cask Data Application Platform (CDAP)*?
CDAP이란 Hadoop 에코시스템을 위한 통합 오픈 소스 개발 플랫폼이다. API를 제공하고 Hbase, HDFS, YARN, MapReduce, Hive, Spark같은 기존 Hadoop 인프라에 다양한 서비스를 정의하고 구현되어 있다. 이를 통해 MapReduce, ETL 파이프라인에서 엔터프라이즈 규모의 데이터 집약적인 어플리케이션을 실행할 수 있다.
> 출처 : [https://github.com/cdapio/cdap](https://github.com/cdapio/cdap)

## Replication Setup
data fusion에서 replication을 사용하여 BigQuery로 데이터를 복사할 수 있는데 **postgresql은 지원되지 않는다**.
MySQL, Oracle, MS SQL 중에 선택해서 사용한다.

![Untitled](../img/datafusion-mysql.png)

#### *Cloud SQL을 복제하는 경우*
Cloud SQL instance를 복제하는 경우는 아래에 따라 설정한다.

1) *Enable access to the instance from the slave.*   
    slave IP까지 authorized IP 범위에 추가시킨다.  
    > 참고 : [Configuring access control for non-App Engine applications](https://download.huihoo.com/google/gdgdevkit/DVD1/developers.google.com/cloud-sql/docs/access_control.html#appaccess)

2) *Enable the binary log using the Cloud SQL API.*  
    ```bash
    # MySQL binlog를 활성화
    $ gcloud config set projectyour-project-id
    $ gcloud sql instances patch --enable-bin-logyour-instance-name
    ```


### Cluster 생성

DataFusion은 Dataproc cluster를 생성하고 source DB에 연결하여 binary log로부터의 CDC를 실행하게 된다.

- Data Fusion 하나의 인스턴스 내에서 한 개의 job을 기준으로 하나의 클러스터가 생성된다.  
	![Untitled](../img/cdap-cluster.png)  
	![Untitled](../img/cdap-cluster-detail.png)
- Master Node 1, Worker Node 2개로 설정하니 다음과 같이 3개의 Node(VM)가 생성되었다.  
  ![](../img/worker-node-conf.png)
	![Untitled](../img/cdap-nodes.png)	 

- Replication Job을 중단하면 클러스터도 자동으로 함께 삭제됨을 알 수 있다.(Deleting)  
  ![Untitled](../img/cdap-deleting.png)

### Comparison

위와 같이 설정한 throughput은 1GB이하 /hr, 1 master + 2 worker 클러스터에 대해 2개의 Job으로 구분하여
1. 99개의 테이블 복제( 1GB 이하 )
2. 11개의 테이블 복제( 1 ~ 9GB )
경우를 비교한다.

#### **Resource 사용량**
다른 리소스 현상은 비슷한데 테이블 크기가 큰 11개의 테이블 로드로 구성된 task가 CPU를 많이 사용하였다.  

![Untitled](../img/over-max-cpu.png)

#### **처리 속도**
크기가 1 ~ 10GB인 테이블 11개인 경우 20분동안 active table이 하나였는데 크기가 1GB이하인 테이블 99개의 경우 20분 동안 3개의 active table이 생겼다.

replicate하려는 테이블 갯수가 더 많은데도 같은 throughput에서 활성화되는데 더 빠른 것으로 보아 **테이블의 갯수보다 크기에 따라 task의 진척도에 차이가 있는 것 같다.**

throughput을 늘렸더니 ( 당연하겠지만 ) 더 빨라짐을 확인하였다.

- throughput이 1GB 이하 /hr
  ![Untitled](../img/perf1.png)

- throughput이 1GB ~ 10GB/hr ]
  ![Untitled](../img/perf2.png)

시간이 지나면서 활성화된 테이블은 복제되는 데이터 양이 점점 늘어남을 알 수 있다.  
![Untitled](../img/perf3.png)


#### *추가적으로,* 
Worker node가 없는 단일 노드 클러스터에서는 실행이 되지 않는 것으로 확인됨: 단일 노드 클러스터( 4CPU, 8GB )에서 20분 가량 처리가 없었는데 2개의 Worker node로 구성한 클러스터로 돌리니 약 7분만에 active table이 발생하였다.

## Bug Report

### Error on Provisioning 
Data Fusion에서 파이프라인을 배포하고 시작하니 provisioning이 실패하였다.   

```bash
PROVISION task failed in REQUESTING_CREATE state for program run program_run:default.test-2.-SNAPSHOT.worker.DeltaWorker.f10567d8-b0e7-11ec-a3f1-42bae283f4a8 due to Dataproc operation failure: INVALID_ARGUMENT: Insufficient 'CPUS' quota. Requested 1.0, available 0.0..

```  
compute engine을 설정하는데 있어 할당량에 비해 오버 스펙으로 설정해서 할당량이 초과되는 문제가 있었다. 확인해보니 실제로 모니터링에서 CPUS가 100% 차지하는 현상이 있었다.

![Untitled](../img/quotas.png)

 Quotas
할당량 제도로 인해 리전마다, 리소스마다 할당량이 정해져 있어 그 이상을 넘어서는 사용할 수 없다. 할당량이 남아도 어떤 리전의 리소스를 쓰고자 할 때 전부 사용 중이라면 쓸 수가 없다. 

> 참고: [Resource quotas | Compute Engine Documentation | Google Cloud](https://cloud.google.com/compute/quotas#gcloud)

### Error on DeltaWorker
해당 이슈는 DB jar파일 관련한 드라이버 문제로 추측된다.

```
2022-03-31 12:38:59,551 - ERROR [worker-DeltaWorker-0:i.c.c.i.a.r.ProgramControllerServiceAdapter@92] - Worker Program 'DeltaWorker' failed.
...
2022-03-31 12:38:59,564 - ERROR [worker-DeltaWorker-0:i.c.c.i.a.r.ProgramControllerServiceAdapter@93] - Worker program 'DeltaWorker' failed with error: expected primitive class, but got: class com.google.api.client.json.GenericJson. Please check the system logs for more details.
```

### `The specified bucket does not exist.`

```
2022-04-07 03:29:03,635 - WARN  [runtime-scheduler-16:i.c.c.r.s.c.DataprocUtils@94] - GCS path cdap-job/733b927a-b622-11ec-a39d-aea9e7c408fb was not cleaned up for bucket df-2356261784124773891-b6chvo5u3mi6zdcvhqug2nlzci due to The specified bucket does not exist.. 
com.google.cloud.storage.StorageException: The specified bucket does not exist.
...
Caused by: com.google.api.client.googleapis.json.GoogleJsonResponseException: 404 Not Found
{
  "code" : 404,
  "errors" : [ {
    "domain" : "global",
    "message" : "The specified bucket does not exist.",
    "reason" : "notFound"
  } ],
  "message" : "The specified bucket does not exist."
}
...
```
Data Fusion 인스턴스를 삭제하고 재생성하니 해결되었다.(이전에 임의로 버킷을 삭제하였는데 인스턴스 내에서 사용하던 스토리지가 필요한 것으로 보인다.)

> 참고: [default-xf-replication-workers-DeltaWorker-0192c657-b683-11ec-b253-eaa8cd9145e1.log](../img/default-xf-replication-workers-DeltaWorker-0192c657-b683-11ec-b253-eaa8cd9145e1.log)

### `Failed to load a batch of changes from GCS into staging table`
해당 오류는 데이터를 로드할 수 없다는 내용인데 BigQuery에서 받아들일 수 없는 문자( 해시값 같은 )가 포함되어 있었던 것으로 추정된다.

> 참고: [Google Cloud Data Fusion MySQL replication job Failed to merge a batch of changes from the staging table](https://stackoverflow.com/questions/66640349/google-cloud-data-fusion-mysql-replication-job-failed-to-merge-a-batch-of-change)

### `NoNode`

```bash
2022-04-08 04:00:27,696 - INFO [zk-client-EventThread:o.a.t.y.YarnTwillController@236] - Failed to access application worker.default.replication-job.DeltaWorker application_1649390038493_0001 live node in ZK, resort to polling. 
Failure reason: KeeperErrorCode = NoNode for /instances/567333d2-2ad3-4965-84e9-447060393149
```