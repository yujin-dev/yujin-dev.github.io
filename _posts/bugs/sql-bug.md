---
title: "sql-bug"
category: "bug"
---

### Couldn’t execute ‘SELECT COLUMN_NAME, JSON_EXTRACT(HISTOGRAM, ‘$.“number-of-buckets-specified”’) FROM information_schema.COLUMN_STATISTICS WHERE SCHEMA_NAME = ‘DB 이름’ AND TABLE_NAME = ‘테이블 이름‘;’: Unknown table ‘COLUMN_STATISTICS’ in information_schema (1109)

MySQL 8.0 부터 발생하는 오류로 옵션이 활성화되어 었으면 dump시 ANALYZE TABLE에 히스토리를 기록하는데 사용할 테이블이 없으면 발생한다.

```console
$ mysqldump --column-statistics=0 --host={host} --port={post} --user={user} --password={pwd} {DB schema} > {설치할 경로}/backup.sql
``` 
출처: https://jay-ji.tistory.com/62
