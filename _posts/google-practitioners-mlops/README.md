---
title: "Google Practitioners Guide to MLOps"
category: "mlops"
---

[https://services.google.com/fh/files/misc/practitioners_guide_to_mlops_whitepaper.pdf](https://services.google.com/fh/files/misc/practitioners_guide_to_mlops_whitepaper.pdf)를 참고하여 대략적으로 정리하였다.

우선적으로, ML system을 빌드하고 운영하는데 필요한 관점에서 scale, automate에 관해 살펴본다. 

## 머신러닝의 지속적 배포 및 자동화 파이프라인
ML 적용하기 위한 요소는 다음과 같다.
- 대규모 데이터세트
- 저렴한 주문형 컴퓨터 리소스
- 여러 클라우드 플랫폼의 ML 전문 가속기
- ML 연구 분야

실질적으로는 ML모델을 빌드하지 않고 프로덕션 단계에서 지속적인 통합 시스템을 운영하기 위해 빌드한다.

### DevOps와의 차이점
기본적으로 MLOps는 아래의 특징이 있다.
- 팀 기술 : 일반적으로 ML 연구가 포함됨
- 개발 : 실험적으로 알고리즘, 모델링, 매개변수 등 여러 시도가 필요함
- 테스트 : 일반적인 통합 테스트 외에 데이터 검증, 학습된 모델 품질 평가, 모델 검증 등이 필요함
- 배포 : 오프라인 학습 이외에 ML 시스템을 사용하면 모델을 자동으로 재학습시키고 배포하기 위한 다단계 파이프라인 배포가 필요함
- 프로덕션 : 진화하는 데이터 세트에 따라 성능이 저하될 수 있어 온라인 성능을 모니터링할 수 있어야 함

코드 및 구성 요소 뿐 아니라 데이터, 모델도 테스트하고 검증해야 한다.

### ML 모델의 프로덕션 단계
1. 데이터 추출 : 다양한 데이터 소스에서 관련 데이터를 선택하여 통합
2. 데이터 분석 : ML 모델을 빌드하기 위한 EDA 수행
3. 데이터 준비 : ML 모델을 돌리기 위한 데이터 준비
4. 모델 학습 
5. 모델 평가
6. 모델 검증
7. 모델 배포 
8. 모델 모니터링

#### 수동 프로세스
![](https://cloud.google.com/architecture/images/mlops-continuous-delivery-and-automation-pipelines-in-machine-learning-2-manual-ml.svg)

- 모든 단계가 수동으로 실행되어 CI/CD가 없다.
- ML 시스템을 배포하는 대신 예측 서비스로 학습된 모델을 배포한다.
- 추적 및 로깅이 따로 이루어지지 않는다.

#### ML 파이프라인 자동화
![](https://cloud.google.com/architecture/images/mlops-continuous-delivery-and-automation-pipelines-in-machine-learning-3-ml-automation-ct.svg)

- ML 파이프라인을 자동화하여 모델을 지속적으로 학습시킨다.
- 구성 요소를 재사용, 구성, 공유가 가능해야 하므로 모듈화가 필요하다.

#### CI/CD 파이프라인 자동화
![](https://cloud.google.com/architecture/images/mlops-continuous-delivery-and-automation-pipelines-in-machine-learning-4-ml-automation-ci-cd.svg)

- 파이프라인을 빠르고 안정적이게 업데이트학 위한 자동화된 CI/CD 시스템을 사용한다.

*(출처) https://cloud.google.com/architecture/mlops-continuous-delivery-and-automation-pipelines-in-machine-learning#mlops_level_1_ml_pipeline_automation*

## 데이터 분석 및 머신러닝을 위한 파이프라인 빌드 - 예시
*(참고) https://cloud.google.com/architecture/building-and-orchestrating-data-analytics-and-machine-learning-pipeline?skip_cache=false*

## Kubeflow
kubernetes 위에서 돌아가는 오픈 소스들을 가져다 붙여 쓸 수 있는 확장형 ML 플랫폼이다.

## Building ML-enable System

ML-enabled system을 구축은 데이터 엔지니어링, ML 엔지니어링, appliction 엔지니어링의 결합으로 구성된다. 

![Untitled](Google%20Pra%20e4c48/Untitled.png)

## MLOps lifecycle

![Untitled](Google%20Pra%20e4c48/Untitled%201.png)

- ML Development : training pipeline을 구축
- Training operationalization : 구축한 training pipeline의 패키징, 테스트, 배포의 자동화
- Continuous training : 새로운 데이터나 수정된 코드에 따라 training pipeline을 실행
- Prediction serving : inference을 위한 model 프로덕션
- Continuous monitoring : 배포된 model의 효율성 모니터링
- Data and model management : ML 관련 dataset, artifacts을 총괄

![End-to-End Workflow](Google%20Pra%20e4c48/Untitled%202.png)

End-to-End Workflow

## MLOps Capabilities

하나의 통합된 ML system을 통해 Capabilities가 발현된다. (보통의 경우 프로세스들은 한번에 배포되기보다 단계별로 거쳐서 배포된다. )

![Untitled](Google%20Pra%20e4c48/Untitled%203.png)

*Infrastructure*는 확장 가능한 컴퓨팅 가능한 인프라를 확보와 관련해서 클라우드나 온프레미스에서 운영될 수 있다. *Source, artifact repositories & CI/CD*는 표준화된 configuration, CI/CD 관리와 관련된다. 

이러한 기반 위에서 *experimentation, data processing, model training, model evaluation, model serving, online experimentation, model monitoring, ML pipeline, model registry*이 있다. *ML metadata & artifact repository, Dataset & feature repository*를 통해 통합적으로  운영이 가능한다. 