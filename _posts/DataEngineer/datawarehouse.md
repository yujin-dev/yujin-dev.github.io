>DataWarehouse

# SnowFlake

- 기존의 하둡이나 RDB 기술 기반으로 구현되지 않았다.
- 모든 Snowflake 서비스 구성 요소는 공용 클라우드 인프라에서 실행된다.

## architecture
기존의 공유 디스크 및 비공유 데이터베이스가 결합된 하이브리드 아키텍쳐이다.
- as 공유 디스크 : 플랫폼 내 모든 컴퓨팅 노드에서 엑세스 가능한 중앙 데이터 레포지토리를 사용한다
- as 비공유 데이터베이스 : 전체 데이터 셋의 일부를 각 노드의 로컬에 저장하여 MPP(대규모 병렬 처리) 컴퓨팅 클러스터 기반으로 쿼리를 처리한다.

![](https://docs.snowflake.com/ko/_images/architecture-overview.png)

### 데이터 저장
데이터를 내부의 최적화되고 압축된 column-base로 저장한다.  
유저는 snowflake가 저장하는 데이터 객체를 직접 확인하거나 액세스할 수 없으며 SQL 쿼리 연산으로만 접근 가능하다.

### 쿼리 처리
쿼리 처리는 가상 웨어하우스를 사용한다. 가상 웨어하우스는 여러 컴퓨팅 노드로 구성된 MPP 컴퓨팅 클러스터이다.

### 클라우드
snowflake의 여러 구성 요소와 연계되어 로그인부터 쿼리 전달까지 사용자 요청을 처리한다.
- 인증
- 인프라 관리
- 메타데이터 관리
- 쿼리문 분석 및 최적화
- 엑세스 제어

## User Guide
python, Spark, JDBC, ODBC 등 기타 클라이언트용 Snowflake 제공 드라이버 및 커넥터를 사용 가능하다.

# BigQuery

## Storage
대규모 데이터 세트에 대한 쿼리 실행에 최적화되어 있다.

스토리지와 컴퓨팅이 분리되어 있는 구조이다. 각각을 필요에 따라 독립적으로 확장할 수 있다.   
![](https://cloud.google.com/bigquery/images/bigquery-storage-architecture.png?hl=ko)

쿼리 엔진이 여러 워커에 작업을 동시에 분산하여 쿼리를 처리하고 결과를 수집한다.
Petabit 네트워크를 사용해 데이터가 빠르게 이동할 수 있다.

- Managed : 스토리지 리소스르르 프로비저닝하거나 예약할 필요가 없다.
- Durable : 여러 availability zone에 걸쳐 데이터를 복제하여 fault-tolerant하다. 아래와 같이 파일이 3개의 복제본으로 각각 다른 데이터 센터에 나눠서 저장된다.  
    ![](https://t1.daumcdn.net/cfile/tistory/25319A3C576258780B)
- Encrypted : 디스크에 기록되기 전 모든 데이터가 암호화된다.
- Efficient : 효율적인 인코딩 형식을 사용한다.

### Table 
- 구조화된 데이터
- table clone은 원본 테이블과 차이만 저장한다.
- 테이블 스냅샷 : 테이블 스냅샷을 원본 테이블과 차이만 저장한다.
- Materialized views : 뷰 쿼리 결과를 주기적으로 캐시하는 뷰이다.( 임시 테이블 )

### Column-base
기존의 RDB는 row-level로 각 필드가 순차적으로 표시된다. 개별 레코드를 효율적으로 조회 가능하나 모든 필드를 읽어야 하는 비효율성이 있다.  
이에 반해 BigQuery는 column-base로 column을 개별적으로 저장하여 개별 column을 스캔하는데 효율적이다.

특히 수백만 개의 row에 대한 칼럼의 합계를 계산하는 경우 모든 row의 칼럼을 읽지 않아도 특정 column 데이터만 읽으면 된다.

- column 데이터는 row-level보다 중복성이 높아 인코딩으로 읽기 성능이 올라가 더 큰 데이터 압축이 가능하게 된다.
- OLTP보다는 OLAP에 적합하다.

![](https://t1.daumcdn.net/cfile/tistory/2277A43C5762587B34)   
- Colossus라는 분산 스토리지가 맨 아래 저장소로 있고, Jupiter라는 TB급 네트워크로 컴퓨팅 노드와 통신한다.
- 컴퓨팅 계층은 Leaf/Mixer1/Mixer0으로 구성되어 있다. Colossus에서 읽은 데이터를 처리해서 위 계층으로 올리면서 처리된다.
---
출처
- [조대협의 블로그-구글 빅데이타 플랫폼 빅쿼리 아키텍쳐 소개](https://bcho.tistory.com/1117)
- [BigQuery 공식문서](https://cloud.google.com/bigquery/docs/introduction?hl=ko)