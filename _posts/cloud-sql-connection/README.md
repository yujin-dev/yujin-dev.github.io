## Connect to Cloud SQL

![Untitled](Untitled%202.png)

public IP는 Authorization이 필요한데 위의 방법 중에 사용해야 한다.

![Untitled](Untitled%203.png)

private IP는 따로 authorization이 필요없고 같은 VPC내이면 접속이 가능하나 sidecar로 proxy를 사용하는 것이 권장된다.

![Untitled](Untitled%204.png)

**Recommended** : application에 sidecar로 Proxy를 사용하는 것이 좋다.

GKE에서 사용하려면 SA( service account )key를 secret으로 생성해서 mount해야 한다.

![Untitled](Untitled%205.png)

![Untitled](Untitled%206.png)

[Connecting to Cloud SQL from Kubernetes](https://www.youtube.com/watch?v=CNnzbNQgyzo)

>💡 AWS RDS와는 좀 다른 것 같다. RDS는 퍼블릭 엑세스를 허용하면 외부에서도 바로 접근이 가능한데 Cloud SQL은 public IP를 사용해도 authorization이 필요하여 Proxy나 authorized network를 사용해야 한다.

### 외부에서 연결

외부에서 연결하려면 `cloud_sql_proxy` 를 설치해서 쓰거나 authorized network를 설정해서 IP를 허용해줘야 한다.

![Untitled](Untitled%207.png)

```bash
$ ./cloud_sql_proxy -credential_file=/${HOME}/admingcpacnt.json -instances=project:asia-northeast3:test-replicate=tcp:3306 &
# 연결이 생성됨을 확인할 수 있다.
2022/03/31 15:33:25 Rlimits for file descriptors set to {Current = 8500, Max = 1048576}                                                           
2022/03/31 15:33:25 using credential file for authentication; email=admingcpacnt@project.iam.gserviceaccount.com
2022/03/31 15:33:26 Listening on 127.0.0.1:3306 for project:asia-northeast3:test-replicate
2022/03/31 15:33:26 Ready for new connections
2022/03/31 15:33:26 Generated RSA key in 182.999362ms
2022/03/31 15:35:00 New connection for "project:asia-northeast3:test-replicate"
2022/03/31 15:35:00 refreshing ephemeral certificate for instance project:asia-northeast3:test-replicate
2022/03/31 15:35:00 Scheduling refresh of ephemeral certificate in 54m59.22683158s
2022/03/31 15:35:00 Instance project:asia-northeast3:test-replicate closed connection
...
```

[About connection options | Cloud SQL for MySQL | Google Cloud](https://cloud.google.com/sql/docs/mysql/connect-external-app)

### [ How the Cloud SQL Auth proxy works ]

> The Cloud SQL Auth proxy works by having a local client running in the local environment. Your application communicates with the Cloud SQL Auth proxy with the standard database protocol used by your database.  
The Cloud SQL Auth proxy **uses a secure tunnel to communicate** with its companion process running on the server. Each connection established through the Cloud SQL Auth proxy creates one connection to the Cloud SQL instance.  
When an application connects to Cloud SQL Auth proxy, it checks whether an existing connection between it and the target Cloud SQL instance is available. **If a connection does not exist, it calls Cloud SQL Admin APIs to obtain an ephemeral SSL certificate and uses it to connect to Cloud SQL**. Ephemeral SSL certificates expire in approximately an hour. Cloud SQL Auth proxy refreshes these certificates before they expire.  
While the Cloud SQL Auth proxy can listen on any port, it creates outgoing or egress connections to your Cloud SQL instance only on port 3307. Because Cloud SQL Auth proxy calls APIs through the domain name `sqladmin.googleapis.com`, which does not have a fixed IP address, all egress TCP connections on port 443 must be allowed. If your client machine has an outbound firewall policy, make sure it allows outgoing connections to port 3307 on your Cloud SQL instance's IP.

![Untitled](Untitled%208.png)

[About the Cloud SQL Auth proxy | Cloud SQL for MySQL | Google Cloud](https://cloud.google.com/sql/docs/mysql/sql-proxy#authentication-options)

