---
layout: post
title: synchronized和reentrantlock
author: itsxun
date: 2019-06-19 17:28:33 +0800
catalog: true
tags:
    - java基础
---
# synchronized

java里面，需要用到同步时一般有两种做法：
- synchronized

  - 这个关键字出现的很早。每个object都有自己的锁。在执行代码的时候，碰上了synchronized后，
  监视器monitor会自动的获取相关的锁，获取锁的等待过程不能被中断，获取到的锁都是非公平锁。
  性能与Reentrantlock旗鼓相当,  一般情况下，都用这个，java官方也更推荐这个，并且一直在优化。


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

# Reentrantlock

- 这个是想说的重点。
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

```java
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

大致流程是：上来就拿锁，然后发现没库存了，这时候调用await方法，注意，这个await是在while的循环里，
如果一直没库存的话，就会一直死循环。

看到这里我有一点迷茫，不管是take方法还是put方法，都是上来就要获取锁的。如果take这里获取到锁后，发现没库存了，进入循环，但是没释放锁，put方法就获取不到锁，不能增加库存，那不就直接死循环了???

除非，虽然我们没有看到unlock方法被调用，但是实际上有调用，并且，如果有调用，肯定就在await方法里。

不着急，我们先来看看condition的await方法和ReentrantLock的unlock方法里边是啥

```java
public void unlock() {
      sync.release(1);//调用了AbstractQueuedSynchronizer的release方法，传参是写死的：1
  }
```

```java
public final void await() throws InterruptedException {
    if (Thread.interrupted())
        throw new InterruptedException();
    Node node = addConditionWaiter();
    int savedState = fullyRelease(node);
    int interruptMode = 0;
    while (!isOnSyncQueue(node)) {
        LockSupport.park(this);
        if ((interruptMode = checkInterruptWhileWaiting(node)) != 0)
            break;
    }
    if (acquireQueued(node, savedState) && interruptMode != THROW_IE)
        interruptMode = REINTERRUPT;
    if (node.nextWaiter != null) // clean up if cancelled
        unlinkCancelledWaiters();
    if (interruptMode != 0)
        reportInterruptAfterWait(interruptMode);
}
//fullyRelease方法点进去看下：
final int fullyRelease(Node node) {
    boolean failed = true;
    try {
        int savedState = getState();
        if (release(savedState)) {
            failed = false;
            return savedState;
        } else {
            throw new IllegalMonitorStateException();
        }
    } finally {
        if (failed)
            node.waitStatus = Node.CANCELLED;
    }
}
//release方法点进去看下：
public final boolean release(int arg) {
    if (tryRelease(arg)) {
        Node h = head;
        if (h != null && h.waitStatus != 0)
            unparkSuccessor(h);
        return true;
    }
    return false;
}
```

可以发现，await方法也调用了unlock方法实际调用的release方法，但是传参数可能不一样。
所以，猜想是可能成立的，即await方法中确实可能释放了锁。

## 监视器

先说下监视器。
监视器我理解是一种同步的实践思路。
监视器模型就像是一个建筑，里面有三个房间，第一个房间是await之后，进去等待的房间。一旦被signal后，开始争夺锁，如果争夺到了，则进去需要第三个也就是目标房间里，否则就进入第二个房间，等待下次争夺锁。

在Reentrantlock里面，condition里面有一个链表，就是房间一，同步器AbstractQueuedSynchronizer(简称AQS),里面也有一个链表，就是房间2

下面给出await方法的注释：
```java
public final void await() throws InterruptedException {
    if (Thread.interrupted())
        throw new InterruptedException();
    /**
      将自己加入到condition的链表
    **/
    Node node = addConditionWaiter();
    /**
      释放自己的锁
    **/
    int savedState = fullyRelease(node);
    int interruptMode = 0;
    /**
      检查自己是否进入了AQS队列
      如果不在，说明没有被signal，没有竞争锁的资格，调用park方法沉睡。
      一直到自己加入了AQS队列。加入AQS队列的契机就是被signal后。
    **/
    while (!isOnSyncQueue(node)) {
        LockSupport.park(this);
        if ((interruptMode = checkInterruptWhileWaiting(node)) != 0)
            break;
    }
    /**
        到这里实际上就是已经被signal了，有资格竞争锁。
        acquireQueued方法会死循环的竞争锁，
    **/
    if (acquireQueued(node, savedState) && interruptMode != THROW_IE)
        interruptMode = REINTERRUPT;
    if (node.nextWaiter != null) // clean up if cancelled
        unlinkCancelledWaiters();
    if (interruptMode != 0)
        reportInterruptAfterWait(interruptMode);
}

//这个是acquireQueued方法，死循环的竞争锁，
//一次未竞争到，parkAndCheckInterrupt里面会再次调用park方法沉睡
final boolean acquireQueued(final Node node, int arg) {
    boolean failed = true;
    try {
        boolean interrupted = false;
        for (;;) {
            final Node p = node.predecessor();
            if (p == head && tryAcquire(arg)) {
                setHead(node);
                p.next = null; // help GC
                failed = false;
                return interrupted;
            }
            if (shouldParkAfterFailedAcquire(p, node) &&
                parkAndCheckInterrupt())
                interrupted = true;
        }
    } finally {
        if (failed)
            cancelAcquire(node);
    }
}

//我们再看下tryAcquire方法，主要就是把自己设置为同步器AQS的排他线程
final boolean nonfairTryAcquire(int acquires) {
    final Thread current = Thread.currentThread();
    int c = getState();
    if (c == 0) {
        if (compareAndSetState(0, acquires)) {
            setExclusiveOwnerThread(current);
            return true;
        }
    }
    else if (current == getExclusiveOwnerThread()) {
        int nextc = c + acquires;
        if (nextc < 0) // overflow
            throw new Error("Maximum lock count exceeded");
        setState(nextc);
        return true;
    }
    return false;
}
```


好了，我们回过神来，刚才看到unlock方法和await方法，都是调用了同步器AQS的release方法，但是区别是，传入的参数不一样，这个参数有以下可取值，在AQS的class里面有写。
  非负数意味着不需要被signal

-  SIGNAL(-1): successor's thread needs unparking

-  CANCELLED(1): 获取锁的过程中超时或者被中断了。

-  CONDITION(-2): 被await的时候，加入到condition链表中的初始值

-  PROPAGATE(-3): the next acquireShared should unconditionally propagate
