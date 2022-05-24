# CDC pipeline

## Cloud SQL to BigQuery(using CDC)

### Data Fusion 파이프라인 생성시

![Untitled](./img/Untitled%203.png)

![Untitled](./img/Untitled%204.png)

### Datastream + Dataflow + BigQuery

![](./img/Untitled%2010.png)

1. MySQL 에 데이터가 변경되면 Datastream에서 이를 변경 사항을 Cloud Storage에 파일로 업데이트한다.

![change data capture file in Cloud Storage](./img/Untitled%208.png)

2. Dataflow - Datastream to BigQuery 탬플릿을 생성하여 PubSub 알람을 통해 변경 사항을 BigQuery에 반영한다.

3. BigQuery에 로그 테이블에 데이터 변경 사항이 replicate되고 이후 원본 테이블과 MERGE한다.

![`sec_mthprc_log` table](./img/Untitled%207.png)

![MERGE triggered in BigQuery](./img/Untitled%205.png)

아래와 같이 변경 사항이 실시간으로 반영되진 않는 것으로 보인다( 설정을 따로 해줘야 하나 ? )

- _log 테이블에는 데이터가 업데이트되었는데 raw table에는 반영되지 않음

![`sec_mthprc` table](./img/Untitled%206.png)

### [ references ]
PostgreSQL CDC pipeline

[Stream changes from Amazon RDS for PostgreSQL using Amazon Kinesis Data Streams and AWS Lambda | Amazon Web Services](https://aws.amazon.com/ko/blogs/database/stream-changes-from-amazon-rds-for-postgresql-using-amazon-kinesis-data-streams-and-aws-lambda/)

[Real-time CDC replication into BigQuery | Google Cloud Blog](https://cloud.google.com/blog/products/data-analytics/real-time-cdc-replication-bigquery)

[CDC, MySQL data migration to cloud | Google Cloud Blog](https://cloud.google.com/blog/products/data-analytics/how-to-move-data-from-mysql-to-bigquery)

![Untitled](./img/Untitled.png)


Debezium server

[Postgres CDC Solution with Debezium & Google Pub/Sub | Infinite Lambda](https://infinitelambda.com/post/postgres-cdc-debezium-google-pubsub/)

[Change Data Capture with Debezium Server on GKE from CloudSQL for PostgreSQL to Pub/Sub](https://medium.com/google-cloud/change-data-capture-with-debezium-server-on-gke-from-cloudsql-for-postgresql-to-pub-sub-d1c0b92baa98)

debezium

[Debezium 1.7.0.Final Released](https://debezium.io/blog/2021/10/04/debezium-1-7-final-released/)

[Debezium Server](https://debezium.io/documentation/reference/operations/debezium-server.html)

[Debezium Server to Cloud PubSub: A Kafka-less way to stream changes from databases](https://medium.com/nerd-for-tech/debezium-server-to-cloud-pubsub-a-kafka-less-way-to-stream-changes-from-databases-1d6edc97da40)

Dataflow : Datastream to BigQuery

`https://cloud.google.com/dataflow/docs/guides/templates/provided-streaming#running-the-datastream-to-bigquery-template`

cloud storage 알람 설정

[Configure Pub/Sub notifications for Cloud Storage | Google Cloud](https://cloud.google.com/storage/docs/reporting-changes#gsutil)

pub/sub

[Create and use subscriptions | Cloud Pub/Sub Documentation | Google Cloud](https://cloud.google.com/pubsub/docs/create-subscription)

Dataflow vs. Data Fusion

[Google Cloud Dataflow v/s Google Cloud Data Fusion](https://stackoverflow.com/questions/56946958/google-cloud-dataflow-v-s-google-cloud-data-fusion)

DataFlow - Apache Beam

[[GCP] Apache Beam 사용하기](https://medium.com/@kiseon_twt/gcp-apache-beam-%EC%82%AC%EC%9A%A9%ED%95%98%EA%B8%B0-8737122b276b)

![Untitled](./img/Untitled%201.png)

Apache Beam

![Untitled](./img/Untitled%202.png)