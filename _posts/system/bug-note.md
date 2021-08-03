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

