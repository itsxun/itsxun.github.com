---
layout: post
title: shell-stream-text-edit
author: itsxun
date: 2019-01-18 10:05:49 +0800
catalog: true
tags:
    - linux
---

### 前言

需求是：将hadoop ls后查询出来的数据按照文件更新时间过滤一部分后稍作处理，提取文件名中的一部分封装在数组中。

hadoop ls后查询出来的数据中每条大概是像下面这样，有很多条，需要过滤后把XXXX提取出来：

-rw-r----- 3 hduser hadoop 1240 2018-11-12 07:34 /user/hive/warehouse/mydb/mytable/part-00000_copy_XXXX

### 命令

#### grep：文件过滤

> 可带参数
  - -v：表示对结果集取反
  - -E：表示运用正则表达式来过滤

比如我需要按照文件生成时间，对当前一个月之前的文件过滤掉，可以这么写：
```
grep -vE "2019-01-"
```

#### sort：结果集排序

> 可带参数
  - -k：后面接数组序号，表示对哪一列进行过滤

比如我需要对上面的例子按照天数和时间戳来排序，可以这么写：
```
sort -k6,7
```

#### awk：控制输出

比如我现在只需要文件名那一列，它是第8列，其他的列不需要输出，可以这么写：
```
awk '{print $8}'
```

### sed：字符串替换

> 可带参数
  - g：global，表示全局替换
  - i：表示忽略大小写替换

比如我现在只需要XXXX，就可以把前面的一长串全局替换成空串，可以这么写：
```
prefix="/user/hive/warehouse/mydb/mytable/part-00000_copy_"
empty=""
sed "s@$prefix@empty@g"
```

###  整合

所以最终的版本是：
```shell
#拿到最终结果集
res=hadoop fs -ls /user/hive/warehouse/mydb/mytable | sort -k6,7 | grep -vE "2019-01-" | awk '{print $8}' | sed "s@$prefix@empty@g"

#组装成数组
array=($res)

#数组长度
length=${#arr[*]}

#遍历数组
#判断下长度，有数据才遍历
if [ $length -eq 0 ]
then
    echo "no data."
else  
    #遍历输出数组中的元素
    for i in ${arr[*]}
    do
        echo "$i"
    done
fi
```
