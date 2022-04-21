# BigQuery external query ?

아래와 같이 BigQuery 공식문서에 따르면 외부 쿼리에 대해 2가지 유형이 있다.

```text
외부 데이터 소스는 데이터가 BigQuery 스토리지에 저장되어 있지 않더라도 BigQuery에서 직접 쿼리할 수 있는 데이터 소스입니다.BigQuery는 다음과 같은 외부 데이터 소스를 지원합니다.

- Bigtable
- Cloud Spanner
- Cloud SQL
- Cloud Storage
- Drive

외부 데이터 소스의 사용 사례는 다음과 같습니다.

ELT(extract-load-transform) 워크로드의 경우 CREATE TABLE ... AS SELECT 쿼리를 사용하여 한 번에 데이터를 로드 및 정리하고 정리된 결과를 BigQuery 스토리지에 씁니다.
외부 데이터 소스에서 자주 변경되는 데이터와 BigQuery 테이블을 조인합니다. 외부 데이터 소스를 직접 쿼리하면 데이터가 변경될 때마다 BigQuery 스토리지를 새로고침할 필요가 없습니다.
BigQuery에는 외부 데이터를 쿼리하는 다음과 같은 두 가지 매커니즘이 있습니다.

# 외부 테이블

외부 테이블은 표준 BigQuery 테이블 역할을 하는 테이블입니다. 테이블 스키마를 포함한 테이블 메타데이터는 BigQuery 스토리지에 저장되지만 데이터 자체는 외부 소스에 있습니다.

외부 테이블은 임시 또는 영구적일 수 있습니다. 영구 외부 테이블은 데이터 세트 내에 포함되어 있으며 표준 BigQuery 테이블을 관리하는 것과 동일한 방식으로 관리합니다. 예를 들어 테이블 속성 보기, 액세스 제어 설정 등을 수행할 수 있습니다. 테이블을 쿼리하고 다른 테이블과 조인할 수 있습니다.

다음 데이터 소스에 외부 테이블을 사용할 수 있습니다.

- Bigtable
- Cloud Storage
- Drive

# 통합 쿼리

통합 쿼리는 쿼리 문을 외부 데이터베이스에 보내고 결과를 임시 테이블로 가져오는 방법입니다. 통합 쿼리는 BigQuery Connection API를 사용하여 외부 데이터베이스와 연결을 설정합니다. 표준 SQL 쿼리에서 EXTERNAL_QUERY 함수를 사용하여 쿼리 문을 외부 데이터베이스로 전송하며 이때 해당 데이터베이스의 SQL 언어를 사용합니다. 결과는 BigQuery 표준 SQL 데이터 유형으로 변환됩니다.

다음 외부 데이터베이스에서 통합 쿼리를 사용할 수 있습니다.

- Cloud Spanner
- Cloud SQL
```

외부 테이블은 데이터 소스를 BigQuery 테이블 자체에 로드할 수 있어 Table size를 차지하게 되지만 통합 쿼리는 쿼리를 전송하기만 하는 것으로 보인다.

