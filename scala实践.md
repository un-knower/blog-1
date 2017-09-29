---
title: scala实践
date: 2017-06-15 20:23:10
tags:
    - scala
toc: true
---

[TOC]



## ScalaTest
``` xml
    <dependency>
      <groupId>org.scalatest</groupId>
      <artifactId>scalatest_2.11</artifactId>
      <version>3.0.1</version>
      <scope>test</scope>
    </dependency>
```

### Selecting testing styles for your project
#### FunSuite
- 自己觉得可以推广使用
``` scala
    class SetSuite extends FunSuite {
      test("An empty Set should have size 0") {
        assert(Set.empty.size == 0)
      }

      test("Invorking head on an empty Set should produce NoSuchElementException") {
        assertThrows[NoSuchElementException] {
          Set.empty.head
        }
      }
    }
```

#### FlatSpec
``` scala
    class ExampleSpec extends FlatSpec with Matchers {

      "A Stack" should "pop values in last-in-first-out order" in {
        val stack = new Stack[Int]

        stack.push(1)
        stack.push(2)
        stack.pop() should be(2)
        stack.pop() should be(1)
      }

      it should "throw NoSuchElementException if an empty stack is popped" in {
        val emptyStack = new Stack[Int]

        a[NoSuchElementException] should be thrownBy {
          emptyStack.pop()
        }
      }
    }
```


## 使用收藏
### collection相关
#### collection reduceByKey
``` scala
    case class Pioneer(startDate:Date, endDate:Date, count:Long, tableId:Int)

    val buffer = getPioneers()

    buffer.map(e => (e.getTableId, e)).groupBy(_._1).map { case (key, values) =>
      (key, values.map(_._2).reduce((l, r) => if (l.getEndDate.after(r.getEndDate)) l else r))
    }
```



## 问题记录
1. scala java 混合调用编译
  a. mvn clean scala:compile