---
title: "Postgresql documentation 살펴보기 - Text Search "
category: "db"
---

## Introduction
Text Search는 쿼리와 연관되는 자연어로 구성된 documents를 탐색하는 기능이다. 보통 쿼리에서 찾는 용어를 포함하는 모든 문서를 찾아 쿼리와 *유사한* 순서대로 추출한다. 간단하게 보면 *쿼리*는 단어들의 묶음이고 *유사도*는 문서에서 단어의 빈도를 의미한다.

정규표현식의 `LIKE` 등 Text Search는 이미 기존에 있었지만 몇 가지 중요한 부분이 빠져있었다.
- 영어에 대한 언어적 지원이 없다. 정규표현식은 만족한다(`satisfy`)라는 의미를 충족하지 못해 문서 검색으로서는 부족한 감이 있다.
- 검색 결과에 대한 순서(`ranking`)이 없다. 
- index가 지원되지 않으므로 모든 문서를 탐색하여 시간 효율성이 떨어진다.

Full Text indexing은 문서를 *전처리*하여 이후의 searching에서 index가 활용된다. 전처리는 아래와 같다.
- 문서를 tokens으로 *Parsing*한다. 여러 종류의 tokens으로 식별하여 각각 다른 전처리 방식을 적용할 수 있다. 
- tokens을 lexemes(어휘)으로 *Converting*한다. lexemes는 tokens와 마찬가지로 문자이지만 normalized된 형식이다. *normalization*는 suffixes를 제거하거나 대문자를 소문자로 바꾸는 작업을 의미한다. 또한 검색에는 의미없는 문자인 `stop words`를 제거하여 indexing, searching이 효율적으로 이루어지도록 한다. 
- searching에 최적화된 전처리된 문서를 *Storing*한다. 예를 들어 각 문서는 normalized lexemes의 정렬된 array로 표현될 수 있다. 이 때 *proximity ranking*에 적합하게 사용되도록 저장할 수 있다.

```sql
SELECT title || ' ' || author || ' ' || abstract || ' ' || body AS document 
FROM messages
WHERE mid = 12;

SELECT m.title || ' ' || m.author || ' ' || m.abstract || ' ' || d.body AS document 
FROM messages m, docs d
WHERE m.mid = d.did AND m.mid = 12;
```

text 검색을 위해서는 모든 문서는 전처리된 `tsvector`형식이어야 한다. 

### Basic Text Matching
Full Text Searching은 match 연산자인 `@@`를 기반으로 한다. `@@`는 `tsvector`(document)가 `tsquery`(query)와 일치하면 `t`(true)를 반환한다.

```sql
SELECT 'a fat cat sat on a mat and ate a fat rat'::tsvector @@ 'cat & rat'::tsquery;
/*
 ?column?
----------
 t
 */
SELECT 'fat & cow'::tsquery @@ 'a fat cat sat on a mat and ate a fat rat'::tsvector;
/*
 ?column?
----------
 t
 */
 ```
`tsquery`는 검색하려는 용어(normalized 단어로 AND(`&`), OR(`|`), NOT(`!`), FOLLOWED BY(`<->`) 연산자 사용 가능)를 포함한다. `to_tsquery`는 쿼리에서 단어를 normalize를 적용해주고 `to_tsvector`는 문서의 parse 및 normalize를 도와준다. 

```sql
SELECT to_tsvector('fat cats ate fat rats') @@ to_tsquery('fat & rat');
/*
 ?column? 
----------
 t
 */
-- 아래는 wrong example
SELECT 'fat cats ate fat rats'::tsvector @@ to_tsquery('fat & rat');
/*
 ?column? 
----------
 f
*/
```

`tsquery`는 `<->`( FOLLOWED BY )는 앞 문자 뒤에 뒤 문자가 오는지를 확인한다.
```sql
SELECT to_tsvector('fatal error') @@ to_tsquery('fatal <-> error');
/*
 ?column? 
----------
 t
*/
SELECT to_tsvector('error is not fatal') @@ to_tsquery('fatal <-> error');
/*
 ?column? 
----------
 f
*/
```

`phraseto_tsquery`는 `stop words`를 고려하여 `<->`( FOLLOWED BY ) 포함하여 변환해준다.
```sql
SELECT phraseto_tsquery('cats ate rats');
/*
       phraseto_tsquery        
-------------------------------
 'cat' <-> 'ate' <-> 'rat'
*/
SELECT phraseto_tsquery('the cats ate the rats');
/*
       phraseto_tsquery        
-------------------------------
 'cat' <-> 'ate' <2> 'rat'
 */
 ```

 ## Tables and Indexes

 ### Searching a Table
 index없이 text 검색이 가능하다.

`body` field에 `friend`가 있으면 `title` field를 출력하는 쿼리는 아래와 같다.
```sql
SELECT title
FROM pgweb
WHERE to_tsvector('english'. body) @@ to_tsquery('english', 'frield');
```

여기서는 `friends`, `friendly`등 연관된 단어도 찾아준다. configuration 변수(`'english'`) 는 생략 가능하다.

### Creating Indexes
GIN Index를 생성하면 검색 속도를 높일 수 있다.

```sql
CREATE INDEX pgweb_idx ON pgweb USING GIN(to_tsvector('english', body));
```

configuration 이름을 명시하는 text 검색 함수가 indexes 생성에 이용될 수 있다. 이는 index는 `default_text_search_config`(https://www.postgresql.org/docs/current/runtime-config-client.html#GUC-DEFAULT-TEXT-SEARCH-CONFIG)에 영향을 받으면 안되기 때문이다. 서로 다른 text search configuration으로 생성된 `tsvector`가 포함된 내용은 index가 일관적이지 않아 부정확해질 수 있다. 

즉, `WHERE to_tsvector('english', body) @@ 'a & b'`는 되지만 `WHERE to_tsvector(body) @@ 'a & b'`는 index를 생성할 수 없다.

configuration 이름을 테이블의 칼럼으로도 사용 가능하다.
```sql
CREATE INDEX pgweb_idx ON pgweb USING GIN (to_tsvector(config_name, body));
```
위에서 `config name`은 `pgweb`의 칼럼으로 문서가 서로 다른 언어를 포함한 경우 유용하게 쓰일 수 있다.

또한 칼럼을 concat해서 indexes로 생성할 수 있다.
```sql
CREATE INDEX pgweb_idx ON pgweb USING GIN (to_tsvector('english', title || ' ' || body));
```
