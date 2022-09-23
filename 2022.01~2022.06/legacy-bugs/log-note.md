# BUG Note

### Couldn’t execute ‘SELECT COLUMN_NAME, JSON_EXTRACT(HISTOGRAM, ‘$.“number-of-buckets-specified”’) FROM information_schema.COLUMN_STATISTICS WHERE SCHEMA_NAME = ‘DB 이름’ AND TABLE_NAME = ‘테이블 이름‘;’: Unknown table ‘COLUMN_STATISTICS’ in information_schema (1109)

MySQL 8.0 부터 발생하는 오류로 옵션이 활성화되어 었으면 dump시 ANALYZE TABLE에 히스토리를 기록하는데 사용할 테이블이 없으면 발생한다.

```console
$ mysqldump --column-statistics=0 --host={host} --port={post} --user={user} --password={pwd} {DB schema} > {설치할 경로}/backup.sql
``` 
출처: https://jay-ji.tistory.com/62

### Segmentation Fault
Segfault라고도 하는데 프로그램이 동작 중 잘못된 주소를 참조할 때 발생한다.
- read-only 메모리 영역에 데이터를 쓰려고 하는 경우
- OS 메모리 영역 / 보호된 메모리 데이터를 쓰려고 하는 경우
- 잘못된 메모리 영역에 접근하는 경우

참고: https://doitnow-man.tistory.com/98

### 명령어 'docker-compose' 을(를) 찾을 수 없습니다.
docker 설치 이외에 추가로 설치를 해주어야한다.
```console
$ sudo curl -L https://github.com/docker/compose/releases/download/1.21.0/docker-compose-`uname -s`-`uname -m` | sudo tee /usr/local/bin/docker-compose > /dev/null
```
권한 부여 
```console
$ sudo chmod +x /usr/local/bin/docker-compose
```
symbolic link 생성
```console
$ sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
```
버전확인하여 설치되었음을 확인한다.
```console
$ docker-compose --version
docker-compose version 1.21.0, build 5920eb0
```

출처: https://somjang.tistory.com/entry/Docker-Amazon-Linux2-AMI-%EC%97%90%EC%84%9C-docker-compose-%EC%84%A4%EC%B9%98%ED%95%98%EA%B8%B0


### [ python-pandas ] TypeError: ufunc 'isnan' not supported for the input types, and the inputs could not be safely coerced to any supported types according to the casting rule ''safe''
```python
df[column1].apply(lambda x: np.isnan(x))
# df[column1] dtype : object
```
에서 발생한 오류

출처: https://stackoverflow.com/questions/36000993/numpy-isnan-fails-on-an-array-of-floats-from-pandas-dataframe-apply/36001292 
> np.isnan can be applied to NumPy arrays of native dtype (such as np.float64)

> Since you have Pandas, you could use pd.isnull instead -- it can accept NumPy arrays of object or native dtypes

`pd.isnull` 로 적용하여 해결


### [ python-psycopg2 ] OperationalError: (psycopg2.OperationalError) server closed the connection unexpectedly. This probably means the server terminated abnormally before or while processing the request.

### PC 프리징 현상
사내 윈도우 서버가 가끔 프리징되는 현상이 일어난다. 원인은 크게 소프트웨어 / 하드웨어의 문제일 수 있다고 한다. 소프트웨어 측면에서는 윈도우 OS상의 문제거나 메모리 과부하 또는 악성코드에 의한 현상 등이 있다. 하드웨어 측면에선 CPU 쿨러 고장 또는 메인 보드 고장 등 다양한 원인이 있을 수 있다. 일단 할 수 있는 것부터 접근하여 
1. 악성코드 검사 : C드라이브 악성코드 검사에서 오류 발견 없다고 나옴.
2. CPU 쿨러 검사 : Core Temp라는 프로그램 설치하여 CPU 온도 확인( 40~50도로 측정된 ). 심하게는 100도까지도 올라갈 수 있다는게 높은 온도는 아닌 것 같음. 
3. 절전모드 사용안함 : 저장장치가 절전모드에 진입하면 멈춤 현상이 나타날 수 있으므로 기본적인 PC 절전모드는 사용안함으로 설정함. 하드웨어와 관련된 절전모드도 해제함(https://itons.net/%EC%9C%88%EB%8F%84%EC%9A%B010-%ED%95%98%EB%93%9C%EB%94%94%EC%8A%A4%ED%81%AC-%EC%A0%88%EC%A0%84%EB%AA%A8%EB%93%9C-%EB%81%84%EA%B8%B0-%EB%94%9C%EB%A0%88%EC%9D%B4-%ED%98%84%EC%83%81-%ED%95%B4%EA%B2%B0/)

그외 https://texit.tistory.com/52 에 따르면, 
- 시작 프로그램 및 서비스 문제: 백신 프로그램 설치하여 자동으로 검사할 것
- 불필요한 가상 메모리 설정 : 기존 물리 메모리보다 엑세스 속도가 느리면 저장장치에 부담을 주어 멈춤현상이 발생할 수 있으므로 물리 메모리를 늘릴 것
- 불필요한 파일이나 레지스트리 문제 :  윈도우 자체 기능인 디스크 정리나 최적화 프로그램을 사용할 것
- 디스크 파일 문제 : 디스크 검사할 것
- 하드디스크 단편화 문제 : SSD의 경우 파일 단편화 문제가 없으나 HDD 하드디스크의 경우 오랫동안 포맷하지 않으면 파일이 단편화 현상이 발생할 수 있음. 
- 윈도우 업데이트 : 장시간 업데이트 안하면 멈춤 현상 발생할 수 있음


### [ logstash.conf ] 수정

```logstash.conf
input {
	tcp {
		port => 5000
		type => "server-log"
	}
}

filter {
    mutate {
        remove_field => ["@version", "@timestamp", "host", "path"]
    }
}

output {
    if [type] == "server-log" {
        elasticsearch {
            index => "server-log"
            hosts => ["http://elasticsearch:9200"]
            user => "elastic"
            password => "hello_world"
        }
    }
}
```
위와 같이 ["@version", "@timestamp", "host", "path"]를 제거하도록 설정해도 아래와 같이 반영되지 않음. json 파싱이 제대로 이루어지지 않는 것으로 보임.

```
        "_source" : {
          "message" : """{"@timestamp": "2021-10-12T10:43:10.379Z", "@version": "1", "message": "{'function': 'get_time_series_data', 'params': OrderedDict([('tickers', 'NASA100'), ('item', 'PI')]), 'msg': 'success', 'client': '127.0.0.1', 'timestamp': '2021-10-12 19:43:10.379770', 'level': 'info'}", "host": "engineeringcomputer", "path": "/home/leeyujin/QRAFT/datastream-soap-server/logger.py", "tags": [], "type": "logstash", "level": "INFO", "logger_name": "datastream-server", "stack_info": null}"""
        }
      }
```

### [ Postgresql ] psql: 오류: 치명적오류:  호스트 "...", 사용자 "postgres", 데이터베이스 "postgres", SSL 중지 연결에 대한 설정이 pg_hba.conf 파일에 없습니다.
`pg_hba.conf`에 

```
# IPv4 local connections:
..
host    all             all             0.0.0.0/0                 md5
```
추가하여 해결


### [ python-mysql 설치 ] OSError: mysql_config not found
`pip install mysqlclient`에서 오류 발생 
```console
$ sudo apt-get install libmysqlclient-dev
```
설치하여 해결

출처: https://samplenara.tistory.com/19


### [ mysql-docker ] sqlalchemy.exc.OperationalError: (MySQLdb._exceptions.OperationalError) (2002, "Can't connect to local MySQL server through socket '/var/run/mysqld/mysqld.sock' (2)")
```
Use "127.0.0.1", instead of "localhost"
```
출처: https://stackoverflow.com/questions/18150858/operationalerror-2002-cant-connect-to-local-mysql-server-through-socket-v

### [ airflow 실행 ] ModuleNotFoundError: No module named 'wtforms.compat'
`pip install apache-airflow` 이 후 `airflow db init`을 실행하여 DB를 초기화하는데 오류가 발생함
https://stackoverflow.com/questions/69879246/no-module-named-wtforms-compat에 따르면 wtforms version 이 python version과 안 맞는 것 같음.

`pip install "apache-airflow==2.2.1" --constraint "https://raw.githubusercontent.com/apache/airflow/constraints-2.2.1/constraints-3.8.txt"`로 [airflow 공식 문서](https://airflow.apache.org/docs/apache-airflow/stable/installation/installing-from-pypi.html) 에서 제공한대로 constraint 추가하여 해결


### [ jenkins-gitlab 연동 ] stdout: HTTP Basic: Access denied

`http://username:personal_access_token@gitlab.yatra.com/xxxxxxxxxxxxxxxxxx.git.` 로 설정

출처: https://gitlab.com/gitlab-org/gitlab-foss/-/issues/38910

### [ jenkins-gitlab hook 설치 오류 ] Failed to load: Gitlab Hook Plugin (1.4.2) - Plugin is missing: ruby-runtime (0.12)


### [ gitlab-runner - Dockfile 빌드 ] 
```
Runtime platform arch=amd64 os=linux pid=7 revision=4b9e985a version=14.4.0
```
wildcard로 wheel파일을 설치하려 했는데 `RUN`이 안 먹혀서 `CMD`로 작성하니 오류가 발생함

```Dockerfile
FROM gitlab/gitlab-runner:latest
RUN apt-get -y update
RUN apt-get -y install python3
RUN apt-get -y install python3-pip
COPY _requires/ /home/gitlab-runner/
COPY test_compustat/cache/ /tmp/cache/
CMD pip3 install *.whl
```

[StackOverflow](https://stackoverflow.com/questions/41428013/why-does-wildcard-for-jar-execution-not-work-in-docker-cmd)에 따르면 
`CMD`는 `/bin/sh`로 돌아가는데 리눅스에 파일이 없어서 안 돌아가는 것 같음.


### Amazon DocumentDB 엔드포인트에 Connect 수 없음
Amazon DocumentDB 에 연결하려고 할 때 표시될 수 있는 일반적인 오류 메시지 중 하나입니다.
```
connecting to: mongodb://docdb-2018-11-08-21-47-27.cluster-ccuszbx3pn5e.us-east-
1.docdb.amazonaws.com:27017/
2018-11-14T14:33:46.451-0800 W NETWORK [thread1] Failed to connect to
172.31.91.193:27017 after 5000ms milliseconds, giving up.
2018-11-14T14:33:46.452-0800 E QUERY [thread1] Error: couldn't connect to server
docdb-2018-11-08-21-47-27.cluster-ccuszbx3pn5e.us-east-1.docdb.amazonaws.com:27017,
connection attempt failed :
connect@src/mongo/shell/mongo.js:237:13
@(connect):1:6
exception: connect failed

```
> 퍼블릭 엔드포인트로부터 연결하는 경우 : 노트북 또는 로컬 개발 머신에서 직접 Amazon DocumentDB 클러스터에 연결하려고 합니다. 노트북 또는 로컬 개발 시스템과 같은 퍼블릭 엔드포인트에서 직접 Amazon DocumentDB 클러스터에 연결하려는 시도는 실패합니다. Amazon DocumentDB 는 가상 사설 클라우드 (VPC) 전용이며 현재 퍼블릭 엔드포인트를 지원하지 않습니다. 따라서 VPC 외부의 노트북 또는 개발 환경에서 Amazon DocumentDB 클러스터에 직접 연결할 수 없습니다. Amazon VPC 외부에서 Amazon DocumentDB 클러스터에 연결하려면 SSH 터널을 사용할 수 있습니다. 자세한 내용은 Amazon VPC 외부에서 Amazon DocumentDB 클러스터에 연결 단원을 참조하세요. 또한, 개발 환경이 다른 Amazon VPC에 있을 경우에는 VPC 피어링을 사용하여 동일한 리전 또는 다른 리전의 다른 Amazon VPC에서 Amazon DocumentDB 클러스터에 연결할 수 있습니다.

### Ubuntu won't load after clearing orphaned inode
우분투 부팅시 
```
/dev/sdb5: recovering journal

Clearing orphaned inode 1180978 (uid=1000, gid=1000, mode=0100600, size=0)
... 
```
*(출처) https://greenfishblog.tistory.com/176*

위와 같은 메시지와 함께 부팅이 진행되지 않음.다시 시작하여  Ubuntu 고급설정으로 들어가 recovery mode로 실행함.


![](https://www.howtogeek.com/wp-content/uploads/2014/09/ubuntu-recovery-menu.png?trim=1,1&bg-color=000&pad=1,1)

위의 항목을 하나씩 실행하여 검사함.

*(출처 및 참고)https://www.howtogeek.com/196740/how-to-fix-an-ubuntu-system-when-it-wont-boot/*

모두 오류없이 실행되어 `system-summary`에서 현재 상태를 확인함.
확인하니 하드디스크가 100%여서 부팅되지 않은 것으로 보여 `root`를 통해 command로 폴더를 지워줌.

재부팅하니 정상 작동함.


### AWS Lambda OSError: [Errno 30] Read-only file system: './cache'
`/tmp`에서만 write이 가능하다고 함

### 우분투에서 mysqlclient 설치 시 에러가 발생 - egg_info 관련 에러
```
Command "python setup.py egg_info" failed with error code 1 in /tmp/pip-install-zbw18e9_/mysqlclient/
```
`sudo apt-get install libmysqlclient-dev`로 해결

### Rust 자동 설치
*Add option for automatic installation*

```console
$ curl https://sh.rustup.rs -sSf | sh -s -- -y
```    
- `sh -s`는 sh의 stdin을 실행한다.
```console
    -s stdin         Read commands from standard input (set automatically if no file arguments are present).  This option has no effect when set after the shell has already started running (i.e. with set).

```
- `--`는 다음 나올 arguments가 options이 아님을 표시해준다.
```console
    set [{ -options | +options | -- }] arg ...
                The set command performs three different functions.

                With no arguments, it lists the values of all shell variables.

                If options are given, it sets the specified option flags, or clears them as described in the section called Argument List Processing.  As a special case, if the option is -o or +o and no argument is supplied, the shell prints the settings of all its options.  If the option
                is -o, the settings are printed in a human-readable format; if the option is +o, the settings are printed in a format suitable for reinput to the shell to affect the same option settings.

                The third use of the set command is to set the values of the shell's positional parameters to the specified args.  To change the positional parameters without changing any options, use “--” as the first argument to set.  If no args are present, the set command will clear
                all the positional parameters (equivalent to executing “shift $#”.)
```

### sudo apt-get update 시 NO_PUBKEY 에러나는 문제

```console
$ sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys <PUBKEY>
$ sudo apt-get update
```

*(출처) https://eehoeskrap.tistory.com/454*

### Python 3.8 이하인 경우의 문법 오류
아래와 같인 대입 표현식은 변수에 값을 대입하는 기능으로 python 3.8에서 새롭게 추가된 것이다.( 그 이하 버전에서는 오류남)
```
if (n := len(a)) > 10: 
  File "<stdin>", line 1
    if (n := len(a)) > 10:
          ^
SyntaxError: invalid syntax
```

*(출처) https://docs.python.org/ko/3/whatsnew/3.8.html*

### permission denied when using DockerOperator in Airflow
```
  File "/home/airflow/.local/lib/python3.8/site-packages/docker/transport/unixconn.py", line 43, in connect
    sock.connect(self.unix_socket)
PermissionError: [Errno 13] Permission denied
```

아래와 같이 airflow에서 DockerOperator 위주로 적용할 때 오류가 발생한다.
```python
DockerOperator(
    docker_url='unix://var/run/docker.sock',
    ...
)
```
1. 바운드하려는 `/var/run/docker.sock`의 권한을 바꾸거나 
2. 해당 파일을 TCP로 통신이 가능하도록 wrapping한다.

```
docker run -d -v /var/run/docker.sock:/var/run/docker.sock -p 127.0.0.1:1234:1234 bobrik/socat TCP-LISTEN:1234,fork UNIX-CONNECT:/var/run/docker.sock
export DOCKER_HOST=tcp://localhost:1234
```
`Dockerfile`에서는 아래와 같이
```yaml
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
```
을 추가하여 연동시킨다.

*(출처) https://onedevblog.com/how-to-fix-a-permission-denied-when-using-dockeroperator-in-airflow/*

### `apt-get: command not found` in AWS python docker image 
OS가 centOS이기에 `apt-get` 대신 `yum`을 사용해야 

*(출처) https://www.reddit.com/r/aws/comments/mu3jtf/working_with_aws_lambda_python_from_docker_images/*  


### docker error in crontab: `the input device is not a TTY`
`docker run --rm -it -v`와 같이 docker 실행을 포함한 shell script를 작성하여 crontab으로 예약 실행하면 오류가 발생한다.
`-i`만 부여해서 적용한다.