---
title: "Udemy Elasticsearch - Managing Documents"
category: "search_engine"
---
Elasticsearch Udemy 강의( *Complete Guide to Elastticsearch* )를 보면서 Managing documents 파트를 정리한다.
예시는 [CodeExplained](https://github.com/codingexplained/complete-guide-to-elasticsearch/tree/master/Managing%20Documents)를 참고한다. 

## Create indices
```sh
PUT /products
{
  "settings": {
    "number_of_shards": 2,
    "number_of_replicas": 2
  }
}
```
>>>
```sh
{
  "acknowledged" : true,
  "shards_acknowledged" : true,
  "index" : "products"
}
```
## Indexing documents
ID를 따로 설정하지 않으면 자동으로 설정된다. 
```sh
POST /products/_doc 
{
  "name": "Coffee Maker",
  "price": 64,
  "in_stock": 10
}
```
```sh
{
  "_index" : "products", 
  "_type" : "_doc",
  "_id" : "wqTxH3sBlg1v6FdkiUBO", 
  "_version" : 1,
  "result" : "created",
  "_shards" : {
    "total" : 3,
    "successful" : 2,
    "failed" : 0
  },
  "_seq_no" : 0,
  "_primary_term" : 1
}
```
ID를 직접 설정할 수 있다.
```sh
PUT /products/_doc/100
{
  "name": "Toaster",
  "price": 49,
  "in_stock": 4
}
```
```sh
{
  "_index" : "products",
  "_type" : "_doc",
  "_id" : "100",
  "_version" : 1,
  "result" : "created",
  "_shards" : {
    "total" : 3,
    "successful" : 2,
    "failed" : 0
  },
  "_seq_no" : 0,
  "_primary_term" : 1
}
```
## Retrieving documents
`products` index의 `ID=100`인 documents를 불러온다. 
```sh
GET /products/_doc/100
```
```sh
{
  "_index" : "products",
  "_type" : "_doc",
  "_id" : "100",
  "_version" : 1,
  "_seq_no" : 0,
  "_primary_term" : 1,
  "found" : true,
  "_source" : {
    "name" : "Toaster",
    "price" : 49,
    "in_stock" : 4
  }
}
```

## Updating documents
`products` index에서 `ID=100` documents 값을 변경한다. 해당 document 값을 변경할 때마다 `version`값이 하나씩 증가하게 된다.

```sh
POST /products/_update/100
{
  "doc": {
    "in_stock": 3
  }
}
```
```sh
{
  "_index" : "products",
  "_type" : "_doc",
  "_id" : "100",
  "_version" : 2,
  "result" : "updated",
  "_shards" : {
    "total" : 3,
    "successful" : 2,
    "failed" : 0
  },
  "_seq_no" : 1, 
  "_primary_term" : 1
}
```

### Scripted updates
- `products` index의 `ID=100` documents의 `in_stock` 값을 하나 줄인다. 
```sh
POST /products/_update/100
{
  "script": {
    "source": "ctx._source.in_stock--"
  }
}
```
```sh
{
  "_index" : "products",
  "_type" : "_doc",
  "_id" : "100",
  "_version" : 3,
  "result" : "updated",
  "_shards" : {
    "total" : 3,
    "successful" : 2,
    "failed" : 0
  },
  "_seq_no" : 2, 
  "_primary_term" : 1
}
```
- `products` index의 `ID=100` documents의 `in_stock` 값을 임의로 설정한다. 
```sh
POST /products/_update/100
{
  "script": {
    "source" :"ctx._source.in_stock=10"
  }
}
```
- parameter를 설정해서 값을 변경할 수도 있다.
```sh
POST /products/_update/100
{
  "script": {
    "source" :"ctx._source.in_stock -= params.quantity",
    "params": {
      "quantity":4
    }
  }
}
```
- 조건에 따라 값을 `noop`으로 설정한다.
```sh
POST /products/_update/100
{
  "script": {
    "source" : """
    if (ctx._source.in_stock == 0) {
      ctx.op = 'noop';
    }
    ctx._source.in_stock--;
    """
  }
}
```
- 조건에 따라 값을 변경한다.
```sh
POST /products/_update/100
{
  "script": {
    "source": """
      if (ctx._source.in_stock > 0) {
        ctx._source.in_stock--;
      }
    """
    }
  }
```

`GET /products/_doc/100` 으로 마지막 결과를 확인하면
```sh
{
  "_index" : "products",
  "_type" : "_doc",
  "_id" : "100",
  "_version" : 7,
  "_seq_no" : 6,
  "_primary_term" : 1,
  "found" : true,
  "_source" : {
    "name" : "Toaster",
    "price" : 49,
    "in_stock" : 4
  }
}
```
- 조건에 따라 `delete`
```sh
POST /products/_update/100
{
  "script": {
    "source": """
      if (ctx._source.in_stock < 0) {
        ctx.op = 'delete';
      }
      ctx._source.in_stock--;
    """
  }
}
```

## Upserts
```sh
POST /products/_update/101
{
  "script": {
    "source": "ctx._source.in_stock+"
  },
  "upsert": {
    "name": "Blender",
    "price": 399,
    "in_stock": 5
  }
}
```
```sh
{
  "_index" : "products",
  "_type" : "_doc",
  "_id" : "101",
  "_version" : 1,
  "result" : "created",
  "_shards" : {
    "total" : 3,
    "successful" : 2,
    "failed" : 0
  },
  "_seq_no" : 8,
  "_primary_term" : 1
}

```

## Replacing documents
```sh
PUT /products/_doc/100
{
  "name": "Toaster",
  "price": 79,
  "in_stock": 4
}
```
```sh
{
  "_index" : "products",
  "_type" : "_doc",
  "_id" : "100",
  "_version" : 9,
  "result" : "updated",
  "_shards" : {
    "total" : 3,
    "successful" : 2,
    "failed" : 0
  },
  "_seq_no" : 9,
  "_primary_term" : 1
}
```
`GET`으로 데이터를 확인하면 `PUT`의 내용과 동일한 결과가 반환된다.

## Deleting documents
```sh
DELETE /products/_doc/101
```
```sh
{
  "_index" : "products",
  "_type" : "_doc",
  "_id" : "101",
  "_version" : 2,
  "result" : "deleted",
  "_shards" : {
    "total" : 3,
    "successful" : 2,
    "failed" : 0
  },
  "_seq_no" : 10,
  "_primary_term" : 1
}
```
`GET`으로 데이터를 확인하면 
```sh
{
  "_index" : "products",
  "_type" : "_doc",
  "_id" : "101",
  "found" : false
}
``` 
로 `found=false`로 반환된다.

## Update by query
- 쿼리와 매칭되는 documents를 변경한다.
```sh
POST /products/_update_by_query
{
  "script": {
    "source": "ctx._source.in_stock--"
  },
  "query": {
    "match_all": {}
  }
}
```
```sh
{
  "took" : 84,
  "timed_out" : false,
  "total" : 2,
  "updated" : 2,
  "deleted" : 0,
  "batches" : 1,
  "version_conflicts" : 0,
  "noops" : 0,
  "retries" : {
    "bulk" : 0,
    "search" : 0
  },
  "throttled_millis" : 0,
  "requests_per_second" : -1.0,
  "throttled_until_millis" : 0,
  "failures" : [ ]
}
```
- version conflicts를 무시하도록 설정한다.
```sh
POST /products/_update_by_query
{
  "conflicts": "proceed",
  "script": {
    "source": "ctx._source.in_stock--"
  },
  "query": {
    "match_all": {}
  }
}
```
전체 결과를 확인하면
```sh
GET /products/_search
{
  "query": {
    "match_all": {}
  }
}
```
```sh
{
  "took" : 888,
  "timed_out" : false,
  "_shards" : {
    "total" : 2,
    "successful" : 2,
    "skipped" : 0,
    "failed" : 0
  },
  "hits" : {
    "total" : {
      "value" : 2,
      "relation" : "eq"
    },
    "max_score" : 1.0,
    "hits" : [
      {
        "_index" : "products",
        "_type" : "_doc",
        "_id" : "100",
        "_score" : 1.0,
        "_source" : {
          "price" : 79,
          "name" : "Toaster",
          "in_stock" : 2
        }
      },
      {
        "_index" : "products",
        "_type" : "_doc",
        "_id" : "wqTxH3sBlg1v6FdkiUBO",
        "_score" : 1.0,
        "_source" : {
          "price" : 64,
          "name" : "Coffee Maker",
          "in_stock" : 8
        }
      }
    ]
  }
}
```
데이터가 총 2개이고 각 `in_stock`의 값이 변경되었음을 알 수 있다.

## Delete by query
```sh
POST /products/_delete_by_query
{
  "query": {
    "match_all":{}
  }
}
```
```sh
{
  "took" : 30,
  "timed_out" : false,
  "total" : 2,
  "deleted" : 2,
  "batches" : 1, 
  "version_conflicts" : 0,
  "noops" : 0,
  "retries" : {
    "bulk" : 0,
    "search" : 0
  },
  "throttled_millis" : 0,
  "requests_per_second" : -1.0,
  "throttled_until_millis" : 0,
  "failures" : [ ]
}
```
## Batch processing
bulk 데이터를 처리할 때 사용하는 API가 있다.
### Indexing
```sh
POST /_bulk
{ "index": { "_index": "products", "_id": 200 } }
{ "name": "Espresso Machine", "price": 199, "in_stock": 5 }
{ "create": { "_index": "products", "_id": 201 } }
{ "name": "Milk Frother", "price": 149, "in_stock": 14 }
```
전체 데이터를 출력하면 아래와 같이 확인할 수 있다.
```sh
{
  "took" : 0,
  "timed_out" : false,
  "_shards" : {
    "total" : 1,
    "successful" : 1,
    "skipped" : 0,
    "failed" : 0
  },
  "hits" : {
    "total" : {
      "value" : 2,
      "relation" : "eq"
    },
    "max_score" : 1.0,
    "hits" : [
      {
        "_index" : "products",
        "_type" : "_doc",
        "_id" : "200",
        "_score" : 1.0,
        "_source" : {
          "name" : "Espresso Machine",
          "price" : 199,
          "in_stock" : 5
        }
      },
      {
        "_index" : "products",
        "_type" : "_doc",
        "_id" : "201",
        "_score" : 1.0,
        "_source" : {
          "name" : "Milk Frother",
          "price" : 149,
          "in_stock" : 14
        }
      }
    ]
  }
}
```
### Update & Delete
```sh
POST /_bulk
{"update": {"_index": "products", "_id": 201}}
{"doc": {"price": 129}} 
{"delete": {"_index": "products", "_id": 200}}
```
```sh
{
  "took" : 7,
  "errors" : false,
  "items" : [
    {
      "update" : {
        "_index" : "products",
        "_type" : "_doc",
        "_id" : "201",
        "_version" : 2,
        "result" : "updated",
        "_shards" : {
          "total" : 2,
          "successful" : 2,
          "failed" : 0
        },
        "_seq_no" : 2,
        "_primary_term" : 1,
        "status" : 200
      }
    },
    {
      "delete" : {
        "_index" : "products",
        "_type" : "_doc",
        "_id" : "200",
        "_version" : 2,
        "result" : "deleted",
        "_shards" : {
          "total" : 2,
          "successful" : 2,
          "failed" : 0
        },
        "_seq_no" : 3,
        "_primary_term" : 1,
        "status" : 200
      }
    }
  ]
}
```
마찬가지로 데이터를 확인하여 요청이 제대로 동작하였는지 알 수 있다.
```sh
{
  "took" : 62,
  "timed_out" : false,
  "_shards" : {
    "total" : 1,
    "successful" : 1,
    "skipped" : 0,
    "failed" : 0
  },
  "hits" : {
    "total" : {
      "value" : 1,
      "relation" : "eq"
    },
    "max_score" : 1.0,
    "hits" : [
      {
        "_index" : "products",
        "_type" : "_doc",
        "_id" : "201",
        "_score" : 1.0,
        "_source" : {
          "name" : "Milk Frother",
          "price" : 129,
          "in_stock" : 14
        }
      }
    ]
  }
}
```

## Importing data with cURL
```console
$ curl -H "Content-Type: application/x-ndjson" -XPOST http://localhost:9200/products/_bulk --data-binary "@products-bulk.json"
```
