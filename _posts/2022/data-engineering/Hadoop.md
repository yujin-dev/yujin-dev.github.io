## HDFS
HDFS(Hadoop Distributed FileSystem)은 데이터를 분산 저장하는 파일 시스템이다. 실시간 처리보다는 배치 처리에 적합하다.

- HDFS는 데이터를 블록 단위로 나누어 저장한다. 
- fault-tolerant를 위해 블록을 복제하여 중복 저장한다.
- 읽기 작업을 위해 설계되어 있어 파일 수정이 지원되지 않느다.

HDFS는 Master-Slave 구조로, Master의 주도 하에 Slave 노드를 제어하여 데이터를 분산 저장한다. 하나의 NameNode와 여러 개의 DataNode로 구성되어 있다. NameNode에는 메타데이터를 관리하고, 실제 데이터는 DataNode에 저장된다. 
- NameNode : 각 DataNode의 메타데이터를 받아 전체 노드의 메타데이터와 파일 정보를 묶어서 관리한다. 데이터를 저장할시 블록을 어떤 DataNode에 저장할지 정한다. DataNode와 3초마다 heartbeat를 주고 받아 health check를 한다. 
- DataNode : 실제 데이터가 저장되는 곳이며, 주기적으로 heartbeat와 blockreport를 전달한다. 

![](https://img1.daumcdn.net/thumb/R1280x0/?scode=mtistory2&fname=https%3A%2F%2Fblog.kakaocdn.net%2Fdn%2FbImaWN%2Fbtq3lTxXT91%2FVxMDqf2h8OR1ATwcHLgzG0%2Fimg.png)

## MapReduce
분산처리가 가능한 시스템에서 분산 저장된 데이터를 병렬로 처리하게 한다. 대용량 데이터 처리에 적합하며 특정 데이터를 갖고 있는 DataNode만 분석하여 결과를 취합한다. 

---
출처  
[하둡(Hadoop) 기초 정리](https://han-py.tistory.com/361)