# Flyte vs. Airflow on Kubernetes

Flyte는 기본적으로 쿠버네티스 클러스터 위에서 돌아가고, Airflow는 선택적으로 설정 및 사용이 가능하다. 어떤 점이 다를까?

Flyte 구조
- FlyteAdmin
- Flyte Propeller
- @task, @workflow
- ContainerTask
- how DAG operates/ scheduling : task 및 workflow로 wrapping된 function은 package로 빌드하여(serialize되어) 등록하면 DB(Postgresql)에 저장된다. 저장된 코드는 도커 이미지 위에서 호출되어 사용할 수 있다. 도커 이미지를 받아 파드가 생성되고 파드 안에서 코드가 실행된다. 

Airflow 구조
- KubernetesPodOperator
- how DAG operates/ scheduling(default) : 도커 이미지를 명시하면 Airflow에서 Operator를 실행할 때 이미지를 받아 파드를 생성한다. Flyte에서 `ContainerTask`와 유사하다고 할 수 있다. 마찬가지로 파드 생성 시 입력된 이미지 경로에서 pull하여 사용하기 때문.

데이터를 전달받는 구조도 다르다.
- Flyte : 결과값을 s3에 임의로 저장하여 다음 task 또는 workflow에 input으로 사용된다. 경로는 Flyte 내부적으로 정해지고 데이터를 업로드했다가 다운받는다. annotations를 통해 input, output의 type을 명시하면 사용이 가능하다
- Airflow: xcom으로 DAG안에서 task간에 데이터 주고받기가 가능하나, 애초에 작은 사이즈의 데이터가 이용되고 dataframe 같은 데이터를 사용하려면 Task 내부적으로 직접 S3 같은 스토리지에 직접 저장하였다가, 받아서 사용한다.

Flyte는 모델 파이프라인을 위주로 사용되고, Airflow는 기본적으로 scheduling 기반으로 workflow 관리에 더 적합하다. 