---
title: "Udemy Elasticsearch - Query DSL"
category: "search_engine"
---
Elasticsearch Udemy 강의( *Complete Guide to Elastticsearch* )를 보면서 [document](https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html)에서 Query DSL 관련 내용을 정리한다. 

Elasticsearch는 쿼리 정의에서 full Query DSL을 제공한다.Query DSL은 두 가지 유형의 clauses로 구성된다.
![](https://miro.medium.com/max/960/1*B2CWVPrA2EwqANIU13xe5w.png)

- Leaf query clauses : field의 특정 값을 찾기 위한 절인데 `match`, `term`, `range` 쿼리가 있다.
- Compound query clauses : 다른 leaf나 compound 쿼리를 결합하기 위한 쿼리문이다.

query clauses는 Query context, Filter context에 따라 다르게 적용된다. 
## Query / Filter context
https://www.elastic.co/guide/en/elasticsearch/reference/current/query-filter-context.html

### Query context
query context에서 *해당 document가 쿼리문과 얼마나 일치*되는가에 초점을 맞춰 쿼리가 동작한다. document를 검색하는데 inverted index에 적용한 analysis가 동일하게 적용되어 normalize된다. 예를 들어 'Lobster'를 검색하며 소문자로 변환되어 'lobster' 단어로 inverted index에서 검색하게 된다. 
```sh 
GET /products/_search
{
  "query": {
    "match": {
      "name": "Lobster"
    }
  }
}
```

### Filter context
filter context에서는 쿼리문은 *해당 문서가 쿼리문과 일치하는*에 대한 답을 찾는 쿼리로 동작한다. 답은 boolean으로 True / False로, score를 계산하지 않는다. 
또한, 자주 사용되는 필터는 자동으로 elasticseach에 캐싱된다. 예를 들어, 'Lobster'로 검색하는 경우 analysis를 거치지 않으므로 정확히 일치하는 경우만 결과를 반환한다. 따라서 'Lobster' / 'lobster'로 요청하느냐 따라 결과가 달라진다. 
```sh
GET /products/_search
{
  "query": {
    "term": {
      "name": "Lobster"
    }
  }
}
```

### Query context & Filter context 
**search** API에서 query context와 filter context를 사용하는 예시로,
- `title` : "Search"와 동일한 의미의 단어를 포함
- `context`: "Elasticsearch"와 동일한 의미의 단어를 포함
- `status`: "published"와 일치하는 단어를 포함
- `publish_date`: "2015-01-01" 이상인 날짜를 포함

```sh
GET /_search
{
  "query": {  # query context
    "bool": { 
      "must": [
        { "match": { "title":   "Search"        }}, # >> query context
        { "match": { "content": "Elasticsearch" }} # >> query context
      ],
      "filter": [ # filter context
        { "term":  { "status": "published" }}, # >> filter context
        { "range": { "publish_date": { "gte": "2015-01-01" }}} # >> filter context
      ]
    }
  }
}
```