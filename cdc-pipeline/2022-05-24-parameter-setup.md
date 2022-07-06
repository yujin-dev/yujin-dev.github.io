---
title: "PostgreSQL, MySQL parameter setup for CDC"
category: "cdc-pipeline"
---

RDB migration은 **primary key가 있는 테이블**을 대상으로 한다. 

## Setting PostgreSQL parameter

### `logical_replication = 1` 설정
먼저 Parameter Group에서 `rds.logical_replication = 1`로 설정해야 한다.

default.postgres13 그룹에서 설정하려니 <u>요청이 실패한다는 오류</u>가 발생한다. 
공식문서를 확인하니 아래와 같다.

**default DB 파라미터 그룹의 파라미터 값은 변경할 수 없다.**  사용자 지정 DB 파라미터 그룹의 파라미터 값을 수정한다.   
다음과 같은 이유로 파라미터 변경에 오류가 발생할 수 있다.
- [SET](https://dev.mysql.com/doc/refman/5.7/en/set-statement.html)와 같은 명령을 사용하는 경우, RDS DB 인스턴스 구성을 업데이트하는 데 사용할 수 없으므로 오류가 발생할 수 있다.
- DB 인스턴스 구성을 업데이트할 수 없는 경우 default RDS DB 파라미터 그룹의 값을 변경할 수 없기 떄문일 수 있다.
- 파라미터 값을 변경했지만 변경 사항이 적용되지 않은 경우 일부 수정 사항이 즉시 적용되기 않았기 때문일 수 있다.
- 어떤 상황에서도 DB 파라미터를 수정할 수 없는 경우 **수정 가능** 파라미터의 속성 값이 **false**이기 때문일 있다.
> 출처 : [Amazon RDS DB 파라미터 그룹의 값 수정](https://aws.amazon.com/ko/premiumsupport/knowledge-center/rds-modify-parameter-group-values/)

파라미터 그룹을 새로 생성하여 수정하였더니 변경사항이 반영되었다.

```sql
postgres=> select * from pg_extension;
-- pglogical 이 반영되었음을 확인할 수 있다.
  oid  |  extname  | extowner | extnamespace | extrelocatable | extversion | extcon
fig | extcondition 
-------+-----------+----------+--------------+----------------+------------+-------
----+--------------
 14287 | plpgsql   |       10 |           11 | f              | 1.0        |       
    | 
 58004 | pglogical |       10 |        58003 | f              | 2.4.0      |       
    | 
(2 rows)

postgres=> show wal_level;
-- wal_level = logical로 변경됨
 wal_level 
-----------
 logical
(1 row)
```

파리미터를 수정하면 DB 인스턴스를 재부팅하여 반영이 된다.

### pglogical 설치
`pglogical`을 설치하기 위해서 위와 같은 파라미터 설정에서 `shared_load_libraries`에 `pglogical`을 추가해야 한다.

공식문서에 따르면, *Run the CREATE EXTENSION IF NOT EXISTS pglogical command on every database on your source instance. This installs the pglogical extension into the database.* 라고 언급되어 있다.

설치는 하나의 스키마가 아니라 **DB 인스턴스 대상의 전체 스키마에 적용** 해주어야 한다. 처음에 `postgres` 에만 적용하여 Data Migration에서 pglogical이 설치되지 않았다는 메시지가 나온다.

## Setting MySQL parameter
lower_case_table_names, character_set*, collation*에 대한 설정사항을 변경해줘야 한다.

Cloud RDMBS를 사용할 경우 다음과 같은 주의사항이 있다.
- Cloud SQL MySQL에서는 8.0 버전 이상인 경우 `lower_case_table_names=1` 이 지원되지 않는다.  
        ![Untitled](img/cloud-sql-lower-case.png)  
    > 출처: [Configure database flags | Cloud SQL for MySQL | Google Cloud](https://cloud.google.com/sql/docs/mysql/flags)

- AWS RDS MySQL에서는 지원되나 인스턴스 생성시 파라미터 그룹을 변경하여 반영해야  한다.  
    ![Untitled](img/rds-lower-case.png)

Cloud SQL은 8.0이상은 해당 파라미터 변경이 지원되지 않으므로, AWS RDS MySQL를 적용하였다.

> 참고: [Set MySQL server variable collation_connection to utf8_unicode_ci on AWS RDS](https://stackoverflow.com/questions/35931530/set-mysql-server-variable-collation-connection-to-utf8-unicode-ci-on-aws-rds)

[MySQL Character Set 과 utf8mb4](https://hoing.io/archives/13254)를 참고하여 설정한다.

- SET NAMES : `SET NAMES 'utf8mb4'`
    - character_set_client
    - character_set_connection
    - character_set_results

- SET collation_connection : `SET collation_connection='utf8mb4_unicode_ci'`

- 다중 init-connect :  `init-connect=SET NAMES 'utf8mb4'`, `init-connect=SET collation_connection='utf8mb4_unicode_ci'`

*init-connect 에 설정된 값을 따라서 character_set과 collation 설정이 변경된다.*

### `collation_connectio=utf8mb4_bin` 설정
AWS RDS 파라미터 그룹에서 `collation_connectio=utf8mb4_bin` 으로 설정하였으나 로컬에서 접속해서 확인하니 변경되지 않았다.

```sql
+---------------------------------+------------------------+
| Variable_name                   | Value                  |
+---------------------------------+------------------------+
| collation_connection            | latin1_swedish_ci            |          |                  |
+---------------------------------+------------------------+
```

client에서 연결을 생성할 때 설정이 이루어져야 하므로 `init_connect` 에서 초기 설정될 수 있도록 추가하였더니 적용되었다.

```sql
+---------------------------------+------------------------+
| Variable_name                   | Value                  |
+---------------------------------+------------------------+
| collation_connection            | utf8mb4_bin            |
| collation_database              | utf8mb4_bin            |
| collation_server                | utf8mb4_bin            |                  |
+---------------------------------+------------------------+
8 rows in set (0.01 sec)
+---------------+----------------------------------------+
| Variable_name | Value                                  |
+---------------+----------------------------------------+
| init_connect  | set COLLATION_CONNECTION = utf8mb4_bin |
```

> 관련 parameter 설명 : [Best practices for configuring parameters for Amazon RDS for MySQL, part 3: Parameters related to security, operational manageability, and connectivity timeout | Amazon Web Services](https://aws.amazon.com/ko/blogs/database/best-practices-for-configuring-parameters-for-amazon-rds-for-mysql-part-3-parameters-related-to-security-operational-manageability-and-connectivity-timeout/)