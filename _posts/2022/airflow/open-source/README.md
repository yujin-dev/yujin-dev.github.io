# Dive into Airflow Source Code

## Overview

![](https://airflow.apache.org/docs/apache-airflow/stable/_images/arch-diag-basic.png)

- Scheduler : *Executor*에 task를 제출하거나, scheduled workflow를 실행시킨다.
- Executor : 실제 task를 실행하는 주체다. 보통 *Worker*에 task를 보내 실행시킨다.
- Metadata Database : *Scheduler*, *Executor*에 사용되며, state를 저장하는 용도이다.
- DAG Directory :  *Scheduler*, *Executor*에 의해 DAG 파일을 읽을 때 사용된다.

대부분 executor는 task queue와 같은 workers를 통해 task를 실행하지만 독립적인 구성 요소로 이해하면 된다. 