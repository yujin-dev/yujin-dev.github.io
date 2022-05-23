# Google Practitioners Guide to MLOps

[https://services.google.com/fh/files/misc/practitioners_guide_to_mlops_whitepaper.pdf](https://services.google.com/fh/files/misc/practitioners_guide_to_mlops_whitepaper.pdf)

ML system을 빌드하고 운영하는데 필요한 관점에서 scale, automate에 관해 살펴본다. 

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

**Experimentation**

• Provide notebook environments that are integrated with version control tools like Git.
• Track experiments, including information about the data, hyperparameters, and evaluation metrics for reproducibility and comparison.
• Analyze and visualize data and models.
• Support exploring datasets, finding experiments, and reviewing implementations.
• Integrate with other data services and ML services in your platform.

**Data processing**
• Support interactive execution (for example, from notebooks) for quick experimentation and for long-running jobs in production.
• Provide data connectors to a wide range of data sources and services, as well as data encoders and decoders for various data structures and formats.
• Provide both rich and efficient data transformations and ML feature engineering for structured (tabular) and unstructured data (text, image, and so on).
• Support scalable batch and stream data processing for ML training and serving workloads.

**Model training**
• Support common ML frameworks and support custom runtime environments.
• Support large-scale distributed training with different strategies for multiple GPUs and multiple workers.
• Enable on-demand use of ML accelerators.
• Allow efficient hyperparameter tuning and target optimization at scale.
• Ideally, provide built-in automated ML (AutoML) functionality, including automated feature selection and engineering as well as automated model architecture search and selection.

**Model evaluation**
• Perform batch scoring of your models on evaluation datasets at scale.
• Compute pre-defined or custom evaluation metrics for your model on different slices of the data.
• Track trained-model predictive performance across different continuous-training executions.
• Visualize and compare performances of different models.
• Provide tools for what-if analysis and for identifying bias and fairness issues.
• Enable model behavior interpretation using various explainable AI techniques.

**Model serving**
• Provide support for low-latency, near-real-time (online) prediction and high-throughput batch (offline) prediction.
• Provide built-in support for common ML serving frameworks (for example, TensorFlow Serving, TorchServe, Nvidia Triton, and others for Scikit-learn and XGBoost models) and for custom runtime environments.
• Enable composite prediction routines, where multiple models are invoked hierarchically or simultaneously before the results are aggregated, in addition to any required pre- or post-processing routines.
• Allow efficient use of ML inference accelerators with autoscaling to match spiky workloads and to balance cost with latency.
• Support model explainability using techniques like feature attributions for a given model prediction.
• Support logging of prediction serving requests and responses for analysis.

**Online experimentation**
• Support canary and shadow deployments.
• Support traffic splitting and A/B tests.
• Support multi-armed bandit (MAB) tests.

**Model monitoring**
• Measure model efficiency metrics like latency and serving-resource utilization.
• Detect data skews, including schema anomalies and data and concept shifts and drifts.
• Integrate monitoring with the model evaluation capability for continuously assessing the effectiveness performance of the deployed model when ground truth labels are available.

**ML pipelines**
• Trigger pipelines on demand, on a schedule, or in response to specified events.
• Enable local interactive execution for debugging during ML development.
• Integrate with the ML metadata tracking capability to capture pipeline execution parameters and to produce artifacts.
• Provide a set of built-in components for common ML tasks and also allow custom components.
• Run on different environments, including local machines and scalable cloud platforms.
• Optionally, provide GUI-based tools for designing and building pipelines.

**Model registry**
• Register, organize, track, and version your trained and deployed ML models.
• Store model metadata and runtime dependencies for deployability.
• Maintain model documentation and reporting—for example, using model cards.
• Integrate with the model evaluation and deployment capability and track online and offline evaluation metrics for the models.
• Govern the model launching process: review, approve, release, and roll back. These decisions are based on a number of offline performance and fairness metrics and on online experimentation results.

**Dataset and feature repository**
• Enable shareability, discoverability, reusability, and versioning of data assets.
• Allow real-time ingestion and low-latency serving for event streaming and online prediction workloads.
• Allow high-throughput batch ingestion and serving for extract, transform, load (ETL) processes and model training, and for scoring workloads.
• Enable feature versioning for point-in-time queries.
• Support various data modalities, including tabular data, images, and text.

**ML metadata and artifact tracking**
• Provide traceability and lineage tracking of ML artifacts.
• Share and track experimentation and pipeline parameter configurations.
• Store, access, investigate, visualize, download, and archive ML artifacts.
• Integrate with all other MLOps capabilities.

### Data & Model Management

![Untitled](Google%20Pra%20e4c48/Untitled%204.png)

**Feature Management** 

• Discover and reuse available feature sets for their entities instead of re-creating the entities in order to create their own datasets.
• Establish a central definition of features.
• Avoid training-serving skew by using the feature repository as the data source for experimentation, continuous training, and online serving.
• Serve up-to-date feature values from the feature repository.
• Provide a way of defining and sharing new entities and features.
• Improve collaboration between data science and research teams by sharing features.

**Dataset management**
• Maintaining scripts for creating datasets and splits so that datasets can be created in different environments(development, test, production, and so on).
• Maintaining a single dataset definition and realization within the team to use in various model implementations and hyperparameters. This dataset includes splits (training, evaluation, test, and so on) and filtering
conditions.
• Maintaining metadata and annotation that can be useful for team members who are collaborating on the same dataset and task.
• Providing reproducibility and lineage tracking.