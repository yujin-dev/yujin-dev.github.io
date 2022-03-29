# data store in Cloud SQL vs. BigQuery Storage?

기존에 (1)AWS RDS(PostgreSQL)에 업데이트되고 있는 사내 DB를 BigQuery에 replicate하는 방식이 있고, (2)RDS를 Cloud SQL로 이전하고 BigQuery로 데이터를 조회하는 방법이 있다. 

(1)은 BigQuery 스토리지가 데이터를 column-oriented 형식으로 저장하여 쿼리가 보다 빠르게 되고 스냅샷 저장이 용이하나 같은 데이터를 저장하는데 클라우드 비용이 2배가 소요된다. BigQuery는 OLAP에 특화되어 있어 WRITE 쿼리가 빈번하게 발생하며 장기적으로 불리할 수도 있다. 

(2)는 Cloud SQL이 row-oriented RDB이나 DB에 데이터가 업데이트되므로 따로 동기화할 필요없이 쿼리가 가능한 점이 있다. 

둘 다 BigQuery라는 하나의 플랫폼으로 데이터에 접근이 가능하다. 디스크에 데이터를 저장하고 스냅샷을 관리하는 점에서 다를 것으로 예상되는데 유의미한 차이가 있을지 확인해야 한다. 

기존에 사용하는 테이블에서 가장 용량이 큰 테이블(약 55GB )을 대상으로 테스트한다.

1. 해당 테이블 Cloud SQL에 COPY한다.
2. 해당 테이블을 BigQuery DDL로 삽입한다.
3. 다소 복잡한 쿼리로 데이터를 조회해본다.