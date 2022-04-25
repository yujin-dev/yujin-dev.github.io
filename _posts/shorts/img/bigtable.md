# BigTable

- HBase의 기반이며 더 좋은 성능을 보임
- 칼럼형 데이터베이스로 용량이 큰 데이터도 빠른 처리가 가능: tablet log + memtable
    - 로그를 통해 데이터가 유실되지 않고 보존되도록 하며 메모리 저장소에 올려 빠른 처리가 가능( Read / Write latency를 줄임 )
- SSTable을 통해 분산 시스템을 구성할 수 있으며 공유 파일시스템을 기반으로 하기에 가능하다  데이터 파일의 포인트만 바꿔주면 병목없이 처리가 가능하며 확장이 용이하다.
- BigQuery와 마찬가지로 Collosus를 기반으로 한다.

[HBase와 구글의 빅테이블 #1 - 아키텍쳐](https://bcho.tistory.com/1217)

[Bigtable 개요 | Cloud Bigtable 문서 | Google Cloud](https://cloud.google.com/bigtable/docs/overview?hl=ko)

인스턴스 : 데이터의 컨테이너

인스턴스에는 클러스터가 한 개 이상 있으며 테이블은 인스턴스에 속한다.

## BigTable with Hadoop

[Hadoop 클러스터 만들기 | Cloud Bigtable 문서 | Google Cloud](https://cloud.google.com/bigtable/docs/creating-hadoop-cluster?hl=ko) 따라하기

### 오류 발생

```bash

$ gsutil mb gs://sample-bigtable-hadoop
$ gcloud dataproc clusters create dataproc-sample --bucket sample-bigtable-hadoop --region asia-northeast3 --num-workers 2 --master-machine-type n1-standard-4 --worker-machine-type n1-standard-4 --master-boot-disk-size 50GB --worker-boot-disk-size 100GB
$ mvn clean package -Dbigtable.projectID="project" -Dbigtable.instanceID="datastore"
...
[INFO] Scanning for projects...
[INFO] 
[INFO] --------------< com.example.bigtable:wordcount-mapreduce >--------------
[INFO] Building wordcount-mapreduce 0-SNAPSHOT
[INFO] --------------------------------[ jar ]---------------------------------
[INFO] ------------------------------------------------------------------------
[INFO] BUILD FAILURE
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  0.622 s
[INFO] Finished at: 2022-04-12T15:47:39+09:00
[INFO] ------------------------------------------------------------------------
[ERROR] Failed to execute goal on project wordcount-mapreduce: Could not resolve dependencies for project com.example.bigtable:wordcount-mapreduce:jar:0-SNAPSHOT: Could not find artifact jdk.tools:jdk.tools:jar:1.6 at specified path /usr/lib/jvm/java-11-openjdk-amd64/../lib/tools.jar -> [Help 1]
[ERROR] 
[ERROR] To see the full stack trace of the errors, re-run Maven with the -e switch.
[ERROR] Re-run Maven using the -X switch to enable full debug logging.
[ERROR] 
[ERROR] For more information about the errors and possible solutions, please read the following articles:
[ERROR] [Help 1] http://cwiki.apache.org/confluence/display/MAVEN/DependencyResolutionException
```