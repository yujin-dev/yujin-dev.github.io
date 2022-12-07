# SnowFlake

- 기존의 하둡이나 RDB 기술 기반으로 구현되지 않았다.
- 모든 https://community.snowflake.com/s/article/Error-Granting-individual-privileges-on-imported-database-is-not-allowed-Use-GRANT-IMPORTED-PRIVILEGES-instead 서비스 구성 요소는 공용 클라우드 인프라에서 실행된다.

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

## [Access Control](https://docs.snowflake.com/en/user-guide/security-access-control-overview.html)
snowflake에서 access control는 DAC와 RBAC의 결합으로 이루어진다. **DAC( Discretionary Access Control )**란 각각의 object에는 owner가 존재하여 권한을 부여해주는 것을 의미하고, **RBAC( Role-based Access Control )**는 Access privilegs가 roles에 할당되어 유저에 부여됨을 설명해준다.
- Securable object : access가 부여될 수 있는 대상이다. 
- Role : Privilege가 부여될 수 있는 대상이다.role은 다른 role에 할당될 수도 있어, role의 계층을 생성할 수 있다.  
- Privilege : object에 정의되는 access level이다. 
- User
securable object에 대한 엑세스는 *role에 할당되어 있는 privilege를 통해 가능*하다. 각각의 securable object에는 roles에 권한을 부여할 수 있는 owner가 있다. 

user-based access control과는 다른 구조이다.  
![](https://docs.snowflake.com/en/_images/access-control-relationships.png)

### Securable Object
![](https://docs.snowflake.com/en/_images/securable-objects-hierarchy.png)

object를 소유한다는 것은 role에 `OWNERSHIP` privilege가 있음을 나타낸다.   
반면에, managed access schema에서는 schema owner나 `MANAGE GRANT` privilege가 있는 role만이 object에 privilege를 부여할 수 있다.

### Roles
privilege가 부여될 수도, 취소될 수도 있는 주체이다. System-defined roles에는 몇 가지가 존재한다.

![](https://docs.snowflake.com/en/_images/system-role-hierarchy.png)

- ORGADMIN : organization level role
- ACCOUNTADMIN : top-level role 
- SECURITYADMIN 
- USERADMIN 
- SYSADMIN : 모든 custom role이 SYSADMIN role에 할당될 수 있도록 권장된다. 
- PUBLIC : pseudo-role로 모든 user, role에 자동으로 부여된다. 보통 explicit access control이 필요하지 않는 경우에 사용된다.

모든 active user session에는 *primary role*이라는 current role이 있다. session이 초기화되면 current role은 아래와 같이 결정된다.
- connection에서 명시된 role이 user에 부여되어 있으면, 해당 role이 current role이 된다.
- user에 role이 명시되지 않으면, default role이 current role이 된다.
- user에 role이 명시되지 않았으나, default role이 설정되어 있지 않으면 PUBLIC이 사용된다.

## Authentication

### Admin
- [Federation 인증 및 SSO](https://docs.snowflake.com/ko/user-guide/admin-security-fed-auth.html) : 대부분의 SAML 2.0 규격 벤더를 IdP로 지원한다.
    - SP( Service Provider ) : Snowflake 
    - IdP( Identity Provider ) : 외부 독립적인 엔티티로, credential를 생성 및 관리하고 SSO 액세스를 위한 사용자를 인증한다.

- [key pair 인증](https://docs.snowflake.com/ko/user-guide/key-pair-auth.html) : 2048비트 이상의 RSA 키 페어가 필요한데, OpenSSL을 사용하여 PEM(Privacy Enhanced Mail) public - private key pair를 생성할 수 있다. 
    1. Snowflake 커넥터 같은 클라이언트에서 개인키를 생성한다.
    ```console
    $ openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -out rsa_key.p8
    -----BEGIN ENCRYPTED PRIVATE KEY-----
    MIIE6TAbBgkqhkiG9w0BBQMwDgQILYPyCppzOwECAggABIIEyLiGSpeeGSe3xHP1
    wHLjfCYycUPennlX2bd8yX8xOxGSGfvB+99+PmSlex0FmY9ov1J8H1H9Y3lMWXbL
    ...
    -----END ENCRYPTED PRIVATE KEY-----
    ```
    2. 공개키를 생성한다.
    ```console
    $ openssl rsa -in rsa_key.p8 -pubout -out rsa_key.pub 
    -----BEGIN PUBLIC KEY-----
    MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAy+Fw2qv4Roud3l6tjPH4
    zxybHjmZ5rhtCz9jppCV8UTWvEXxa88IGRIHbJ/PwKW/mR8LXdfI7l/9vCMXX4mk
    ...
    -----END PUBLIC KEY-----
    ```
    3. 개인 - 공개 키 안전하게 저장
    4. 공개키를 Snowflake 사용자에 할당
    ```console
    $ alter user jsmith set rsa_public_key='MIIBIjANBgkqh...';
    ```
    `desc user jsmith;`로 사용자의 개인키를 확인할 수 있다.

- [MFA 사용](https://docs.snowflake.com/ko/user-guide/security-mfa.html) : ACCOUNTADMIN 역할의 모든 사용자는 MFA를 사용하는 것을 적극 권장된다.
- [OAuth](https://docs.snowflake.com/ko/user-guide/oauth.html) : 사용자 credential를 공유나 저장하지 않고 Snowflake에 접근하는 것을 허용하는 개방형 표준 프로토콜이다.   
    ![](https://docs.snowflake.com/ko/_images/oauth2-workflow.png)
    

### Client : [connect to Snowflake](https://docs.snowflake.com/en/user-guide/python-connector-example.html#connecting-to-snowflake)
- 기본 인증 및 세션 매개 변수 설정
    ```python
    con = snowflake.connector.connect(
    user='XXXX',
    password='XXXX',
    account='XXXX',
    session_parameters={
        'QUERY_TAG': 'EndOfMonthFinancials',
        }
    )
    ```
- SSO 사용 : federation 인증을 통해 SSO를 사용하여 연결 가능하다. IdP 세션을 통해 Snowflake에 접속한다. 대신 Programmtic SSO는 Okta만 이용이 가능하다.  
    ```
    Snowflake supports two methods of authenticating:
    - Browser-based SSO
    - Programmatic SSO (only for Okta)
    ```
- MFA 사용
- key pair 사용 : `private_key`를 개인키 파일로 설정
    ```python
    import snowflake.connector
    import os
    from cryptography.hazmat.backends import default_backend
    from cryptography.hazmat.primitives.asymmetric import rsa
    from cryptography.hazmat.primitives.asymmetric import dsa
    from cryptography.hazmat.primitives import serialization
    with open("<path>/rsa_key.p8", "rb") as key:
        p_key= serialization.load_pem_private_key(
            key.read(),
            password=os.environ['PRIVATE_KEY_PASSPHRASE'].encode(),
            backend=default_backend()
        )

    pkb = p_key.private_bytes(
        encoding=serialization.Encoding.DER,
        format=serialization.PrivateFormat.PKCS8,
        encryption_algorithm=serialization.NoEncryption())

    ctx = snowflake.connector.connect(
        user='<user>',
        account='<account_identifier>',
        private_key=pkb,
        warehouse=WAREHOUSE,
        database=DATABASE,
        schema=SCHEMA
        )

    cs = ctx.cursor()
    ```
- Proxy 서버 사용 : 아래의 환경 변수를 설정하여 접근한다.
    - HTTP_PROXY
    - HTTPS_PROXY
    - NO_PROXY
    
    Snowflake의 security model은 HTTPS 인증서를 사용하는 SSL(Secure Sockets Layer) proxies가 허용되지 않는다. proxy server는 반드시 공인 CA를 사용해야 한다.
- OAuth 연결 : OAuth로 연결해서 사용하려면 connection string은 `authenticator = oauth`로 설정하고 token을 지정해야 한다.

    ```python 
    ctx = snowflake.connector.connect(
        user="<username>",
        host="<hostname>",
        account="<account_identifier>",
        authenticator="oauth",
        token="<oauth_access_token>",
        warehouse="test_warehouse",
        database="test_db",
        schema="test_schema"
    )
    ```

## [Data Sharing](https://docs.snowflake.com/ko/user-guide/data-sharing-intro.html)
Secure Data Sharing은 계정 간에 실제 데이터가 복사되거나 전송되지 않는다. 모든 공유는 Snowflake의 고유 서비스와 메타 데이터 저장소를 수행된다. **공유 데이터는 consumer 계정의 저장소를 차지하지 않아 데이터 저장소 요금에 영향을 주지 않는다. 유일하게 부과되는 요금은 쿼리 처리를 위한 컴퓨팅 리소스 관련 요금이다.**

또한, 데이터 이동이 없으므로 보다 빠르고 쉽게 접근이 가능하다.
- Provider : DB 공유를 생성하고 DB object에 대한 액세스 권한을 부여한다. 
- Consumer : **읽기 전용** 계정이 생성되어 DB가 공유된다. 

여기서 *Sharing*은 데이터 공유를 위해 모든 정보를 캡슐화하는 Snowflake object이다. 구성 요소는 DB 및 스키마에 대한 접근 권한 등이 포함된다.   
![](https://docs.snowflake.com/ko/_images/data-sharing-shares.png) 



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

# Data Mesh
> [분산형 데이터 분석 아키텍처-데이터 매쉬](https://bcho.tistory.com/1379)

data mesh는 데이터 분석 시스템을 분산형 서비스 형태로 개발 및 관리하는 모델이다.
데이터 분석 시스템은 Data Warehouse -> Data Lake -> Data Mesh를 거쳐 발전하였다.

## 기존 아키텍쳐
Data Warehouse, Data Lake를 기반으로 하나의 중앙 집중화된 시스템에 데이터를 수집하고 분석하는 형태이다. 보통 데이터 엔지니어링 팀이 따로 있다.
하지만 도메인 지식의 부족이나 예산 및 인력 부족과 같은 문제가 야기된다. 

### Data Warehouse
전통적인 RDBMS 형태에서 데이터를 모아 분석하는 아키텍쳐이다. 파일이나 DB에서 데이터를 ETL이나 CDC방식으로 Data Warehouse에 저장한다.
- structured data를 처리하는데 유용하다.
- 보통 상용 소프트웨어와 하드웨어를 사용해야 하기에 인프라 비용이 높다.

### Data Lake
데이터 형식에 제한 없이 비정형 데이터까지 관리가 가능하다. 
Data Warehouse에서 기존의 RDBMS에서 배치로 데이터를 주기적으로 적재하였다면 Data Lake 기반에서는 log stream같은 실시간 streaming 데이터 처리가 가능하다.

보통 Hadoop/Spark 기반으로 구축되며 HDFS를 저장소로 사용하고,  실시간 스트리밍 처리는 Kafka, spark streaming을 사용한다.

## Data Mesh
데이터 엔지니어가 각 업무별로 할당되어 있는 형태로 업무에 해당하는 도메인에 적합한 기술을 사용하여 최적화가 가능하다.

### Data Catalog
서로 다른 조직 간 데이터를 서로 크로스 조회하려면 어디에 어떤 데이터가 있는지 찾을 수 있어야 한다. 데이터 거버넌스 측면에서 데이터 검색 및 메타 데이터 관리에 대한 요소가 반드시 필요하다. 

### 실시간 streaming
실시간 데이터 처리는 message queue를 활용한다. 1:N message delivery가 가능해야 하는데 실시간 데이터 큐는 DB는 아니지만 data asset으로 분류되어 catalog에 등록되어 관리되어야 한다.

### DevOps
데이터 분석 시스템이 플랫폼화되는 것이 이상적이며 DevOps를 통해 개발 및 운영되어야 한다.

# DBT
DBT는 아래와 같이 ETL에서 Transformation을 수행한다.  
![](https://miro.medium.com/max/1400/0*gwL5iaxSMgrilZQI)

**유일한 기능은 코드를 통해 SQL로 컴파일하여 DB에서 실행시키는 것이다.**

Snowflake외에 Postgresql, BigQuery 등에서 지원된다.
- 파이썬으로 작성된 오픈소스이다.
- CLI는 데이터 파이프라인 실행을 위한 기능을 제공한다.
- UI는 문서화 작업을 위한 것이다. 
- 모든 *Model*은 원하는 방식으로 데이터를 변환하기 위해 다른 모델과 함께 조율되는 SELECT문이다.  
    ![](https://miro.medium.com/max/1400/0*ONcosYrul6BgIT94)  
    위와 같이 *jinja*는 소스에 없는 technical 행을 삽입하는데 사용된다.

    모든 DBT model은 스키마 정의로 보완되는데, 코드 베이스로 저장되면 모든 단계를 쉽게 이해할 수 있다.

> 출처 : [DBT: A new way to transform data and build pipelines at The Telegraph](https://medium.com/the-telegraph-engineering/dbt-a-new-way-to-handle-data-transformation-at-the-telegraph-868ce3964eb4)