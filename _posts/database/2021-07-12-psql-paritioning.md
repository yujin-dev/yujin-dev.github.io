---
title: "Postgresql documentation 살펴보기 - Partitioning"
category: "db"
---

Partitioning은 하나의 테이블을 여러 개의 physical 조각으로 분할시키는 것을 의미한다. Partitioning을 통해 얻을 수 있는 이점은
- 쿼리가 single partition이나 적은 수의 partition에 접근하는 경우 indexes의 상위 레벨을 효율적으로 대체하여 성능이 향상된다. 
- 쿼리가 single partition의 많은 부분에 접근하는 경우 index scan 대신 seq scan으로 성능이 개선될 수 있다. 
- Bulk loads, deletes는 partition을 추가하거나 제거하여 가능하다. 

(그럼 많은 partition을 접근하는 경우는 쿼리 성능 효과가 없는건가..?)
위의 이점은 테이블 크기가 많이 클 경우에만 해당된다. 

## Declarative Partitioning

### Creating Partition
Partitioning 방식은 아래와 같이 있다.
- Range Partitioning : column으로 구성되는 ranges에 따라 partition 분할
- List Partitioning : key value(s)에 따라 partition 분할
- Hash Partitioning : modulus, remainder에 따라 partition 분할

분할된 table은 *partitioned table*이라 칭한다. declaration은 *partitioning method*와 *partition key*를 포함한다. 각각의 partition은 *partition bounds*라는 데이터 부분을 저장하고 있다. partition key column(s)에 따라 모든 rows는 partitions 중 하나에 route된다. 모든 partition은 동일한 칼럼을 가지나, partition마다 고유의 indexes, constraints, default 값을 가질 수 있다. 

[ 예시 ]
```sql
CREATE TABLE measurement (
    city_id         int not null,
    logdate         date not null,
    peaktemp        int,
    unitsales       int
);
```

대부분의 쿼리는 지난 주, 지난 달, 지난 분기를 접근한다고 가정하여 최근 3년치만 저장하기로 한다. 
declarative partitiong은 다음 단계에 따라 실행된다.
1. partitioned table을 생성한다. partition 정의는 특정 partitioning method & partitioning key로 bounds를 구성한다. 예시에서는 `measurement` 테이블로 partitioning method는 `RANGE`를, partition key로 `logdate`를 설정하였다.
```sql
CREATE TABLE measurement (
    city_id         int not null,
    logdate         date not null,
    peaktemp        int,
    unitsales       int
) PARTITION BY RANGE (logdate);
```
2. partition은 생성한다. 각각의 partition은 bounds와 함께 정의해준다. 개별 partition은 tablespace나 parameters를 명시할 수 있다.
```sql
CREATE TABLE measurement_y2006m02 PARTITION OF measurement
    FOR VALUES FROM ('2006-02-01') TO ('2006-03-01');

CREATE TABLE measurement_y2006m03 PARTITION OF measurement
    FOR VALUES FROM ('2006-03-01') TO ('2006-04-01');

...
CREATE TABLE measurement_y2007m11 PARTITION OF measurement
    FOR VALUES FROM ('2007-11-01') TO ('2007-12-01');

CREATE TABLE measurement_y2007m12 PARTITION OF measurement
    FOR VALUES FROM ('2007-12-01') TO ('2008-01-01')
    TABLESPACE fasttablespace;

CREATE TABLE measurement_y2008m01 PARTITION OF measurement
    FOR VALUES FROM ('2008-01-01') TO ('2008-02-01')
    WITH (parallel_workers = 4)
    TABLESPACE fasttablespace;
```
3. key column(s)에 index를 생성한다. partitioned table(`measurement`)에 정의된 index는 가상의 것으로 실제 데이터는 partition table에 존재한다.
```sql
CREATE INDEX ON measurement(logdate);
```

위의 결과, 각 월에 해당하는 새로운 partition을 생성된다. 

### Partition Maintenance
paritions를 제거하거나 새로운 partition을 추가하는 경우가 있다. 

#### partition 제거
```sql
DROP TABLE measurement_y2006m02;
```
partition 제거하는 경우 parent table에 `ACCESS EXCLUSIVE` lock이 걸려있어야 한다. 

#### partition 추가
```sql
CREATE TABLE measurement_y2008m02 PARTITION OF measurement
    FOR VALUES FROM ('2008-02-01') TO ('2008-03-01')
    TABLESPACE fasttablespace; 
```
empty partition을 생성할 수 있다. 

```sql
CREATE TABLE measurement_y2008m02
    (LIKE measurement INCLUDING DEFAULTS INCLUDING CONSTRAINTS)
    TABLESPACE fasttablespace; 

ALTER TABLE measurement_y2008m02 ADD CONSTRAINT y2008m02
    CHECK ( logdate >= DATE '2008-02-01' AND logdate < DATE '2008-03-01');

\copy measurement_y2008m02 from 'measurement_y2008m02'
-- ...

ALTER TABLE measurement ATTACH PARTITION measurement_y2008m02
    FOR VALUES FROM ('2008-02-01') TO ('2008-03-01');
```
`ATTACH PARTITION`을 실행하기 전에 `CHECK` constraint를 생성하여 partition constraint를 검증하는 작업이 필요하다. 

추가 : https://www.postgresql.org/docs/current/ddl-partitioning.html#DDL-PARTITIONING-DECLARATIVE

### Partitioning Using Inheritance
Partitioning은 때로 table inheritance로 실행되기도 하는데    