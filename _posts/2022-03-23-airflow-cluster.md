# TIL
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