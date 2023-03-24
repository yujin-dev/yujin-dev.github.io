---
layout: post
title: Migration from Snowflake to Clickhouse
date: 2023-03-23
categories: [CLICKHOUSE]
---

Let's migrate data from Snowflake to Clickhouse.

1. Unload raw data from Snowflake to S3. In this case, I used AWS external S3 bucket for snowflake stage.
2. Create Clickhouse table. For prequiremnets, Snowflake table schema should be converted to Clikchouse table schema with matched data types.
3. Insert data from S3 to Clickhouse with S3 table engine. 

# Parameters
### [Snowflake] Unloading data
- file format : csv
    - compression : AUTO, GZIP, BZ2, BROTLI, ZSTD, DEFLATE, RAW_DEFLATE
    - seems to be compression efficiency of `gzip` is higher. 
- file format : parquet 
    - compression : AUTO, LZO, SNAPPY
    - data loading speed is much higher 

If the file format is csv, a parsing error may occur or empty string and NULL values ​​may be inserted without distinction when if the option is not properly set. However, parquet does not set the parsing value separately, and there is no case where an error occurs in parsing.

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
- `NULL_IF = /NULL/` : define NULL value
- `EMPTY_FIELD_AS_NULL = TRUE` : use with `FIELD_OPTIONALLY_ENCLOSED_BY`
    - If `EMPTY_FIELD_AS_NULL = FALSE` and `FIELD_OPTIONALLY_ENCLOSED_BY = NONE`, set empty string without double quotes
    - If `EMPTY_FIELD_AS_NULL = TRUE`, `FIELD_OPTIONALLY_ENCLOSED_BY` should be set `"` or `'`

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

### [Snowflake] Stage format type

`snappy`

Snappy compression is a fast and efficient compression algorithm designed to compress and decompress data at high speeds. It was developed by Google and released as an open-source software in 2011.

Snappy is designed to be fast rather than offering the highest compression ratio possible. It achieves high compression and decompression speeds by using a very simple algorithm that operates directly on the input data without requiring any pre-processing or complex data structures.

Snappy works by dividing the input data into small, fixed-size blocks and compressing each block independently. This allows Snappy to take advantage of the local redundancy in the data and achieve high compression ratios without the overhead of more complex algorithms.

Snappy is particularly well-suited for use cases where data needs to be compressed and decompressed quickly, such as in distributed systems and big data processing applications. However, its relatively low compression ratios make it less suitable for use cases where storage space is at a premium.

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