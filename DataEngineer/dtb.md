# DBT
DBT는 아래와 같이 ETL에서 Transformation을 수행한다.  
![](https://miro.medium.com/max/1400/0*gwL5iaxSMgrilZQI)

**유일한 기능은 코드를 통해 SQL로 컴파일하여 DB에서 실행시키는 것이다.**

Snowflake외에 Postgresql, BigQuery 등에서 지원된다.
- 파이썬으로 작성된 오픈소스이다.
- CLI는 데이터 파이프라인 실행을 위한 기능을 제공한다.
- UI는 문서화 작업을 위한 것이다. 
- 모든 *Model*은 원하는 방식으로 데이터를 변환하기 위해 다른 모델과 함께 조율되는 SELECT문이다.  
    ![](https://miro.medium.com/max/1400/0*ONcosYrul6BgIT94)  
    위와 같이 *jinja*는 소스에 없는 technical 행을 삽입하는데 사용된다.

    모든 DBT model은 스키마 정의로 보완되는데, 코드 베이스로 저장되면 모든 단계를 쉽게 이해할 수 있다.

> 출처 : [DBT: A new way to transform data and build pipelines at The Telegraph](https://medium.com/the-telegraph-engineering/dbt-a-new-way-to-handle-data-transformation-at-the-telegraph-868ce3964eb4)