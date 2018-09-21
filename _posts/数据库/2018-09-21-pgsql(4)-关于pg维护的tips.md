---
layout: post
title: PGSQL(4)-关于PG维护的Tips
author: itsxun
date: 2018-09-21 11:25:08 +0800
catalog: true
tags:
    - 数据库
---

## 思路

PGSQL的日常维护中，一般来说，有以下步骤：

1. analyze：搜集信息

2. vacuum：清理无效数据

3. reindex：索引重建

### analyze

当表中的增加或者更新了大量列的时候，立即运行analyze可以保证让规划器得到基于该表的最新的统计数据，便于规划器选择更好的执行计划。

>语法

```sql
analyze [verbose] [table_name] [column_name1,column_name2];
```
verbose：可选，表示是否显示执行进度。

不加表名代表analyze整个库，不加列名代表analyze整张表。

### vacuum

之前的文章有提到过，由于pgsql的mvcc策略，不会有记录会被实际删除，因此导致表实际上会也越来越大。而vacuum，就是用来解决这个问题的。

> 语法

```sql
VACUUM [FULL | VERBOSE | ANALYZE ] [ table_name [ (column_name1,column_name2) ] ]
```

vacuum会将表中处于删除状态的空间重新置为可重复利用状态，但是释放出来的空间不进行合并，因此，整张表的水位线并不会降低。

FULL：可选，特别小心这个选项，它会lock住表，同时梳理整张表，将所有能释放的空间全部释放，然后有效记录会往前移动，进行空间合并。水位线会降低。

analyze: 可选，更新表的统计信息，便于规划器选择更好的执行计划

### reindex

使用 REINDEX 有以下原因：

1. 索引崩溃，并且不再包含有效的数据。尽管理论上这是不可能发生的，但实际上索引会因为软件毛病或者硬件问题而崩溃。REINDEX 提供了一个恢复方法。
2. 索引变得"臃肿"，包含大量的空页或接近空页。
3. 为索引更改了存储参数(例如填充因子)，并且希望这个更改完全生效。
4. 使用 CONCURRENTLY 选项创建索引失败，留下了一个"非法"索引。可以通过 REINDEX 重建新索引来覆盖。注意，REINDEX 不能并发创建。要在生产环境中重建索引并且尽可能减小对尖峰负载的影响，可以先删除旧索引，然后使用 CREATE INDEX CONCURRENTLY 命令重建新索引。

> 语法

```SQL
  REINDEX [VERBOSE] { INDEX | TABLE | SCHEMA | DATABASE | SYSTEM } index_name;
```

## 一些Tips

### 索引上可以用函数

如果说sql中对某一个列的查询用到了函数，可以直接将函数应用在列上，比如：

```SQL
SELECT * FROM table WHERE substr(col1::text, 1, 1)='1' AND col2 =1 AND date_part('year'::text, col3)=2018;

-- 建立如下索引：

CREATE INDEX test_index
ON table
( substr(col1::text, 1, 1) ,  col2 , date_part('year'::text, col3) );
```

## 结语

暂时没想到其他的有意思的知识点，缓慢更新中。
