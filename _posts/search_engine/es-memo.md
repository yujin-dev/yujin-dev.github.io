---
title: "Elasticsearch BlahBlah"
category: "search_engine"
---

## [ 21.07.30 ] 도커로 설치
1. elk 설치
```consle
$ git clone https://github.com/deviantony/docker-elk.git
$ cd docker-elk
```
default로 X-Pack 설정이 되어있는데 무료로 사용하려면 각 Elasticsearch, Kibana, Logstash 설정파일에서 X-Pack 비활성화한다. 
```console
$ vi docker-elk/elasticsearch/config/elasticsearch.yml
$ vi docker-elk/kibana/config/kibana.yml
$ vi docker-elk/logstash/config/logstash.yml
```
[ elasticsearch ]
```bash
#xpack.license.self_generated.type: trial
#xpack.security.enabled: true
#xpack.monitoring.collection.enabled: true
```
[ logstash ]
```bash
#xpack.monitoring.elasticsearch.hosts: [ "http://elasticsearch:9200" ]
#xpack.license.self_generated.type: trial
#xpack.security.enabled: true
#xpack.monitoring.collection.enabled: true
```
[ kibana ]
```bash
#monitoring.ui.container.elasticsearch.enabled: true

## X-Pack security credentials
#
#elasticsearch.username: elastic
#elasticsearch.password: changeme
```

2. elk 실행
docker-elk 디렉토리에서 아래와 같이 실행한다.
```console
$ docker-compose build 
$ docker-compose up -d
```

출처
- https://judo0179.tistory.com/60
- https://kkamagistory.tistory.com/771

### Elasticsearch 검색엔진으로서의 특성
일단은 비정형 데이터에 대한 색인이 가능하고, 고성능의 전문검색 지원이 가능하다는 점이 있다. ES는 Lucene을 기반으로 하는데 Lucene은 Inverted Index 구조를 갖고 있다. Inverted Index는 document를 단어들로 쪼개 각 단어에 대해 documents를 인덱싱한다. ES에서 형태소 분석기라 불리는 Analyzer를 통해 documents를 term으로 분리한다.

![](https://blog.lael.be/wp-content/uploads/2016/01/3107787182.png)

ES에서는 검색 프로세스가 단순히 Matching만을 의미하는 것이 아니다. 검색어와 documents의 relevancy를 평가하여 유사한 문서를 추출한다. 

또한, ES는 분산 관리 기능이 뛰어나다. 

## [ 21.07.30 ] Kibana configure
Kibana 서버는 `kibana.yml` 설정을 기반으로 한다. 
Elasticsearch 연동시키려면 config 에서 `elasticsearch.hosts` 접근하려는 Elasticsearch URLs 설정해야 한다.

출처 : https://www.elastic.co/guide/en/kibana/current/settings.html