---
title: "systems-bug"
category: "system"
---

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


### TypeError: ufunc 'isnan' not supported for the input types, and the inputs could not be safely coerced to any supported types according to the casting rule ''safe''
```python
df[column1].apply(lambda x: np.isnan(x))
# df[column1] dtype : object
```
에서 발생한 오류

출처: https://stackoverflow.com/questions/36000993/numpy-isnan-fails-on-an-array-of-floats-from-pandas-dataframe-apply/36001292 
> np.isnan can be applied to NumPy arrays of native dtype (such as np.float64)

> Since you have Pandas, you could use pd.isnull instead -- it can accept NumPy arrays of object or native dtypes

`pd.isnull` 로 적용하여 해결


### OperationalError: (psycopg2.OperationalError) server closed the connection unexpectedly. This probably means the server terminated abnormally before or while processing the request.

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
