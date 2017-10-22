---
title: flink实践纪要
date: 2017-09-25 11:31:28
tags:
    - flink
    

---

[TOC]












## 环境准备


### 研发环境
1. [download flink binary](http://mirrors.shuosc.org/apache/flink/flink-1.3.2/flink-1.3.2-bin-hadoop27-scala_2.11.tgz)
2. 解压并转到安装目录${FLINK_HOME}
3. ./bin/start-local.bat
4. tail -f log/flink-*-jobmanager-*.log
5. [浏览器验证: ](http://localhost:8081/#/overview)


### 生产环境


## 问题记录



## 原理探索


## 细节积累



## 概念



## 开发
1. 编辑pom.xml文件
    + scala
    ``` xml
    <dependency>
        <groupId>org.apache.flink</groupId>
        <artifactId>flink-scala_2.11</artifactId>
        <version>1.3.2</version>
    </dependency>
    <dependency>
        <groupId>org.apache.flink</groupId>
        <artifactId>flink-streaming-scala_2.11</artifactId>
        <version>1.3.2</version>
    </dependency>
    <dependency>
        <groupId>org.apache.flink</groupId>
        <artifactId>flink-clients_2.11</artifactId>
        <version>1.3.2</version>
    </dependency>       
    ```
    + java
    ``` xml
    <dependency>
        <groupId>org.apache.flink</groupId>
        <artifactId>flink-java</artifactId>
        <version>1.3.2</version>
    </dependency>
    <dependency>
        <groupId>org.apache.flink</groupId>
        <artifactId>flink-streaming-java_2.10</artifactId>
        <version>1.3.2</version>
    </dependency>
    <dependency>
        <groupId>org.apache.flink</groupId>
        <artifactId>flink-clients_2.10</artifactId>
        <version>1.3.2</version>
    </dependency>
    ```

2. 配置文件   放入到 {PROJECT_HOME}/src/main/resources
``` xml

```
3. 开发demo
``` scala

```
4 .结果概览
``` shell
...


...
```

## 问题集锦
1. 异常

解决方法：
