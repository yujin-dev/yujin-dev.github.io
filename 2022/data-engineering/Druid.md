# Druid

Apache Druid는 OLAP 데이터베이스로, 데이터를 다차원 정보로 적재한다. 

![](https://img1.daumcdn.net/thumb/R1280x0/?scode=mtistory2&fname=https%3A%2F%2Fblog.kakaocdn.net%2Fdn%2FGAmhB%2Fbtq6VsjHEOd%2FRqOctI98bmP5KPeTd2eDe1%2Fimg.png)

다차원 정보는 기존의 row 단위를 몇 개의 필드를 통해 사용하는데, 데이터를 적재할 때 인덱싱하여 저장된다. Druid는 미리 dimension을 지정해서 데이터를 삽입할 때마다 인덱싱이 일어나 데이터 검색시에는 O(1)의 시간 복잡도를 가진다. 기존의 RDB가 O(n)의 시간 복잡도를 갖는 것에 비해 쿼리 속도가 훨씬 빠르다고 할 수 있다.

Druid는 Column-oriented이며, search system과 timeseries DB의 특징을 모두 포함하고 있다.

## [Architecture](https://druid.apache.org/docs/latest/design/architecture.html)
![](https://druid.apache.org/docs/latest/assets/druid-architecture.png)

Druid 서버는 크게 3가지로 구분된다.
- Master: Coordinator와 Overload 프로세스를 실행하여 데이터 접근과 적재를 관리한다.
- Query : Broker와 Router 프로세스를 실행하여 외부 clients의 쿼리를 처리한다.
- Data : Historical, MiddleManager 프로세스를 실행하여 적재 워크로드를 통해 데이터를 저장한다. 

외부 스토리지에도 종속성을 가지고 있다.
- Deep Storage: 모든 Druid 서버가 접근 가능한 공유 파일 스토리지다. 보통 S3나 HDFS같은 오브젝트 스토리지가 있다. Deep Storage는 백업용이나 Druid 프로세스간에 데이터를 이전할 때만 사용된다. Druid는 segments라는 파일에 데이터를 저장한다. Historical 프로세스는 디스크에 segments를 캐싱하여 디스크 및 인메모리 캐시에서 쿼리 결과를 가져온다. 
- Metadata Storage: segment 정보 같은 메타 데이터를 저장한다. 보통 RDBMS를 사용한다.
- ZooKeeper : service discovery, coordination, leader election에서 사용된다.

### Storage
Druid 데이터는 RDBMS에서 테이블과 같은 개념인 datasources에 저장되어 있다. 각각의 datasource는 **시간**에 따라 파티션되어 있다. 각각의 time range는 *chunk*라고 한다. 또 chunk내에서 데이터는 여러 *segments*로 나뉘어진다. 하나의 segment가 하나의 파일이고, 수백만의 row로 구성되어 있다. MiddelManager는 mutable하고 uncommitted한 segment를 생성한다. 주기적으로 segments는 commit되고, deep storage에 저장된다. 파일인 segment는 **columnar 형식으로 변환**하여 **인덱싱**되고, **압축**된다. segment의 entry 정보는 메타데이터에서 관리된다.



![](https://druid.apache.org/docs/latest/assets/druid-timeline.png)