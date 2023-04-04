---
layout: post
title: Migration from Snowflake to Clickhouse
date: 2023-03-23
categories: [Database]
---

Snowflake에서 Clickhouse로 데이터를 이전하는 과정을 정리하였다.

이전 단계는 다음과 같이 진행하였다.
1. 이전하려는 Snowflake 데이터를 S3 Stage로 언로딩한다. Stage는 버킷 내 저장된 데이터를 직접 확인하기 위해 AWS external S3 bucket을 적용하였다. 
2. 데이터를 삽입하기 위해 Clickhouse 테이블을 생성한다. Clickhouse 데이터 타입 및 문법에 맞게 테이블 스키마를 생성해야 한다.
3. Clickhouse S3 table engine을 통해 Stage에서 Clickhouse로 데이터를 삽입한다.

즉 크게 보면 Snowflake -> S3 -> Clickhouse의 흐름으로 데이터가 이전된다.

이전 과정에서 설정한 설정 변수 및 파일 형식 등을 좀 더 살펴보겠다.(이 부분은 나의 유즈 케이스에 맞춰 디버깅하면서 필요한 부분을 설정하고 수정한 내용이라 범용적이지 않을 수도 있을 것 같다.)

## Parameters for unloading data
S3에 언로딩하는 과정에서 설정한 파라미터는 크게 파일형식( csv, parquet ), 그에 따른 압축 형식 및 기타 옵션 등이 있었다.

Snowflake에서 S3로 데이터를 언로딩할 때 보통 csv 또는 parquet을 많이 적용할 것으로 예상된다. 

- file format : csv
- compression : AUTO, GZIP, BZ2, BROTLI, ZSTD, DEFLATE, RAW_DEFLATE

압축 형식은 테스트로 gzip과 zstd를 적용해봤는데, gzip 압축률이 좀 더 높은 것으로 확인되었다.

- file format : parquet 
- compression : AUTO, LZO, SNAPPY

parquet을 사용하게 되면 거의 snappy 압축 방식을 사용한다고 보면 된다. 비교해보면, csv + gzip가 압축률이 높은 것으로 확인된다.

약 1.3G 데이터를 압축했을 때 다음과 같은 용량으로 나왔다.
- csv + gzip : 858.5 MB
- csv + zstd : 889.4 MB
- parquet + snappy : 약 1.0 GB

하지만 데이터 로딩 속도는  parquet + snappy가 훨씬 빠르다. snappy는 높은 압축률보다는 빠른 압축이 가능하도록 설계되어, 분산 시스템 및 빅데이터 처리에서 적합한 압축 방식이라고 한다. 

CSV인 경우에는 NULL 값을 직접 설정해야 하고 Clickhouse로 데이터를 덤프하는 과정에서 잦은 파싱 오류가 발생하였다.

처음 CSV를 적용했을 때 Snowflake `COPY INTO` 파라미터를 아래와 같이 세팅하였다.
```
TYPE = CSV
```
- `COMPRESSION = GZIP` 
- `RECORD_DELIMITER = \n` : default
- `FIELD_DELIMITER = ,` : default
- `FILE_EXTENSION = null`  : default
- `DATE_FORMAT = AUTO` : default
- `TIME_FORMAT = AUTO` : default
- `TIMESTAMP_FORMAT = AUTO` : default
- `BINARY_FORMAT = HEX` : default
- `ESCAPE = NONE` : default
- `ESCAPE_UNENCLOSED_FIELD = \\` : default
- `EMPTY_FIELD_AS_NULL = TRUE` : default
- `FIELD_OPTIONALLY_ENCLOSED_BY = "` : `EMPTY_FIELD_AS_NULL = TRUE` 이면 적용되는 파라미터로,  `"` 또는 `'`만 가능하다. String에서  `"` 또는 `'`를 붙일지 정의한다. 빈 string을 구분하기 위해서 적용하는 파라미터이다. 만일 `EMPTY_FIELD_AS_NULL = FALSE` & `FIELD_OPTIONALLY_ENCLOSED_BY = NONE` 이면 빈 string을 NULL과 구분하지 못할 수 있다.
- `NULL_IF = /NULL/` : NULL 값을 정의한다.

Clickhouse에서 데이터 삽입 시에 `EMPTY_FIELD_AS_NULL = TRUE` & `FIELD_OPTIONALLY_ENCLOSED_BY` 값을 설정하지 않으면 빈 string은 NULL로 인식한다. 데이터에서 엄연히 둘은 다른 것으로 따로 설정해주는 것이 필요할 것 같다.

Clickhouse에서는 S3 table engine에서 CSV 포맷 형식을 다음과 같이 설정하였다.
- `format_csv_delimiter = ,` : default
- `format_csv_allow_single_quotes = true`  : default
- `format_csv_allow_double_quotes = true` : default
- `format_csv_null_representation = /NULL/` : **위에서 설정한 Snowflake `NULL_IF`와 일치**해야 원하는대로 NULL로 인식한다.
- `input_format_csv_empty_as_default = true` : default
- `input_format_csv_enum_as_number = false` : default
- `input_format_csv_use_best_effort_in_schema_inference = true` : default
- `input_format_csv_arrays_as_nested_csv = false` : default
- `output_format_csv_crlf_end_of_line = false` : default
- `input_format_csv_skip_first_lines = 0` : default
- `input_format_csv_detect_header = true` : default

위에서 NULL값 때문에 파싱 오류가 있어서 수정이 필요하였다. String의 경우에는 `"`로 감싸서 실제 csv 파일에서는 `,"/NULL/,"로 값이 저장되는데 Clickhouse에서는 이를 NULL로 제대로 인식한다. 하지만 Float 타입에서는 데이터를 저장할 때 quotes를 포함하지 않으므로 `,/NULL/,`로 저장되는데 Clickhouse에서 오류가 발생한다. `/NULL/`을 처음부터 quotes로 감싸서 저장하면 String이든, Decimal이든 quotes를 포함해서 인식하기에 파싱 오류가 해결된다.

- `NULL_IF = '/NULL/'`
- `format_csv_null_representation = "'/NULL/'", '/NULL/'`

String이면 값이 `"'/NULL/'"로 저장될 것이고, Decimal같은 타입이면 `'/NULL/'`로 저장되어 둘 다 NULL값을 인식한다.

CSV를 적용하니 데이터를 저장하고 불러오는데 수동으로 설정한 변수가 많아, 그렇게 깔끔하다는 느낌이 들지 않는다.
Parquet을 사용하면 파싱 오류는 거의 발생하지 않았다. 결국 다음과 같이 세팅하여 사용하였다.

- **CREATE SNOWFLAK STAGE**
```sql
    CREATE OR REPLACE STAGE {stage}
        storage_integration = {storage_integration}
        url = 's3://{bucket}/{schema}/{table}/'
        file_format = (type=parquet compression='snappy')
```

- **COPY INTO Snowflake data to S3**
```sql
        COPY INTO @{stage} from {source}
            file_format = (type=parquet compression='snappy')
            OVERWRITE = TRUE
            HEADER = TRUE
            MAX_FILE_SIZE = 4900000000;
```

- **INSET data into Clickhouse**
```sql
        INSERT INTO {table} SELECT * FROM s3('{s3_url}/*.snappy.parquet', {access_key_id}, {secret_access_key}, 'Parquet')
```

Snowflake는 테이블명이나 칼럼명이 case-insensitive하게 쿼리가 가능하나, Clickhouse에서는 기본적으로 case-sensitive하다. Clickhouse 테이블 생성시에 칼럼명을 소문자로 설정하였다고, Snowflake에서 `HEADER = True` 옵션으로 칼럼명이 대문자로 저장되어 Clickhouse 데이터 덤프시에 칼럼 miss match 오류가 발생할 것이다. 

`SET input_format_parquet_case_insensitive_column_matching=1`을 설정하여 일시적으로 case-insensitive 상태로 만들어서 해결하였다.

## Table Schema

### [Snowflake] Data Type - Timestamp

- `timestamp_ntz` : timestamp with timezone
- `timestamp_tz` : timestamp without time zone
- `timestamp_ltz` : timestamp with local time zone

### [Clickhouse] Data Type - Datetime
```
DateTime64(precision, [timezone])
```
- Tick size (precision): 10-precision seconds( 0 ~ 9 ). 
    - Typically are used - 3 (milliseconds), 6 (microseconds), 9 (nanoseconds).
- Supported : [1900-01-01 00:00:00, 2299-12-31 23:59:59.99999999]. 
    - If date value over `2299-12-31 23:59:59.99999999`( ex. `9999-12-31` ), Clickhosue change the value as `2299-12-31 23:59:59.{precision}`
- Data to be inserted must match precision with precision defined in table
    - ex: If data is "2010-12-31 23:59:12.000", datetime precision should be 3. If precision set to 9, ERROR.

### [Snowflake] Data Type - ARRAY
VARIANT in ARRAY. VARIANT means any data types

### [Clickhouse] Data Type - Array(t)
Must define which data type(`t`) to be stored in Array

### [Clickhouse] Set Nullable
As default( if not set `Nullable`), set default as follows:
- for data type `String` : '' (empty string)
- for data type `Datetime` : 1970-01-01 09:00:00.000000000
- for data type `Float` : 0

### Snowflake -> Clickhouse Conversion

|snowflake|clickhouse|
|---------|---|
| TEXT | String, FixedString |
| DATE | Date |
| FLOAT | Float32, Float64, .. | 
| NUMBER | Decimal |
| BOOLEAN | Bool |
| TIMESTAMP_LTZ | DateTime, DateTime64, .. |
| TIMESTAMP_NTZ | DateTime, DateTime64, .. |
| TIMESTAMP_TZ | DateTime, DateTime64, .. |
| OBJECT | JSON |
| ARRAY | Array |


# Reference
- [Purpose of ESCAPE_UNENCLOSED_FIELD option in file-format and how to use it](https://community.snowflake.com/s/article/Use-of-ESCAPE-UNENCLOSED-FIELD-option-in-file-format)
- [Clickhouse Decimal](https://clickhouse.com/docs/en/sql-reference/data-types/decimal)
- [Clickhouse Array](https://clickhouse.com/docs/en/sql-reference/data-types/array#working-with-data-types)
- [Clickhouse MergeTree](https://clickhouse.com/docs/en/engines/table-engines/mergetree-family/mergetree)
- [Snowflake ARRAY](https://docs.snowflake.com/en/sql-reference/data-types-semistructured#label-data-type-variant)
- [Clickhouse Datetime](https://clickhouse.com/docs/en/sql-reference/data-types/datetime64)
- [Clickhouse Format](https://clickhouse.com/docs/en/operations/settings/formats)
- [Snowflake COPY INTO options](https://docs.snowflake.com/en/sql-reference/sql/copy-into-table)
- [parquet vs. csv](https://velog.io/@freetix/parquet-csv-parquet-%ED%8C%8C%EC%9D%BC-%EB%B6%88%EB%9F%AC%EC%98%A4%EA%B8%B0-%ED%85%8C%EC%8A%A4%ED%8A%B8)
- [Dumping a Snowflake Table to Parquet](https://altinity.com/blog/migrating-data-from-snowflake-to-clickhouse-using-s3-and-parquet)