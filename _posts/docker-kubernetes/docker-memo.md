---
title: "Docker BlahBlah"
category: "docker-kubernetes"
---

## [ 21.07.16 ] 도커 설치
```console
$ sudo apt update
$ sudo apt install apt-transport-https ca-certificates curl software-properties-common
$ curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
$ sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
$ sudo apt update
$ apt-cache policy docker-ce
'''
docker-ce:
  설치: (없음)
  후보: 5:20.10.7~3-0~ubuntu-bionic
  버전 테이블:
     5:20.10.7~3-0~ubuntu-bionic 500
        500 https://download.docker.com/linux/ubuntu bionic/stable amd64 Packages
     5:20.10.6~3-0~ubuntu-bionic 500
        500 https://download.docker.com/linux/ubuntu bionic/stable amd64 Packages
     5:20.10.5~3-0~ubuntu-bionic 500
```
실행 결과 위에서 `설치:(없음)`으로 출력된 것은 아직 도커가 설치되지 않았단 뜻. 아래처럼 도커를 설치한다. 
```sh
$ sudo apt install docker-ce # 도커 설치
$ sudo systemctl status docker # 도커 작동 확인
''' 
 docker.service - Docker Application Container Engine
     Loaded: loaded (/lib/systemd/system/docker.service; enabled; vendor preset: enabled)
     Active: active (running) since Fri 2021-07-16 16:51:43 KST; 1min 0s ago
TriggeredBy: ● docker.socket
       Docs: https://docs.docker.com
   Main PID: 21899 (dockerd)
      Tasks: 17
     Memory: 44.1M
     CGroup: /system.slice/docker.service
...
```
sudo로 docker를 실행해야 하므로 권한을 부여한다.
```console
$ sudo usermod -aG docker $USER
'''
-G: 새로운 그룹
-a: 다른 그룹에서 삭제 없이 G에 따른 사용자 추가
```
참고: https://blog.cosmosfarm.com/archives/248/%EC%9A%B0%EB%B6%84%ED%88%AC-18-04-%EB%8F%84%EC%BB%A4-docker-%EC%84%A4%EC%B9%98-%EB%B0%A9%EB%B2%95/


