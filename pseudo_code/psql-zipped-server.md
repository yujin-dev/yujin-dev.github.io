## psql export to zip file
```sql
COPY table_name TO stdout DELIMITER ',' CSV HEADER | gzip > table_name.csv.gz

-- with column info
COPY table_name(column1, column2) TO stdout DELIMITER ',' CSV HEADER | gzip > table_name.csv.gz

-- one command
COPY table_name to PROGRAM 'gzip > /table_name.csv.gz' delimiters',' CSV HEADER;
```
시간 체크

doc : https://www.postgresql.org/docs/9.4/sql-copy.html

## zip file 데이터 주고받기 위한 서버 통신  
`zeromq` 사용해볼것

### server
```python
import zeromq

class DataServer:

    def __init__(self):
        # 데이터 종류(각 테이블별) 매핑되는 PORT 정보

    def subscribe(self):
        # PUB/SUB 구조로 client에서 요청 받음
    
    def publish(self):
        # client에 파일 결과 전달
```
### client

```python
class DataClient:

    def __init__(self):
        # zip데이터를 로드할 수 있는 서버 정도

    def request(self, dataset):
        # dataset에 해당하는 요청을 서버에 전달
    
    def receive(self):
        # 결과 전달 받음
    
    def unzip(self):
        result = self.receive(self)
        # unzip zipped data
```



