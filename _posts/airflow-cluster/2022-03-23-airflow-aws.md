# Airflow Cluster on AWS
[Running Airflow Workflow Jobs on Amazon EKS with EC2 Spot Instances](https://aws.amazon.com/ko/blogs/containers/running-airflow-workflow-jobs-on-amazon-eks-spot-nodes/)에 따라 디버깅하며 Airflow Cluster를 생성해본다. 

## Airflow Cluster 생성하기

[https://www.notion.so/Airflow-Cluster-in-AWS-8a173c2f9b054a1090e3259e7ebafd33#8328160bd708432a9649827826c7c937](https://www.notion.so/Airflow-Cluster-in-AWS-8a173c2f9b054a1090e3259e7ebafd33)

1. kubectl , eksctl 설치
    
    [Amazon EKS 시작하기](https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/getting-started.html)
    
2. EKS 클러스터 생성
3. EKS용 kubeconfig 생성하여 업데이트 
    
    [https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/create-kubeconfig.html](https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/create-kubeconfig.html)
    

**Debugging..**

잘 생성이 되면 아래와 같이 나온다고 한다.

*The script will create the following Kubernetes resources:*

- Namespace : `airflow`
- Secret : `airflow-secrets`
- ConfigMap : `airflow-configmap`
- Deployment : `airflow`
- Service: `airflow`
- Storage class: `airflow-sc`
- Persistent volume: `airflow-dags`, `airflow-logs`
- Persistent volume claim: `airflow-dags`, `airflow-logs`
- Service account : `airflow`
- Role : `airflow`
- Role binding : `airflow`

일단 하니 아래처럼 나왔다. deployment 생성이 실패했다.

```bash
$ for node in `kubectl get nodes --label-columns=lifecycle --selector=lifecycle=Ec2Spot -o go-template='{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}'`;do
echo $node $(kubectl describe node $node | grep Taints)
done
ip-192-168-22-14.ap-northeast-2.compute.internal Taints: spotInstance=true:PreferNoSchedule
ip-192-168-87-22.ap-northeast-2.compute.internal Taints: spotInstance=true:PreferNoSchedule

$ kubectl get secret,configmap,deployment,service,storageclasses,persistentvolumes,persistentvolumeclaims,serviceaccounts,roles,rolebindings  -n airflow
NAME                         TYPE                                  DATA   AGE
secret/airflow-secrets       Opaque                                1      38m
secret/airflow-token-69fzp   kubernetes.io/service-account-token   3      38m
secret/default-token-9tmn2   kubernetes.io/service-account-token   3      38m

NAME                          DATA   AGE
configmap/airflow-configmap   1      38m

NAME                      READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/airflow   0/1     1            0           38m

NAME              TYPE           CLUSTER-IP      EXTERNAL-IP                                                                    PORT(S)          AGE
service/airflow   LoadBalancer   10.100.217.59   ae2a663f376b1464282086eb7e61b8a9-1000354845.ap-northeast-2.elb.amazonaws.com   8080:32309/TCP   38m

**NAME                                        PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
storageclass.storage.k8s.io/efs-sc          efs.csi.aws.com         Delete          Immediate              false                  38m
storageclass.storage.k8s.io/gp2 (default)   kubernetes.io/aws-ebs   Delete          WaitForFirstConsumer   false                  21h

NAME                              CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                     STORAGECLASS   REASON   AGE
persistentvolume/airflow-efs-pv   100Gi      RWX            Retain           Bound    airflow/airflow-efs-pvc   efs-sc                  38m

NAME                                    STATUS   VOLUME           CAPACITY   ACCESS MODES   STORAGECLASS   AGE
persistentvolumeclaim/airflow-efs-pvc   Bound    airflow-efs-pv   100Gi      RWX            efs-sc         38m**

NAME                     SECRETS   AGE
serviceaccount/airflow   1         38m
serviceaccount/default   1         38m

NAME                                     CREATED AT
role.rbac.authorization.k8s.io/airflow   2022-03-23T03:25:13Z

NAME                                            ROLE           AGE
rolebinding.rbac.authorization.k8s.io/airflow   Role/airflow   38m

```

```bash
+ PODS='airflow-845f457557-r6rh7   0/2     Init:CrashLoopBackOff   3          65s'
```

`kubectl describe` 로 확인하니 `Init:CrashLoopBackOff` 발생하여 initContainers 생성이 실패함을 알 수 있다.

로그를 확인한다. 로그는 pod name, container name 정보를 기반으로 한다. `--previous` 를 붙이면 이전 Pod에 대한 로그를 확인할 수 있다.

airflow version 이랑 WTforms라는 패키지 버전이 안 맞아서 발생했는데 Docker 이미지 생성에서 필요한 version을 전반적으로 수정하였다. 

```bash
$ kubectl logs -p airflow-d596f8f66-bjfpw -c init -n airflow           
+ /tmp/airflow-test-env-init.sh
Traceback (most recent call last):
  File "/usr/local/bin/airflow", line 26, in <module>
    from airflow.bin.cli import CLIFactory
  File "/usr/local/lib/python3.6/site-packages/airflow/bin/cli.py", line 70, in <module>
    from airflow.www.app import (cached_app, create_app)
  File "/usr/local/lib/python3.6/site-packages/airflow/www/app.py", line 37, in <module>
    from airflow.www.blueprints import routes
  File "/usr/local/lib/python3.6/site-packages/airflow/www/blueprints.py", line 25, in <module>
    from airflow.www import utils as wwwutils
  File "/usr/local/lib/python3.6/site-packages/airflow/www/utils.py", line 32, in <module>
    from wtforms.compat import text_type
ModuleNotFoundError: No module named 'wtforms.compat'
```

다시 하니 아래 처럼 Pending으로 파드 scheduling이 실패하였는데 일시적인 오류였던 것 같다.

```bash
+ PODS='airflow-845f457557-kts2w   0/2     Pending   0          7m29s'
```

```bash
Events:
  Type     Reason            Age                  From               Message
  ----     ------            ----                 ----               -------
  Warning  FailedScheduling  87s (x8 over 7m26s)  default-scheduler  0/4 nodes are available: 2 node(s) didn't match node selector, 2 pod has unbound immediate PersistentVolumeClaims.
```

```bash
$ kubectl describe pvc -n airflow
Name:          airflow-efs-pvc
Namespace:     airflow
StorageClass:  efs-sc
Status:        Pending
Volume:        
Labels:        <none>
Annotations:   volume.beta.kubernetes.io/storage-provisioner: efs.csi.aws.com
Finalizers:    [kubernetes.io/pvc-protection]
Capacity:      
Access Modes:  
VolumeMode:    Filesystem
Used By:       airflow-845f457557-kts2w
Events:
  Type     Reason                Age                   From                                                                                                    Message
  ----     ------                ----                  ----                                                                                                    -------
  Normal   Provisioning          3m35s (x12 over 17m)  efs.csi.aws.com_ip-192-168-33-252.ap-northeast-2.compute.internal_1f29e38c-e827-4fb9-8ae5-01ba0ce39f8f  External provisioner is provisioning volume for claim "airflow/airflow-efs-pvc"
  Warning  ProvisioningFailed    3m35s (x12 over 17m)  efs.csi.aws.com_ip-192-168-33-252.ap-northeast-2.compute.internal_1f29e38c-e827-4fb9-8ae5-01ba0ce39f8f  failed to provision volume with StorageClass "efs-sc": rpc error: code = InvalidArgument desc = Missing provisioningMode parameter
  Normal   ExternalProvisioning  2m (x62 over 17m)     persistentvolume-controller                                                                             waiting for a volume to be created, either by external provisioner "efs.csi.aws.com" or manually created by system administrator
```

로컬에서 docker 이미지 빌드하여 가능한 부분만 먼저 테스트 후 다시 실행했는데 이번에 RDS 연결 오류가 발생하였다. 

```bash
sqlalchemy.exc.OperationalError: (psycopg2.OperationalError) connection to server at "airflow-postgres.cqhwqfsfjio8.ap-northeast-2.rds.amazonaws.com" (192.168.94.108), port 5432 failed: Connection timed out
	Is the server running on that host and accepting TCP/IP connections?
```

AWS에서 보안 그룹을 확인하니 RDS security group - inbond 규칙에서 node의 접속 허용을 위한 source를 추가하였다.

다시 돌려서 Pod를 확인하니 scheduler는 돌아가는데 webserver 생성이 실패했다.

```bash
Name:         airflow-845f457557-5kcb8
Namespace:    airflow
Priority:     0
Node:         ip-192-168-72-216.ap-northeast-2.compute.internal/192.168.72.216
Start Time:   Wed, 23 Mar 2022 19:36:22 +0900
Labels:       name=airflow
              pod-template-hash=845f457557
Annotations:  kubernetes.io/psp: eks.privileged
Status:       Running
IP:           192.168.91.90
IPs:
  IP:           192.168.91.90
Controlled By:  ReplicaSet/airflow-845f457557
Init Containers:
  init:
    Container ID:  docker://a9407a3965d2fef435b735dedbdc3c821a1c485ed12566c952ff19c549f129ca
    Image:         717473574740.dkr.ecr.ap-northeast-2.amazonaws.com/airflow-eks-demo:latest
    Image ID:      docker-pullable://717473574740.dkr.ecr.ap-northeast-2.amazonaws.com/airflow-eks-demo@sha256:392e7758e81b68811e38e22b31f48fc06f2dc4db2e0885b9cc05b747f1c95861
    Port:          <none>
    Host Port:     <none>
    Command:
      /bin/bash
    Args:
      -cx
      /tmp/airflow-test-env-init.sh 
    State:          Terminated
      Reason:       Completed
      Exit Code:    0
      Started:      Wed, 23 Mar 2022 19:36:23 +0900
      Finished:     Wed, 23 Mar 2022 19:36:29 +0900
    Ready:          True
    Restart Count:  0
    Environment:
      SQL_ALCHEMY_CONN:  <set to the key 'sql_alchemy_conn' in secret 'airflow-secrets'>  Optional: false
    Mounts:
      /root/airflow/airflow.cfg from airflow-configmap (rw,path="airflow.cfg")
      /root/airflow/dags from airflow-dags (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from airflow-token-qj89x (ro)
Containers:
  webserver:
    Container ID:  docker://c76120eb1ad53613d78d4e27862bc536a9260ee07fd4983fce6210cf16d17c22
    Image:         717473574740.dkr.ecr.ap-northeast-2.amazonaws.com/airflow-eks-demo:latest
    Image ID:      docker-pullable://717473574740.dkr.ecr.ap-northeast-2.amazonaws.com/airflow-eks-demo@sha256:392e7758e81b68811e38e22b31f48fc06f2dc4db2e0885b9cc05b747f1c95861
    Port:          8080/TCP
    Host Port:     0/TCP
    Args:
      webserver
    State:          **Waiting**
      Reason:       **CrashLoopBackOff**
    Last State:     **Terminated**
      Reason:       **Error**
      Exit Code:    1
      Started:      Wed, 23 Mar 2022 19:42:30 +0900
      Finished:     Wed, 23 Mar 2022 19:42:33 +0900
    Ready:          False
    Restart Count:  6
    Environment:
      AIRFLOW_KUBE_NAMESPACE:  airflow (v1:metadata.namespace)
      SQL_ALCHEMY_CONN:        <set to the key 'sql_alchemy_conn' in secret 'airflow-secrets'>  Optional: false
    Mounts:
      /root/airflow/airflow.cfg from airflow-configmap (rw,path="airflow.cfg")
      /root/airflow/dags from airflow-dags (rw)
      /root/airflow/logs from airflow-dags (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from airflow-token-qj89x (ro)
  scheduler:
    Container ID:  docker://755c41027e8e303482a3bee6bf20444b14d357332be1d3e84b87639b634002e5
    Image:         717473574740.dkr.ecr.ap-northeast-2.amazonaws.com/airflow-eks-demo:latest
    Image ID:      docker-pullable://717473574740.dkr.ecr.ap-northeast-2.amazonaws.com/airflow-eks-demo@sha256:392e7758e81b68811e38e22b31f48fc06f2dc4db2e0885b9cc05b747f1c95861
    Port:          <none>
    Host Port:     <none>
    Args:
      scheduler
    State:          **Running**
      Started:      Wed, 23 Mar 2022 19:36:30 +0900
    Ready:          True
    Restart Count:  0
    Environment:
      AIRFLOW_KUBE_NAMESPACE:  airflow (v1:metadata.namespace)
      SQL_ALCHEMY_CONN:        <set to the key 'sql_alchemy_conn' in secret 'airflow-secrets'>  Optional: false
    Mounts:
      /root/airflow/airflow.cfg from airflow-configmap (rw,path="airflow.cfg")
      /root/airflow/dags from airflow-dags (rw)
      /root/airflow/logs from airflow-dags (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from airflow-token-qj89x (ro)
Conditions:
  Type              Status
  Initialized       True 
  Ready             False 
  ContainersReady   False 
  PodScheduled      True 
...
Tolerations:     node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                 node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type     Reason     Age                  From               Message
  ----     ------     ----                 ----               -------
  Normal   Scheduled  10m                  default-scheduler  Successfully assigned airflow/airflow-845f457557-5kcb8 to ip-192-168-72-216.ap-northeast-2.compute.internal
  Normal   Pulled     10m                  kubelet            Successfully pulled image "717473574740.dkr.ecr.ap-northeast-2.amazonaws.com/airflow-eks-demo:latest"
  Normal   Created    10m                  kubelet            Created container init
  Normal   Started    10m                  kubelet            Started container init
  Normal   Pulling    10m                  kubelet            Pulling image "717473574740.dkr.ecr.ap-northeast-2.amazonaws.com/airflow-eks-demo:latest"
  Normal   Pulling    10m                  kubelet            Pulling image "717473574740.dkr.ecr.ap-northeast-2.amazonaws.com/airflow-eks-demo:latest"
  Normal   Started    10m                  kubelet            Started container scheduler
  Normal   Created    10m                  kubelet            Created container scheduler
  Normal   Pulled     10m                  kubelet            Successfully pulled image "717473574740.dkr.ecr.ap-northeast-2.amazonaws.com/airflow-eks-demo:latest"
  Normal   Created    10m (x3 over 10m)    kubelet            Created container webserver
  Normal   Started    10m (x3 over 10m)    kubelet            Started container webserver
  Normal   Pulled     9m39s (x4 over 10m)  kubelet            Successfully pulled image "717473574740.dkr.ecr.ap-northeast-2.amazonaws.com/airflow-eks-demo:latest"
  Normal   Pulling    9m39s (x4 over 10m)  kubelet            Pulling image "717473574740.dkr.ecr.ap-northeast-2.amazonaws.com/airflow-eks-demo:latest"
  Warning  BackOff    28s (x45 over 10m)   kubelet            Back-off restarting failed container
```

webserver로그를 확인하니 secret_key가 안 맞는 것 같다.

configmap.yaml에서 airflow.cfg 의 secret_key를 좀더 복잡한 것으로 설정한다.

다시 생성하면 잘 나온다.

```bash
NAME                                                STATUS   ROLES    AGE   VERSION               INTERNAL-IP      EXTERNAL-IP      OS-IMAGE         KERNEL-VERSION                  CONTAINER-RUNTIME
ip-192-168-22-14.ap-northeast-2.compute.internal    Ready    <none>   28h   v1.18.20-eks-c9f1ce   192.168.22.14    3.36.54.65       Amazon Linux 2   4.14.268-205.500.amzn2.x86_64   docker://20.10.7
ip-192-168-33-252.ap-northeast-2.compute.internal   Ready    <none>   28h   v1.18.20-eks-c9f1ce   192.168.33.252   15.164.208.169   Amazon Linux 2   4.14.268-205.500.amzn2.x86_64   docker://20.10.7
ip-192-168-72-216.ap-northeast-2.compute.internal   Ready    <none>   28h   v1.18.20-eks-c9f1ce   192.168.72.216   3.37.123.202     Amazon Linux 2   4.14.268-205.500.amzn2.x86_64   docker://20.10.7
ip-192-168-87-22.ap-northeast-2.compute.internal    Ready    <none>   28h   v1.18.20-eks-c9f1ce   192.168.87.22    3.34.183.44      Amazon Linux 2   4.14.268-205.500.amzn2.x86_64   docker://20.10.7
```

AirflowUI에 접속하려 하니 로그인이 실패하였다.

`kubectl exec $(kubectl get pods -n airflow | awk '{print $1}' | xargs | cut -d ' ' -f 2) -it -c webserver -n airflow /bin/bash` 로 webserver에 접속하여 postgresql client를 설치하고 DB에서 계정이 있는지 확인한다. `ab_user` 테이블에서 확인할 수 있다.

없으면 `airflow users create` 로 계정을 생성하여 로그인한다.

[Airflow Login Failed After Creating User](https://stackoverflow.com/questions/66280133/airflow-login-failed-after-creating-user)

```

예시 DAG를 트리거하면 operator에 따라 Spot Pod가 생성된다.

##### example_bash_operator
....
    for i in range(3):
        task = BashOperator(
            task_id='runme_' + str(i),
            bash_command='echo "{{ task_instance_key_str }}" && sleep 1',
        )
...
    # [START howto_operator_bash_template]
    also_run_this = BashOperator(
        task_id='also_run_this',
        bash_command='echo "run_id={{ run_id }} | dag_run={{ dag_run }}"',
    )
....
# [START howto_operator_bash_skip]
this_will_skip = BashOperator(
    task_id='this_will_skip',
    bash_command='echo "hello world"; exit 99;',
    dag=dag,
)
##### 

NAME                                                               READY   STATUS             RESTARTS   AGE
airflow-845f457557-9w5pg                                           2/2     Running            0          17h
examplebashoperatoralsorunthis.e7186c0615444d6090e5f6a9ee81225f    0/1     CrashLoopBackOff   4          2m56s
examplebashoperatoralsorunthis.ec61ccccaf9a434b8661bf7edd74de91    0/1     CrashLoopBackOff   4          2m52s
examplebashoperatorrunme0.01bc9ca3487a479eb467272cadd01006         0/1     CrashLoopBackOff   4          2m58s
examplebashoperatorrunme0.ac336bfd83824c5ab4b5a37c35272aa9         0/1     CrashLoopBackOff   4          2m59s
examplebashoperatorrunme1.11aaf07ebfb046d7a30e95262bff9ef4         0/1     Completed          5          3m
examplebashoperatorrunme1.37bafd7e66114451942d56bdca2a1f11         0/1     CrashLoopBackOff   4          2m57s
examplebashoperatorrunme2.0cb28accecae402f89e8283826f88945         0/1     CrashLoopBackOff   4          2m57s
examplebashoperatorrunme2.f1d5e32724984216982575a663727051         0/1     CrashLoopBackOff   4          3m
examplebashoperatorthiswillskip.340fe941caf24878ac236ee69977bc51   0/1     CrashLoopBackOff   4          2m53s
examplebashoperatorthiswillskip.e5e72aadda154f5b89f7347452047a61   0/1     Completed          5          2m55s

```
각 Operator마다 Worker Pod를 생성하여 실행되는데 `CrashLoopBackOff`상태로 실패하였다. `describe`명령어로 `Args`를 보면 airflow 이미지를 받아 `airflow tasks run`으로 동작하는데 airflow config가 제대로 설정되지 않은 것으로 보인다. 

```bash
Name:         examplebashoperatorrunme0.01bc9ca3487a479eb467272cadd01006
Namespace:    airflow
Priority:     0
Node:         ip-192-168-72-216.ap-northeast-2.compute.internal/192.168.72.216
Start Time:   Thu, 24 Mar 2022 13:19:08 +0900
Labels:       airflow-worker=4
              airflow_version=2.2.1
              dag_id=example_bash_operator
              kubernetes_executor=True
              run_id=manual__2022-03-24T041905.5161770000-e017e1369
              task_id=runme_0
              try_number=1
Annotations:  dag_id: example_bash_operator
              kubernetes.io/psp: eks.privileged
              run_id: manual__2022-03-24T04:19:05.516177+00:00
              task_id: runme_0
              try_number: 1
Status:       Running
IP:           192.168.73.244
IPs:
  IP:  192.168.73.244
Containers:
  base:
    Container ID:  docker://439314f36efcfa6afb739d6952230d666c2a5228e6435d8d868412ee4eb333f8
    Image:         717473574740.dkr.ecr.ap-northeast-2.amazonaws.com/airflow-eks-demo:latest
    Image ID:      docker-pullable://717473574740.dkr.ecr.ap-northeast-2.amazonaws.com/airflow-eks-demo@sha256:392e7758e81b68811e38e22b31f48fc06f2dc4db2e0885b9cc05b747f1c95861
    Port:          <none>
    Host Port:     <none>
    Args:
      airflow
      tasks
      run
      example_bash_operator
      runme_0
      manual__2022-03-24T04:19:05.516177+00:00
      --local
      --subdir
      DAGS_FOLDER/example_bash_operator.py
    **State:          Waiting
      Reason:       CrashLoopBackOff**
    **Last State:     Terminated
      Reason:       Completed
      Exit Code:    0**
      Started:      Thu, 24 Mar 2022 14:16:30 +0900
      Finished:     Thu, 24 Mar 2022 14:16:30 +0900
    Ready:          False
    Restart Count:  16
    Environment:
      AIRFLOW_IS_K8S_EXECUTOR_POD:  True
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-d8dp4 (ro)
Conditions:
  Type              Status
  Initialized       True 
  Ready             False 
  ContainersReady   False 
  PodScheduled      True 
Volumes:
  default-token-d8dp4:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  default-token-d8dp4
    Optional:    false
QoS Class:       BestEffort
Node-Selectors:  <none>
Tolerations:     node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                 node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type     Reason   Age                  From     Message
  ----     ------   ----                 ----     -------
  Normal   Created  60m (x4 over 60m)    kubelet  Created container base
  Normal   Started  60m (x4 over 60m)    kubelet  Started container base
  Normal   Pulling  59m (x5 over 60m)    kubelet  Pulling image "/airflow-eks-demo:latest"
  Normal   Pulled   59m (x5 over 60m)    kubelet  Successfully pulled image "/airflow-eks-demo:latest"
  Warning  BackOff  44s (x282 over 60m)  kubelet  Back-off restarting failed container
```

실패한 pod에 대해서 로그를 확인하니 아래와 같이 sqlite3 접속이 실패되었다고 한다. 기존에 설정한 airflow metaDB 를 PostgreSQL로 설정하였는데 airflow.cfg가 반영되지 않은 것으로 확인된다.
```
Traceback (most recent call last):
  File "/usr/local/lib/python3.8/site-packages/airflow/models/dagbag.py", line 331, in _load_modules_from_file
    loader.exec_module(new_module)
  File "<frozen importlib._bootstrap_external>", line 843, in exec_module
  File "<frozen importlib._bootstrap>", line 219, in _call_with_frames_removed
  File "/usr/local/lib/python3.8/site-packages/airflow/example_dags/example_python_operator.py", line 84, in <module>
    virtualenv_task = PythonVirtualenvOperator(
  File "/usr/local/lib/python3.8/site-packages/airflow/models/baseoperator.py", line 188, in apply_defaults
    result = func(self, *args, **kwargs)
  File "/usr/local/lib/python3.8/site-packages/airflow/operators/python.py", line 342, in __init__
    raise AirflowException('PythonVirtualenvOperator requires virtualenv, please install it.')
airflow.exceptions.AirflowException: PythonVirtualenvOperator requires virtualenv, please install it.
[2022-03-24 07:24:26,476] {dagbag.py:334} ERROR - Failed to import: /usr/local/lib/python3.8/site-packages/airflow/example_dags/example_subdag_operator.py
Traceback (most recent call last):
  File "/usr/local/lib/python3.8/site-packages/sqlalchemy/engine/base.py", line 1808, in _execute_context
    self.dialect.do_execute(
  File "/usr/local/lib/python3.8/site-packages/sqlalchemy/engine/default.py", line 732, in do_execute
    cursor.execute(statement, parameters)
sqlite3.OperationalError: no such table: slot_pool

```
[Upgrading from 1.10 to 2 - Airflow Documentation](https://airflow.apache.org/docs/apache-airflow/2.2.1/upgrading-from-1-10/index.html?highlight=airflow_configmap) 에 따르면 airflow 1.10 에서 2 버전으로 바뀌면서 airflow.cfg 항목이 많이 바뀐 것 같다. configmap의 airflow.cfg가 2버전에 맞게 수정되지 않아서 airflow 환경이 제대로 설정되지 않았다.
