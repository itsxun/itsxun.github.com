---
layout: post
title: PGSQL(1)-pgsql的执行计划入门
author: itsxun
date: 2018-06-16 21:55:21 +0800
catalog: true
tags:
    - 数据库
---
# 前言：pgsql的sql执行过程
1. 解析器对语法分析，根据sql语句生成所有可能的执行路径
2. 优化器接收所有的执行路径，并且计算出每一条路径获取结果集所花费的代价，最终选择一个最小的路径，制作成一个完整的规划树，传递给执行器
3. 执行器实施具体路径，获取结果集
4. 存储器可能还会对结果进行其他操作，更新缓存之类的。

# 语法
```sql
explain [option] statement;
```

其中，option有以下常用的选项
- analyze
  - 这个参数用于通过实际执行statement来获取更精确的执行计划，因为会实际执行，所以可以放在事物中rolleback取消执行效果。如果不加上的话，结果可能没那么准确，但是一般来说不加上也够用。
  ```sql
  begin;
    explain analyze balabala;
  rollback;
  ```
- verbose
  - 用于显示附加信息，such as 计划树中每个节点输出的各个列，如果触发器被触发，会输出触发器名称。默认false.
- cost
  - cost会显示每个节点的启动成本，总成本，估计行数和每行宽度，默认为true
- buffers
  - 只能与analyze参数一起使用，显示关于缓冲区的信息。比如会告诉你查询的数据块的数量，修改的数据块的数量。
- format
  -可以指定输出的格式，默认是TEXT,可以以json，xml格式输出。

# 输出结果解释

```sql
explain select * from test_table;

-- QUERY PLAN

Seq scan on test_table (cost=0.00..3.55 rows=55 width=315)
```

***解释：***

seq scan 指的是全表扫描，就是从头到尾顺序扫描表一次，后面括号中分为三部分

cost中的0.00指的是sql到返回第一行花费的成本，包括语法解析等

3.55指的是返回所有的数据所花费的成本

row=55表示会返回55行

width表示每行平均宽度为36字节

> cost的计算方法：

- 顺序扫描一个数据块，cost为1
- 随机扫描一个数据块，cost为4
- 处理一个数据行的CPU，cost为0.01
- 处理一个索引行的CPU，cost为0.05
- 每个操作符的CPU代价，cost为0.0025

buffers
```sql
explain (analyze true, buffers true) select * from test_table;

-- QUERY PLAN

Seq scan on test_table (cost=0.00..3.55 rows=55 width=315) (actual time=0.006..0.037 rows=56 loops=1)
  Buffers: share hit=3 read = 1 written = 1
plan time : 0.067
Execution time : 0.063
```

hits表示在共享内存中直接读到了3个块，read表示从磁盘中读了1个块，written表示写磁盘一共1块
。因为共享内存中有脏数据，所以即使是查询，也会有写操作。


limit
```sql
explain create table test_table as select * from teablea limit 10000;

-- QUERY PLAN

Limit (cost=0.00..3127.6 rows=10000 width=126)
  -> Seq scan on teablea (cost=0.00..312766.02 rows=1000002 width=126)

-- limit导致在rows减少的同时，cost也显著减少了。
```

# 扫描方式

1. Seq scan 全表扫描

2. index scan , index only scan 索引扫描。

3. bitmap index scan, 位图扫描。
也是索引扫描的一种，会扫描索引，把满足条件的行或者块在内存中建一个位图，扫描完索引后，再根据位图到表的数据文件中把相应的数据读出来。如果走了两个索引，两个索引形成的位图还会进行and or 操作，合并成一个位图，再去查找数据。

```sql
explain select * from test_table where id2 > 100 or id1 < 0;

-- QUERY PLAN

bitmap heap scan on test_table (cost=20854.46..41280.46 rows=998446 width=16)
  Recheck Cond:((id2 > 100) OR (id1 < 0))
  -> BitMapOr (cost=20854.46..20854.46 rows=100100 width=0) -- or 操作
     -> BitMap Index Scan on idx_test_id2 (costs=0.00..18458.59 rows=998155 width=0)
        Index Cond: (id2 > 100)
     -> BitMap Index Scan on idx_test_id1 (costs=0.00..1896.35 rows=102430 width=0)
        Index Cond: (id1 > 100)
```
BitMapOr 表示or操作合并了两个位图
