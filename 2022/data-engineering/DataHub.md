> Data Discovery

# DataHub
[DataHub: Popular metadata architectures explained](https://engineering.linkedin.com/blog/2020/datahub-popular-metadata-architectures-explained)를 참고하여 작성하였다.

먼저 data catalog란 조직의 데이터에 대한 inventory이다. 메타 데이터를 사용하여 데이터를 관리하는게 유용하다. 
데이터 검색 및 거버넌스를 지원하기 위해 메타 데이터를 수집하고 엑세스할 수 있도록 한다.

## Architecture
크게 3세대에 걸쳐 아키텍쳐가 변화하며 발전하였다.

![](https://content.linkedin.com/content/dam/engineering/site-assets/images/blog/posts/2020/12/metadata-5.png)

### 1세대 
![](https://content.linkedin.com/content/dam/engineering/site-assets/images/blog/posts/2020/12/metadata-1.png)

검색 쿼리를 위한 search index 및 App으로 조회한다. 

메타 데이터는 보통 DB catalog, Hive catalog, Kakfa schema registry, workflow orchestrator 로그 파일같은 메타 소스에 연결하여 크롤링 방식으로 수집한다. 
나아가서 spark 작업 같은 배치 작업이 메타 데이터를 대규모로 처리하고 로드할 수 있다.

## 2세대
![](https://content.linkedin.com/content/dam/engineering/site-assets/images/blog/posts/2020/12/metadata-2.png)

App에서 DB 메타 서비스가 분할되어 API를 통해 저장소에 계속적으로 push된다.

## 3세대
메타 데이터가 event-driven 형식으로 실시간으로 구독할 수 있고 메타 데이터 모델이 확장 가능하다.

1. log-oriented metadata
![](https://content.linkedin.com/content/dam/engineering/site-assets/images/blog/posts/2020/12/metadata-3.png)

stream-based API로 메타 데이터를 push하거나 CRUD 작업을 수행할 수 있다.

2. domain-oriented metadata
![](https://content.linkedin.com/content/dam/engineering/site-assets/images/blog/posts/2020/12/metadata-4.png)

엔티티 유형, 측면 및 관계를 통해 데이터 집합, 사용자, 그룹을 분리하여 설명할 수 있다.

최종적으로 아래와 같은 모델이다.  
![](https://content.linkedin.com/content/dam/engineering/site-assets/images/blog/posts/2020/12/metadata-5.png)



