
Let's migrate data from Snowflake to Clickhouse.

1. Unload raw data from Snowflake to S3. In this case, I used AWS external S3 bucket for snowflake stage.
2. Create Clickhouse table. For prequiremnets, Snowflake table schema should be converted to Clikchouse table schema with matched data types.
3. Insert data from S3 to Clickhouse with S3 table engine. 

# Parameters
### [Snowflake] `COPY INTO` parameters settings 
`TYPE = CSV`

- `COMPRESSION = GZIP` 
- `RECORD_DELIMITER = \n` : separates records (rows)
- `FIELD_DELIMITER = ,` : separates fields (columns) within a record
- `FILE_EXTENSION = null`
- `DATE_FORMAT = AUTO`
- `TIME_FORMAT = AUTO`
- `TIMESTAMP_FORMAT = AUTO`
- `BINARY_FORMAT = HEX`
- `ESCAPE = NONE`
- `ESCAPE_UNENCLOSED_FIELD = \\`
- `FIELD_OPTIONALLY_ENCLOSED_BY = "`
- `NULL_IF = /NULL/` : SQL NULL값을 변환하는 값
- `EMPTY_FIELD_AS_NULL = TRUE` : `FIELD_OPTIONALLY_ENCLOSED_BY`와 함께 사용
    - `EMPTY_FIELD_AS_NULL = FALSE`, `FIELD_OPTIONALLY_ENCLOSED_BY = NONE`이면 빈 string을 따옴표없이 표시
    - `EMPTY_FIELD_AS_NULL = TRUE`이면, `FIELD_OPTIONALLY_ENCLOSED_BY`을 `"` 또는 `'`으로 표시해야 함

### [Clickhouse] CSV format settings
- `format_csv_delimiter = ,`
- `format_csv_allow_single_quotes = true` 
- `format_csv_allow_double_quotes = true`
- `format_csv_null_representation = "/NULL/"`
- `input_format_csv_empty_as_default = true`
- `input_format_csv_enum_as_number = false`
- `input_format_csv_use_best_effort_in_schema_inference = true`
- `input_format_csv_arrays_as_nested_csv = false`
- `output_format_csv_crlf_end_of_line = false`
- `input_format_csv_skip_first_lines = 0`
- `input_format_csv_detect_header = true`

# Table Schema

### [Snowflake] Data Type - Timestamp

- `timestamp_ntz` : timestamp with timezone
- `timestamp_tz` : timestamp without time zone
- `timestamp_ltz` : timestamp with local time zone

### [Snowflake] Data Type - ARRAY
ARRAY내의 값은 VARIANT 타입으로, 어떤 타입이든 저장할 수 있음

### [Clickhouse] Data Type - Array(t)
Array에 들어갈 데이터 타입을 명시해야 함

### [Clickhouse] Set Nullable
`Nullable`을 설정하지 않으면, null값은 각 data type의 기본값으로 설정됨
- String : '' (empty string)
- Datetime : 1970-01-01 09:00:00.000000000
- Float : 0

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