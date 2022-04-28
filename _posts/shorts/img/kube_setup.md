## kubectl config 설정

`kubectl config`

- set-credentials : 로그인 관련 정보
- set-cluster : 클러스터 등록
- set-context : credentials, cluster를 조합

kubectl config는 세 가지로 구성된다.

- clusters: 연결할 클러스터의 정보
- users : 사용할 권한의 사용자
- contexts : cluster, user 조합 정보

![](https://img1.daumcdn.net/thumb/R1280x0/?scode=mtistory2&fname=https%3A%2F%2Fblog.kakaocdn.net%2Fdn%2FcileDE%2FbtqUeXBLe0K%2FesioKolPMtKOSLc4UQYPq0%2Fimg.png)

`kubectl config view` 에서 토큰 정보는 `REDACTED` 로 표시되지 않는다.

`~/.kube/config` 에서 확인해야 BASE64로 인코딩된 토큰 정보를 확인할 수 있다.

user나 context를 선택해서 계정 권한을 확인할 수 있다.

```bash
$ kubectl get pod --context user1-context
Error from server (Forbidden): pods is forbidden: User "user1" cannot list resource "pods" in API group "" in the namespace "frontend"

$ kubectl get pod --user user1
Error from server (Forbidden): pods is forbidden: User "user1" cannot list resource "pods" in API group "" in the namespace "default"

$ kubectl get pod --as user1
Error from server (Forbidden): pods is forbidden: User "user1" cannot list resource "pods" in API group "" in the namespace "default"
```

remote cluster으로 `kubectl` 설정하려면 clusters - server를 수정해야 한다.

```bash
apiVersion: v1 
clusters:    
- cluster:
    server: http://<master-ip>:<port>
  name: test 
contexts:
- context:
    cluster: test
    user: test
  name: test
```

[[데브옵스를 위한 쿠버네티스 마스터] 클러스터 유지와 보안, 트러블슈팅 - kube config 파일을 사용한 인증](https://freedeveloper.tistory.com/425)

[Configure kubectl command to access remote kubernetes cluster on azure](https://stackoverflow.com/questions/36306904/configure-kubectl-command-to-access-remote-kubernetes-cluster-on-azure)

## create postgresql secret
```bash
apiVersion: v1
kind: Secret
metadata:
  name: postgresql-credential
  namespace: {{AIRFLOW_CLUSTER}}
type: Opaque
data:
  connection: cG9zdGdyZXNxbDovL3Bvc3RncmVzOnBvc3RncmVzOjU0MzIvcG9zdGdyZXM= # = echo -n postgresql://postgres:postgres:5432/postgres | base64
```

## NFS pvc

![](https://blog.kakaocdn.net/dn/YOZDW/btqAThTUuuc/gxotlwVPJAR0e83v5lzMXk/img.png))

[Kubernetes Persistent Volume 생성하기 - PV, PVC](https://waspro.tistory.com/580)

```bash
no persistent volumes available for this claim and no storage class is set
```

storageclass에서 정의한 annotations의 pathPattern `"${.PVC.namespace}/${.PVC.annotations.nfs.io/storage-path}"` 에 맞춰서 PVC에 annotations에 설정해야 한다. 아니면 persistent volume에 bound되지 않는다.

```bash
 # storageclass
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"storage.k8s.io/v1","kind":"StorageClass","metadata":{"annotations":{},"name":"managed-nfs-storage"},"parameters":{"onDelete":"retain","pathPattern":"${.PVC.namespace}/${.PVC.annotations.nfs.io/storage-path}"},"provisioner":"k8s-sigs.io/nfs-subdir-external-provisioner"}
	name: managed-nfs-storage
...
~~~~
# pvc
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: etl-airflow-postgresql-pvc
  namespace: etl-airflow
  annotations:
    nfs.io/storage-path: "etl-airflow-postgreql"
spec:
  accessModes:
  - ReadOnlyMany
  volumeMode: Filesystem
  resources:
    requests:
      storage: 10Gi
  storageClassName: nfs-storage
```