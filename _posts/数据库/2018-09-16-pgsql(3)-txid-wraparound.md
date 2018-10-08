---
layout: post
title: PGSQL(3)-txid-wraparound
author: itsxun
date: 2018-09-16 21:30:59 +0800
catalog: true
tags:
    - 数据库
---

## 前言

在PGSQL中，事务ID长度为32位，并且不建议再长，因为可能会大量占用空间。一个有符号的32位数字能产生超过十亿个不同的会话ID。但是会话ID如果继续增长，会突然变回到之前的会话ID，于是产生了冲突。下面是pgsql中实现解决的大致方式。

## Tips:几个特殊的txid

1. txid = 0: 表示 Invalid txid，通常作为判断txid的有效性使用；
2. txid = 1: 表示 Bootstrap txid，目前情况下，只在intidb的时候，初始化数据库的时候使用
3. txid = 2: 表示 Frozen txid，一般是在Vacuum时使用(在后面会提到)。

## 具体讨论和细节

txid的维护中vacuum起了很大的作用。
clog, 全程commit log, 事务的提交信息会存在这个里面。
如果事务越来越多，clog文件会变得越来越大，clog的查询也会变得越来越低效，vacuum会去清理clog。

当会话的txid变得足够老的时候，vacuum会直接将该事务的txid换成一个特殊的txid，称为FrozenXID。

这个ID特殊在，他对比所有的其他的会话ID，系统都会判定它是更旧的会话。所以他们最终会被vacuum清理掉。

默认产生了2亿的会话ID后，vacuumn就会开始执行这个操作，虽然说这时候离id的耗完还早着。
原因是：这个参数非常影响clog的文件大小。如果这个值设置为2亿，clog文件会占用50M的磁盘，但是如果设置到最大值，会占用到500M。如果有比较大的表，并且磁盘空间充裕，指可以调大，降低vacuum的频率。

但是调大会有隐患，如果长时间没有触发vacuum，当它终于被触发时，可能会需要更长的时间。频率更短的vacuum才会产生更短的更小的disruption。

一般来说，有一种情况会建议调小该值：当有大批量的数据导入库后。
调小会增加数据丢失的可能性，当事务并未提交，但是会话ID被vacuum强制替换成FrozenXid后，修改的数据全部丢失。

## 结语

这块其实看的不是很懂，可能会有坑，仅供参考！
