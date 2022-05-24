
## Setting MySQL parameter: lower_case_table_names, character_set*, collation*

- Cloud SQL MySQL에서는 8.0 버전 이상인 경우 `lower_case_table_names=1` 이 지원되지 않는다.
- AWS RDS MySQL에서는 지원되나 인스턴스 생성시 파라미터 그룹을 변경하여 반영시켜줘야 한다.

![Untitled](img1/Untitled%205.png)

[Configure database flags | Cloud SQL for MySQL | Google Cloud](https://cloud.google.com/sql/docs/mysql/flags)

![Untitled](img1/Untitled%206.png)

[Set MySQL server variable collation_connection to utf8_unicode_ci on AWS RDS](https://stackoverflow.com/questions/35931530/set-mysql-server-variable-collation-connection-to-utf8-unicode-ci-on-aws-rds)

### AWS RDS MySQL 파라미터 변경

AWS RDS 파라미터 그룹에서 `collation_connectio=utf8mb4_bin` 으로 설정하였으나 로컬에서 접속해서 확인하니 변경되지 않았음.

```bash
+---------------------------------+------------------------+
| Variable_name                   | Value                  |
+---------------------------------+------------------------+
| collation_connection            | latin1_swedish_ci            |          |                  |
+---------------------------------+------------------------+
```

→ client에서 연결을 생성할 때 설정이 해줘야 된다기에 `init_connect` 에서 초기 설정될 수 있도록 추가하였더니 적용되었다.

```bash
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

- **SET NAMES 설정시**

설정 예시 : SET NAMES 'utf8mb4'

character_set_client

character_set_connection

character_set_results

- **SET collation_connection**

설정 예시 SET collation_connection='utf8mb4_unicode_ci'

collation_connection 이 변경

- **다중 init-connect 사용시**

init-connect=SET NAMES 'utf8mb4'

init-connect=SET collation_connection='utf8mb4_unicode_ci'

[ 추가 ]

> 클라이언트 환경 변수에 지정된 문자셋 대신 character_set_server 사용을 강제 하는 skip-character-set-client-handshake 파라미터가 지정이 되어 있어도 init-connect 에 설정된 값을 따라서 케릭터셋과 collation 은 설정이 변경 됩니다.
> 

[MySQL Character Set 과 utf8mb4](https://hoing.io/archives/13254)

관련 parameter 설명

[Best practices for configuring parameters for Amazon RDS for MySQL, part 3: Parameters related to security, operational manageability, and connectivity timeout | Amazon Web Services](https://aws.amazon.com/ko/blogs/database/best-practices-for-configuring-parameters-for-amazon-rds-for-mysql-part-3-parameters-related-to-security-operational-manageability-and-connectivity-timeout/)