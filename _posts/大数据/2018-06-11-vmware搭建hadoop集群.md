---
layout: post
title: vmware搭建hadoop集群
author: itsxun
date: 2018-06-11 22:51:33 +0800
catalog: true
tags:
    - 大数据
---

## 准备工作

vmware -> 编辑 -> 虚拟网络编辑器 -> 选择VMnet8 -> 右下角更改设置 -> 选择VMnet8 -> net设置

*** 记下网关 ***（我的是192.168.80.2）


## 进入centos

### 防火墙
min版本的linux也有防火墙的，免的麻烦，都关了吧，记得开机禁用。

### 关闭selinux

```shell
vim /etc/selinux/config
```
修改成这样:
```shell
SELINUX=disabled
```

### 固化IP，方便xshell连接
```shell
vi /etc/sysconfig/network-scripts/ifcfg-ens33
```

***添加以下的配置（需要根据上面的网关来设置***
```java
IPADDR="192.168.80.100"   //在网关的网段内自己随便设置一个
NETMASK="255.255.255.0"   
NETWORK="192.168.80.0"    
GATEWAY="192.168.80.2"    //最重要的网关不能设置错
ONBOOT="yes"
DNS1="8.8.8.8"
DNS2="114.114.114.114"
```

### 修改hosts文件
将几台服务器的地址贴进去

```shell
192.168.xxx.xxx master
192.168.xxx.xxx slave1
192.168.xxx.xxx slave2
```

## 收尾
```shell
reboot --重启服务器
-- 或者
service network restart -- 重启网络服务
```

## 配置master免登陆

将master的ssh key配置到所有的slave的信任文件中
```shell
cd /root/.ssh/
ssh-copy-id -i id_rsa.pub root@slave1
..
```
