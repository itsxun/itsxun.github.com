---
layout: post
title: BigDecimal的一些基础知识
author: itsxun
date: 2018-06-11 22:51:33 +0800
catalog: true
tags:
    - java基础
---
# BigDecimal

> BigDecimal是java在涉及到高精度运算（例如金额）时，为了避免丢失精度而诞生的类

## 构造方法
```py
- BigDecimal(double)    # 这个不建议使用，仍然会丢失精度
- BigDecimal.valueOf()  # 可用于double和long生成BigDecimal
- BigDecimal(String)    # 保证准确无误
- BigDecimal(int)       # 保证准确无误
```

## 成员变量
- precision 精度(变量长度)
  - 0 返回 1
  - 01 返回 1
  - 01.10 返回 3

- scale 小数位数
  - 01.000 返回 3

- intCompact
  - 用于计算辅助，当值的绝对值小于Long.MAX_VALUE，值会被压缩存储在这个数中加快计算
  
## 常用的方法
- 加法: add
  ```java
    b1 = b1.add(b2);
  ```
- 减法
  ```java
    b1 = b1.subtract(b2);
  ```
- 乘法
  ```java
    b1 = b1.multiply(b2);
  ```
- 除法
  ```java
    b1=b1.divide(b2);
    //但是不建议除法直接这么计算，推荐使用带精度，带有RoundingMode(舍入模式)的计算方法
    //比如我想计算10 / 3的值，保留两位小数，四舍五入:
      BigDecimal b=new BigDecimal("10").divide(new BigDecimal("3"), 2, RoundingMode.HALF_UP);
  ```

- 大小比较 compareTo
```java
//不能用equals，需要用compareTo
new BigDecimal("1").compareTo(new BigDecimal("2"));

equals会先检查是否类型一直，在检查小数位数是否一致，最后判断
```

- 计算余数
```java
BigDecimal[] bs= BigDecimal("10").divideAndRemainder(new BigDecimal("4"));
bs[1]就是余数
```
- number格式化
```
//一个公共方法，去除开头的0，去除结尾的0，指数形式会转为正常显示
public static String format(String str){
  //stripTrailingZeros: 删除开头的，结尾的0
  //toPlainString: toString，并且同时会转指数形式成为正常的显示
  return new BigDecimal(str).stripTrailingZeros().toPlainString();
}
```


## 关于RoundingMode的效果
- UP
```
1.1 -> 2
1.0 -> 1
-1.1 -> -2
```

- DOWN
```
1.1 -> 1
-1.0 -> -1
-1.1 -> -1
```

- CEILING
```
1.1 -> 2
-1.1 -> -1
```

- FLOOR
```
1.1 -> 1
-1.1 -> -2
```

- HALF_UP
```
四舍五入
```
- HALF_DOWN
```
五舍六入
1.6  =>  2
-1.1  =>  -1
-1.6  =>  -2
```

- UNNECESSARY
```java
//余数超过指定scale就会抛异常
//比如：10 / 4
//不抛异常
new BigDecimal("10").divide(new BigDecimal("4"), 1, RoundingMode.UNNECESSARY);
//java.lang.ArithmeticException: Rounding necessary ，精度不指定默认为0(final int)
new BigDecimal("10").divide(new BigDecimal("4"), RoundingMode.UNNECESSARY);
```

- HALF_EVEN
```
银行家算法
舍去位的数值小于5时，直接舍去。
舍去位的数值大于5时，进位后舍去。
当舍去位的数值等于5时，若5后面还有其他非0数值，则进位后舍去，若5后面是0时，则根据5前一位数的奇偶性来判断，奇数进位，偶数舍去。
eg.
11.556 = 11.56 ------六入
11.554 = 11.55 -----四舍
11.5551 = 11.56 -----五后有数进位
11.545 = 11.54 -----五后无数，若前位为偶数应舍去
11.555 = 11.56 -----五后无数，若前位为奇数应进位
```
