---
title: "Postgresql documentation 살펴보기 - Transactions "
category: "db"
---

PostgreSQL 공식문서에서 정의하는 transactions 개념을 살펴보기로 한다.

*Transactions*은 operation의 여러 단계를 하나로 묶은 개념이다. transactions를 수행하는 과정에서 여러 단계를 거치는데 이 중 하나가 실패해도 DB에는 영향을 미치지 않는다.

[ 예시 ]
여러 소비자 계좌를 포함하는 bank DB가 있다고 하자. **Alice의 계좌에서 Bob의 계좌로 $100.00 입금**을 기록하려는 SQL commands는 아래와 같을 것이다. 
```sql
UPDATE accounts SET balance = balance - 100.00 WHERE name = 'Alice';
UPDATE branches SET balance = balance - 100.00 WHERE name = (
    SELECT branch_name FROM accounts WHERE name = 'Alice' 
);
UPDATE accounts SET balance = balance + 100.00 WHERE name = 'Bob';
UPDATE branches SET balance = balance + 100.00 WHREE  name = (
    SELECT branch_name FROM accounts WHERE name = 'Bob' 
)
```
해당 task를 수행하는데 여러 `UPDATE`가 실행되는데 bank 입장에서는 전부 다 실행되거나 아예 발생하지 않아야 한다. 하나라도 잘못되면 전체 step이 실행되지 않아야 하므로 이를 grouping하여 업데이트한다.(*transaction*) 이는 DB의 특징 중 하나인 *atomic*(원자성)을 보장한다. 

또한 transaction이 끝나면 정보가 완전히 기록되어 유실되지 않길 바란다. 따라서 transaction에 의한 정보는 permanent 저장소( disk )에 로그로 남는다.
 
만일 여러 transactions을 병렬로 실행할 때 각각은 서로의 완료되지 않은 변화를 확인할 수 없다. 
transactions은 한마디로 all-or-nothing 어이야 한다.

PostgreSQL에서 transactions는 `BEGIN`과 `COMMIT`으로 wrapping된다. 이를 *transaction block*이라고도 부른다.

```sql
BEGIN;
UPDATE accounts SET balance = balance - 100.00 WHERE name = 'Alice';
-- ... 위와 동일
COMMIT;
```

transaction 마지막에 `COMMIT` 대신 `ROLLBACK`으로 모든 `UPDATE`를 취소할 수 있다. 

중간에 `SAVEPOINT`를 지정하여 롤백이 필요하면 해당 지점으로 `ROLLBACK TO`를 실행 가능하다.(일종의 checkpoint) 
```sql
BEGIN;
UPDATE accounts SET balance = balance - 100.00 WHERE name = 'Alice';
SAVEPOINT my_savepoint;
UPDATE accounts SET balance = balance + 100.00 WHERE name = 'Bob';
-- Wally 의 계좌였음을 잊어버림..!
ROLLBACK TO my_savepoint;
UPDATE accounts SET balance = balance + 100.00 WHERE name = 'Wally';
COMMIT;
```