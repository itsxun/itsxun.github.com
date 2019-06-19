---
layout: post
title: synchronized和reentrantlock
author: itsxun
date: 2019-06-19 17:28:33 +0800
catalog: true
tags:
    - java基础
---
# 引入


java里面，需要用到同步时一般有两种做法：
- synchronized

  - 这个关键字出现的很早。每个object都有自己的锁。在执行代码的时候，碰上了synchronized后，
  监视器monitor会自动的获取相关的锁，获取锁的过程不能被中断，获取到的锁都是非公平锁。
  性能与Reentrantlock旗鼓相当,  一般情况下，都用这个，java官方也更推荐这个，一直在优化。

> 锁的说明

```java
//锁定对象分为以下几种，其实很简单，不难理解，分为以下几种
/**
 1，锁定当前调用该方法的对象
 2，锁定当前调用该方法的对象的class对象
 3.锁定自定义的一个对象
**/
public synchronized void xxx(){};//锁定当前调用该方法的对象
public synchronized static void xxx(){};//锁定当前调用该方法的对象的class对象

synchronized(this}//锁定当前调用该方法的对象

Object obj = new Object();
synchronized(obj){}//锁定自定义的obj
```

- Reentrantlock，这个是想说的重点
  一个Reentrantlock可以通过newCondition方法生成多个condition，从而实现更细粒度的控制。

  先看一个生产者消费者的代码片段，网上随便找的：

```java
//其实很简单，就是两组线程，一组一直调push方法，另外一组一直调take方法
public class ProducerAndCustomer {
    private int count;
    public final int MAX_COUNT = 10;
    ReentrantLock reentrantLock = new ReentrantLock();
    Condition push = reentrantLock.newCondition();
    Condition take = reentrantLock.newCondition();

    public void push() {
        reentrantLock.lock();
        while (count >= 10) try {
            System.out.println("库存大于等于10个，阻塞停止生产！");
            push.await();
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        count++;
        System.out.println(Thread.currentThread().getName() + "生产者生产，库存：" + count);
        take.signal();
        reentrantLock.unlock();
    }
    public void take() {
        reentrantLock.lock();
        while (count <= 0) {
            try {
                System.out.println("拿的太快啦，收手停止一下啦！");
                take.await();
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }
        count--;
        System.out.println("有人偷偷拿走一个商品，还剩:" + count);
        push.signal();
        reentrantLock.unlock();
    }

    public static void main(String[] args) {
        ProducerAndCustomer producerAndCustomer = new ProducerAndCustomer();
        ExecutorService executorService = Executors.newFixedThreadPool(10);

        executorService.execute(new Producer(producerAndCustomer));
        executorService.execute(new Producer(producerAndCustomer));
        executorService.execute(new Producer(producerAndCustomer));
        executorService.execute(new Producer(producerAndCustomer));

        executorService.execute(new Customer(producerAndCustomer));
        executorService.execute(new Customer(producerAndCustomer));
        executorService.execute(new Customer(producerAndCustomer));
        executorService.execute(new Customer(producerAndCustomer));
        executorService.execute(new Customer(producerAndCustomer));
        executorService.execute(new Customer(producerAndCustomer));
    }
}

class Producer implements Runnable {
    private ProducerAndCustomer producerAndCustomer;
    public Producer(ProducerAndCustomer producerAndCustomer) {
        this.producerAndCustomer = producerAndCustomer;
    }
    @Override
    public void run() {
        while (true) {
            producerAndCustomer.push();
            try {
                Thread.sleep(1000);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }
    }
}

class Customer implements Runnable {
    private ProducerAndCustomer producerAndCustomer;
    public Customer(ProducerAndCustomer producerAndCustomer) {
        this.producerAndCustomer = producerAndCustomer;
    }
    @Override
    public void run() {
        while (true) {
            producerAndCustomer.take();
            try {
                Thread.sleep(1000);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }
    }
}
```

看完这个代码后，我昨天一直在思考一个问题，我们看这take方法：
```
public void take() {
    reentrantLock.lock();
    while (count <= 0) {
        try {
            System.out.println("拿的太快啦，收手停止一下啦！");
            take.await();
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }
    count--;
    System.out.println("有人偷偷拿走一个商品，还剩:" + count);
    push.signal();
    reentrantLock.unlock();
}
```
