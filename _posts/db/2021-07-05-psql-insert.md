---
title: "Postgresql 빠르게 삽입하기(WIP)"
category: "db"
---
지난 6월, 사내에서 새로운 데이터를 사용할 일이 생겨 DB에 데이터를 적재하였다. 데이터는 약 76833개 기업의 20년치 대체 데이터로 용량은 대략 300GB 정도인 것 같다.  
빅데이터라고 하기엔 용량이 애매하다만 자칫 삽입하는데 꽤 시간을 잡아먹을 것 같아 빠르게 삽입할 수 있는 방법을 알아보았다.
데이터는 기본적으로 하루 단위로 csv파일로 저장되어 있고, 파이썬으로 Postgresql에 로드할 계획이었다.

일단 Postgresql에서 데이터를 삽입하는데
- 기본적인 `INSERT TABLE_NAME(column1, column2, ..) VALUES(xx, xx, ..)` 쿼리 실행 : single row단위로 실행되기에 시간이 오래 소요됨
- `ARRAY` 형식으로 보다 빠르게 삽입할 수 있는 `UNNEST ..` : 각 칼럼별 데이터를 리스트로 추출하여 `UNNEST`로 `ARRAY` 형식으로 변환해 삽입하는데 훨씬 빨라짐
- 파일 자체를 StringByte로 출력하는 과정을 `COPY`하는 방식
- `PG BULK` 
등이 있다고 본다. 사실 더 다양한 방법이 있겠지만 일단은 위 경우들을 시도해보았다. 
아래 단계로 갈수록 데이터를 보다 빠르게 `INSERT`할 수 있는 것으로 안다. 

여기서 파이썬으로 스크립트를 짜서 실행하려는데 마지막 PG BULK는 python sql library에서 연동되는 기능을 찾지 못해 위 3가지 방법에 대해 구현하여 실험해보고자 한다. 
Task는 <데이터 자체는 csv 파일로 존재하고 이를 DB에 적재한다> 이다.

파이썬으로 Postgresql DB에 접속하기 위해 아래와 같이 SQL 연동 python 라이브러리를 활용하였다. 
먼저, `psycogp2`를 통해 접속하려는 DB 정보로 연결을 생성한다.
```python
import psycopg2
conn = psycopg2.connect(db_address)
```

데이터는 csv 파일로 저장되어 pandas.to_csv로 읽어와 메모리에 올리기로 한다. 데이터를 살펴보면
```python
import pandas as pd
data = pd.read_csv(csv_file)
```
[ 표 ]
- 용량

참고: https://www.dataquest.io/blog/loading-data-into-postgres/

### `INSERT TABLE_NAME(column1, column2, ..) VALUES(xx, xx, ..)` - Single 
```python
query = "INSERT TABLE_NAME(column1, column2, ..) VALUES(xx, xx, ..)"
psycopg2.execute(query)
```
- 시간
여러 row를 삽입할 때마다 commit이 발생하여 오버헤드가 비교적 크게 발생한다. 속도를 다소 늘리고 싶다면 DB의 설정을 변경해줘야 하는데 `autocommit=False`로 설정하여
매 row마다 commit되지 않아도 모든 row를 거친 후 마지막에 한번에 commit을 시켜준다.

### `INSERT TABLE_NAME(column1, column2, ..) VALUES(xx, xx, ..)` - 
```python
query = "INSERT TABLE_NAME(column1, column2, ..) VALUES(xx, xx, ..)"
psycopg2.executemany(query)
```

### `UNNEST`
UNNEST 는 ARRAY로 변환시켜주는 기능을 한다. 우선 pandas DataFrame 형식의 데이터를 각 칼럼별 값을 리스트로 묶어 전체 dictionary로 변환해준다.
```python
df = data.to_dict('list') 
```
특히 `timestamp_utc`인 컬럼은 DB에 저장힐시 `TIMESTAMP` 타입이 되도록 함께 명시해준다.각 칼럼별 list 데이터를 칼럼 정보와 UNNEST로 wrapping하여 DB에 삽입하도록 한다.
```python
is_time = lambda x: "::date[]" if table_info[table_info["column"]==x]["data_type"].iloc[0] == "TIMESTAMP" else ""
value = [f"unnest(ARRAY{df[col]}){is_time(col)}" for col in table_info['column']]
sql = f"INSERT INTO {table_name}({columns}) SELECT {','.join(value)}"
```
- 시간


### `COPY FROM`

여기서는 약간의(?) 많은 시행착오가 있었다. 일단 `copy .. from ..`은 구분자로 데이터를 SPLIT하여 읽어 삽입하는데 데이터 자체에 구분자가 포함되는 경우가 있었다.
구분자는 1BYTE이어야 하는 조건이 있었고 이를 만족하는 문자열은 데이터의 텍스트 칼럼에 이미 존재하였다. 여기서 parse를 제대로 적용해줘야 한다.

아래 `COPY..FROM...`을 실행하기에 앞서 dataframe을 StringBYte로 변환해주는데 삽입하려는 테이블의 정보와 정확히 일치해야 한다. 
테이블의 각 칼럼 순서와 Type이 DataFrame의 칼럼 순서 및 dtype이 동일해야 삽입될 수 있다.
기존의 `INSERT`보다 유연성이 다소 떨어지나 한번에 command 실행으로 많은 row를 삽입하고 commit을 한번만 발생시켜 오버헤드도 적다. 
따라서 단일 트랜젝션에서는 가장 빠른 방법으로 사용될 수 있다. 
```python
sio = StringIO()
sio.write(data.to_csv(header=False, index=False, sep=sep, quoting=csv.QUOTE_NONNUMERIC))
sio.seek(0)
```

```python
cursor.copy_expert(f"COPY {table_name} FROM STDIN WITH ( DELIMITER ',', FORMAT CSV, FORCE_NULL ({','.join(columns)}));", dt)
```
위에서 `FORCE_NULL` 을 통해 명시된 칼럼에 대해 NULL도 값으로 포함하여 데이터를 삽입함을 의미한다. 기존 테이블에서 NULL 허용을 Y로 설정해줘도 `FORCE_NULL`을 허용함을 명시하지 않으면 오류를 발생하여 해당 트랜잭션을 처리하지 않는다. 
- 시간

### 결과 비교