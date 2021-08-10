---
title: "Window 성능 모니터"
category: "system"
---

## 성능 모니터 기록하기
- https://nogan.tistory.com/17
- https://sagittariusof85s.tistory.com/82


## 주요 성능 카운터 
- https://tshooter.tistory.com/93
- https://www.nextstep.co.kr/121

현재 기록중인 카운터는 
Memory 
- Memory: Commited Bytes( 서버에서 실행 중인 프로세스의 메모리 사용량 ) 
- Memory:Pages/sec( 페이지가 디스크에서 물리 메모리로 쓰여지거나 디스크로 페이지를 옮겨 쓰는 속도 )
- Paging File: %Usage( 현재 사용중인 페이징 파일의 % )
Disk
- Physcial Disk: %Disk Time( 디스크가 읽고 쓰는 요청 )
- Process: Private Bytes( 가상 메모리의 크기 ) 
Network
- Server:Bytes Total/sec( 서버가 네트워크 데이터를 송수신하는 속도 )
- Network Interface: Bytes Total/sec( 네트워크 카드가 데이터를 송수신하는 속도 )
Postgres
- Process: Working Set( 프로세스가 데이터를 저장하기 위해 사용하는 RAM 사용량 측정 )  