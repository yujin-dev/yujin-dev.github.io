---
title: "PostgrSQL BlahBlah"
category: "db"
---
## [ 21.07.02 ] sub query 적용 비교
postgresql에서 필터를 적용한 쿼리를 실행할 때 서브 쿼리가 포함된 경우가 더 빠를까? 보통은 서브 쿼리가 들어가면 속도가 더 느려진다.  
아래 예시처럼 실제 시간 차이가 나는지 간단하게 확인해보았다. 현재 테이블 크기는 table1의 경우 약 4.2G로 다수의 `entity_id` 20년치 데이터가 들어있다.  
추가적으로 Query Plan을 함께 확인하여 쿼리 동작이 어떻게 이루어지는지 확인하였다.

[ 예시 ]
- table1, table2의 `entity_id`라는 칼럼을 기준으로 inner join
- 조인 대상을 서브쿼리로 적용하느냐에 따라 구분하여 실행

### join with sub query
```sql
SELECT base_date, table2.unique_id, agg_count FROM table1 
INNER JOIN ( select entity_id, unique_id from table2 
		  where entity_id in ('xxxx0', 'xxxx1', 'xxxx2', 'xxxx3', 'xxxx4', 'xxxx5', 'xxxx6', 'xxxx7', 'xxxx8', 'xxxx9', 'xxxx10', 'xxxx11', 'xxxx12', 'xxxx13', 'xxxx14', 'xxxx15', 'xxxx16', 'xxxx17', 'xxxx18', 'xxxx19', 'xxxx20', 'xxxx21', 'xxxx22', 'xxxx23', 'xxxx24', 'xxxx25', 'xxxx26', 'xxxx27', 'xxxx28', 'xxxx29', 'xxxx30', 'xxxx31', 'xxxx32', 'xxxx33', 'xxxx34', 'xxxx35', 'xxxx36', 'xxxx37', 'xxxx38', 'xxxx39', 'xxxx40', 'xxxx41', 'xxxx42', 'xxxx43', 'xxxx44', 'xxxx45', 'xxxx46', 'xxxx47', 'xxxx48', 'xxxx49', 'xxxx50', 'xxxx51', 'xxxx52', 'xxxx53', 'xxxx54') ) table2
ON table1.entity_id = table2.entity_id 

/*
"Gather  (cost=600025.39..792357.91 rows=1257562 width=22)"
"  Workers Planned: 2"
"  ->  Parallel Hash Join  (cost=599025.39..665601.71 rows=523984 width=22)"
"        Hash Cond: (table2.entity_id = table1.entity_id)"
"        ->  Parallel Seq Scan on table2  (cost=0.00..12118.46 rows=337 width=17)"
"              Filter: (entity_id = ANY ('{xxxx0, xxxx1, xxxx2, xxxx3, xxxx4, xxxx5, xxxx6, xxxx7, xxxx8, xxxx9, xxxx10, xxxx11, xxxx12, xxxx13, xxxx14, xxxx15, xxxx16, xxxx17, xxxx18, xxxx19, xxxx20, xxxx21, xxxx22, xxxx23, xxxx24, xxxx25, xxxx26, xxxx27, xxxx28, xxxx29, xxxx30, xxxx31, xxxx32, xxxx33, xxxx34, xxxx35, xxxx36, xxxx37, xxxx38, xxxx39, xxxx40, xxxx41, xxxx42, xxxx43, xxxx44, xxxx45, xxxx46, xxxx47, xxxx48, xxxx49, xxxx50, xxxx51, xxxx52, xxxx53, xxxx54}'::bpchar[]))"
"        ->  Parallel Hash  (cost=433834.17..433834.17 rows=8997617 width=19)"
*/
```
```
Successfully run. Total query runtime: 19 secs 638 msec.
1472265 rows affected.
```
### join without sub query
```sql
SELECT base_date, table2.unique_id, agg_count FROM table1 
INNER JOIN table2 
ON table1.entity_id = table2.entity_id 
 WHERE table1.entity_id in ('xxxx0', 'xxxx1', 'xxxx2', 'xxxx3', 'xxxx4', 'xxxx5', 'xxxx6', 'xxxx7', 'xxxx8', 'xxxx9', 'xxxx10', 'xxxx11', 'xxxx12', 'xxxx13', 'xxxx14', 'xxxx15', 'xxxx16', 'xxxx17', 'xxxx18', 'xxxx19', 'xxxx20', 'xxxx21', 'xxxx22', 'xxxx23', 'xxxx24', 'xxxx25', 'xxxx26', 'xxxx27', 'xxxx28', 'xxxx29', 'xxxx30', 'xxxx31', 'xxxx32', 'xxxx33', 'xxxx34', 'xxxx35', 'xxxx36', 'xxxx37', 'xxxx38', 'xxxx39', 'xxxx40', 'xxxx41', 'xxxx42', 'xxxx43', 'xxxx44', 'xxxx45', 'xxxx46', 'xxxx47', 'xxxx48', 'xxxx49', 'xxxx50', 'xxxx51', 'xxxx52', 'xxxx53', 'xxxx54')

/*
"Gather  (cost=6680.84..358967.87 rows=74263 width=22)"
"  Workers Planned: 6"
"  ->  Parallel Hash Join  (cost=5680.84..350541.57 rows=12377 width=22)"
"        Hash Cond: (table1.entity_id = table2.entity_id)"
"        ->  Parallel Index Scan using table1_pkey on table1  (cost=0.56..344723.63 rows=1565 width=19)"
"              Index Cond: ((base_date >= '2000-01-01 00:00:00'::timestamp without time zone) AND (base_date <= '2005-06-30 00:00:00'::timestamp without time zone))"
"              Filter: (entity_id = ANY ('{xxxx0, xxxx1, xxxx2, xxxx3, xxxx4, xxxx5, xxxx6, xxxx7, xxxx8, xxxx9, xxxx10, xxxx11, xxxx12, xxxx13, xxxx14, xxxx15, xxxx16, xxxx17, xxxx18, xxxx19, xxxx20, xxxx21, xxxx22, xxxx23, xxxx24, xxxx25, xxxx26, xxxx27, xxxx28, xxxx29, xxxx30, xxxx31, xxxx32, xxxx33, xxxx34, xxxx35, xxxx36, xxxx37, xxxx38, xxxx39, xxxx40, xxxx41, xxxx42, xxxx43, xxxx44, xxxx45, xxxx46, xxxx47, xxxx48, xxxx49, xxxx50, xxxx51, xxxx52, xxxx53, xxxx54}'::bpchar[]))"
"        ->  Parallel Hash  (cost=4249.57..4249.57 rows=114457 width=17)"
"              ->  Parallel Seq Scan on table2  (cost=0.00..4249.57 rows=114457 width=17)"
*/
```
```
Successfully run. Total query runtime: 12 secs 407 msec.
1472265 rows affected.
```

요약하면..
- sub query 없이 join하는게 더 빠름
- filter의 역할이 중요하게 작동함( 전체 entity_id 18377개인데 55개( 0.3% )에 해당하는 경우만 추출하도록 하여 Index Scan이 효과적으로 적용됨 )
- filter의 역할이 미미해질 경우( 전체 테이블에서 큰 비율로 데이터를 로드해야 하는 경우,..) Seq Scan이 적용될 것(Parallel Seq Scan 인 경우 프로세스를 여러 개 띄워 병렬로 쿼리를 수행하나 CPU 사용량이 급증할 수 있음)

결과적으로 왠만하면 서브 쿼리는 적용하지 않는게 나을 것 같다..!

## [ 21.07.05 ] NUMERIC data type
출처: https://www.geeksforgeeks.org/postgresql-numeric-data-type/

postgresql에서  `NUMERIC` type이 지원된다. syntax는 아래와 같다. 

```sql
NUMERIC(precision, scale)

/*
Precision: 전체 숫자 길이
Scale: fraction( 소숫점 )의 길이
*
```
예를 들어,

```sql
CREATE TABLE IF NOT EXISTS products (
    id serial PRIMARY KEY,
    name VARCHAR NOT NULL,
    price NUMERIC (5, 2)
);
```
테이블을 생성하면, 아래와 같은 데이터를 삽입할 때
```sql
INSERT INTO products (name, price)
VALUES
    ('Phone', 100.2157), 
    ('Tablet', 300.2149);
```
[ 결과 ]
```sql
id | name  | price
-------------------
 1 | Phone | 100.22
 2 | Table | 300.21
```
전체 길이 5에서 소숫점 2만큼만 반영된다.

---
## [ 21.07.05 ] inner join vs. pandas.merge(how='inner')
Postgresql 서버에서 inner join을 적용하는게 나을지, python에서 데이터를 메모리에 올려 `pandas.merge`로 적용하는게 나을지 실험해보았다. 데이터를 전구간으로 한번에 쿼리 요청하면 프로세스가 죽어있는 경우가 발생하여 연도별로 나눠서 받았다.

[ 21.07.14 추가 ]
결과를 정리하면, 
- 기존에 병합이 필요한 부분은 `pd.merge`를 적용하였는데 약 1~2 GB 데이터 받는데 대략 4060초 소요되었음. 
- `pd.merge` 대신 PostgreSQL에서 대신 쿼리로 작업을 수행하여 `inner join`을 적용하였는데 9172초로 대략 2배 더 발생했음. 


## [ 21.07.16 ] 도커로 설치
```console
$ sudo docker run -p 5432:5432 --name postgres -e POSTGRES_PASSWORD={password} -d postgres

enable to find image 'postgres:latest' locally
latest: Pulling from library/postgres
b4d181a07f80: Pull complete 
46ca1d02c28c: Pull complete 
a756866b5565: Pull complete 
36c49e539e90: Pull complete 
664019fbcaff: Pull complete 
727aeee9c480: Pull complete 
796589e6b223: Pull complete 
add1501eead6: Pull complete 
fdad1da42790: Pull complete 
8c60ea65a035: Pull complete 
ccdfdf5ee2b1: Pull complete 
a3e1e8e2882e: Pull complete 
a6032b436e45: Pull complete 
Digest: sha256:2b87b5bb55589540f598df6ec5855e5c15dd13628230a689d46492c1d433c4df
Status: Downloaded newer image for postgres:latest
3f80d6777eeb31ace20bab432fde8735c2681a8c362576e06ed32473a75e1c6d

$ sudo docer ps -a

CONTAINER ID   IMAGE      COMMAND                  CREATED              STATUS              PORTS                                       NAMES
3f80d6777eeb   postgres   "docker-entrypoint.s…"   About a minute ago   Up About a minute   0.0.0.0:5432->5432/tcp, :::5432->5432/tcp   postgres
```
컨테이너에 접속한다.
```console
$ docker exec -it postgres /bin/bash
```
접속하려는 서버 정보를 명시한다.
```console
root@3f80d6777eeb:/ psql -U postgres
root@3f80d6777eeb:/ psql -h {host_name} -p 5432 -U postgres -d {db_name} 
```

해당 컨테이너를 다시 시작하려면
```console
$ docker run postgres 
```

## [ 21.07.16 ] 성능 분석 - pgbench
pgbench는 PostgreSQL에서 제공하는 Benchmark 툴이다. `SELECT`, `INSERT`, `UPDATE` 등 명령어를 조합해서 시뮬레이션하고 이를 초당 Transaction 횟수로 성능을 평가한다.
서버가 설치된 하드웨어 및 OS 환경에서 성능을 측정하며 postgresql.conf의 환경 변수 설정에 사용될 수 있다.

### pgbench 사용
1. 성능 측정을 위한 임시 DB 인스턴스 생성 : 임시 Table을 쉽게 정리하기 위해 DB instance를 생성한다.
```console
$ psql -h {host} -U postgres postgres
$ CREATE DATABASE pgbenchtest OWNER postgres;
$ pgbenchtest postgres
```
2. DB instance `pgbenchtest`에 테이블 생성
```console 
$ pgbench -h {host} -p 5432 -U postgres -i pgbenchtest
```

접속하여 `\dt`로 실행하면 생성된 테이블을 확인할 수 있다.
테이블 크기를 키우려면 `-s`로 tuple수를 배수만큼 늘린다. 아래의 경우 10배만큼 증가한다.
```console
$ pgbench -h {host} -p 5432 -U postgres -i -s 10 pgbenchtest
```
3. 성능 테스트
벤치마킹 옵션을 적용하여 성능 테스트를 진행한다. 대표적으로
- `-c`: DB에 접속하는 가상의 client수
- `-j`: client를 thread 몇 개로 동작할 것인지(`-c`에서 설정한 값 이상이어야 함)
- `-t`: 시뮬레이션할 transaction 수

8개의 client, 각 client가 10회의 transaction을 수행할 때(4개의 thread로 분산)
```console
$ pgbench -h {host} -p 5432 -U postgres -c 8 -j 4 -t 10 pgbenchtest
```

튜닝 시에 postgresql.conf 인자 변경 및 pgbench 수행을 반복해야 하는 번거로움이 있다. 여러 변수를 테스트하려면 테스트할 시나리오로 자동화 테스트를 진행해야 할 것 같다.

#### 참고: https://browndwarf.tistory.com/52

## [ 21.07.23 ] Lock 파악하기
스크랩 : https://medium.com/29cm/db-postgresql-lock-%ED%8C%8C%ED%97%A4%EC%B9%98%EA%B8%B0-57d37ebe057

## [ 21.07.23 ] Connection Pool deadlock 현상

PostgreSQL 서버의 최대 connection 갯수는 크게 설정되지 않고 client에서 무거운 transaction으로 인한 *connection pool deadlock*이 발생하기 쉽다. 
초창기에 무거운 transaction으로 인해 pool에 deadlock이 걸려 서비스 장애가 일어날 수 있다. pool size를 늘리고 무거운 transaction은 한번에 처리할 수 있도록 최대 갯수를 늘려 deadlock을 방지할 수 있으나 서비스 응답시간과 connection 사용량에 문제가 생긴다. 

해결 방안 제시 : https://medium.com/@hyeonjay.kim/postgresql-%EC%B4%88%EB%B3%B4%EB%A5%BC-%EC%9C%84%ED%95%9C-%EA%B0%80%EC%9D%B4%EB%93%9C-%EC%BF%BC%EB%A6%AC-%EC%BB%A4%EB%84%A5%EC%85%98-%ED%92%80-%EA%B7%B8%EB%A6%AC%EA%B3%A0-%EC%84%9C%EB%B9%84%EC%8A%A4-%EC%9D%91%EB%8B%B5%EC%8B%9C%EA%B0%84-%EC%B5%9C%EC%A0%81%ED%99%94%ED%95%98%EA%B8%B0-917352a2a19a

#### 참고 
- https://sondahum.tistory.com/21  
- https://blog.lael.be/post/3056
