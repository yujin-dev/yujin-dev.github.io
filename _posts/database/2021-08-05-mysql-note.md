---
title: "MySQL BlahBlah"
category: "db"
---


## [ 21.07.22 ] 도커로 설치
1. MySQL 도커 이미지를 다운받는다. 뒤에 버전 명시(mysql:8.0.22) 를 안하면 자동으로 최신 버전을 가져온다. 
```console
$ docker pull mysql
Using default tag: latest
latest: Pulling from library/mysql
b4d181a07f80: Already exists 
a462b60610f5: Pull complete 
578fafb77ab8: Pull complete 
524046006037: Pull complete
```
2. docker 이미지를 확인하다.
```console
$ docker images
```
3. MySQL docker 컨테이너를 생성하여 실행한다.
```console
$ docker run --name mysql -e MYSQL_ROOT_PASSWORD={passsword} -d -p 3306:3306 mysql:latest
```
4. MySQL docker 컨테이너 시작/중지/재시작
```console
$ docker start mysql
$ docker stop mysql
$ docker restart mysql
```
5. MySQL docker 컨테이너 진입( 접속 )
```console
$ docker exec -it mysql bash
```

## [ 21.07.22 ] dump 
```console
$ mysqldump --host={host} --port={post} --user={user} --password={pwd} {DB schema} > {설치할 경로}/backup.sql
``` 

주기적으로 백업 : https://backkom-blog.tistory.com/entry/Docker-Mysql-Server-%EC%A3%BC%EA%B8%B0%EC%A0%81%EC%9C%BC%EB%A1%9C-%EB%B0%B1%EC%97%85%ED%95%98%EA%B8%B0crontab-%ED%99%9C%EC%9A%A9%ED%95%98%EA%B8%B0