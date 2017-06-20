---
title: spark-sql-hive纪要
date: 2017-06-09 11:31:28
tags:
    - sparksql
    - hive
toc: true
---

[TOC]

## 环境准备
1. 拷贝mysql-connector-java-x.y.z-bin.jar到{SPARK_HOME}/jars
2. 重启spark服务
3. 创建hive元数据库hivedb并赋予相应权限
    ``` sql
        create database hivedb;
        grant all privileges on *.* to hive@'localhost' identified by "passwd" with grant option;
        grant all privileges on *.* to hive@'%' identified by "passwd" with grant option;
        flush privileges;
    ```
4. 编辑hive-site.xml文件
hive-site.xml
``` xml
    <configuration>
        <property>
            <name>hive.zookeeper.quorum</name>
            <value>hostname:2181</value>
        </property>
        <property>
            <name>spark.sql.warehouse.dir</name>
            <value>hdfs://hostname:8020/user/hive/warehouse</value>
        </property>
        <property>
            <name>hive.metastore.local</name>
            <value>true</value>
        </property>
        <property>
            <name>javax.jdo.option.ConnectionURL</name>
            <value>jdbc:mysql://hostname:3306/hivedb</value>
        </property>
        <property>
            <name>javax.jdo.option.ConnectionDriverName</name>
            <value>com.mysql.jdbc.Driver</value>
        </property>
        <property>
            <name>javax.jdo.option.ConnectionUserName</name>
            <value>hive</value>
        </property>
        <property>
            <name>javax.jdo.option.ConnectionPassword</name>
            <value>passwd</value>
        </property>
    </configuration>
```
5. 编辑spark-defaults.conf
``` shell
    spark.eventLog.enabled              true
    spark.eventLog.dir                  hdfs://node68:8020/var/log/spark_hislog
    spark.sql.warehouse.dir             hdfs://node68:8020/user/hive/warehouse
```

6. 运行 spark-sql 命令行客户端
``` sql
    create database learn;
    use learn;

    create table if not exists person(
    id string,
    name string,
    phone string,
    address string)ROW FORMAT DELIMITED FIELDS TERMINATED BY '\u0001\t' STORED AS TEXTFILE;


```


## 原理探索
### 


## 开发
1. 编辑pom.xml文件
``` xml
        <dependency>
            <groupId>org.apache.spark</groupId>
            <artifactId>spark-core_${scala.binary.version}</artifactId>
            <version>${spark.version}</version>
        </dependency>
        <dependency>
            <groupId>org.apache.spark</groupId>
            <artifactId>spark-sql_${scala.binary.version}</artifactId>
            <version>${spark.version}</version>
        </dependency>
        <dependency>
            <groupId>org.apache.spark</groupId>
            <artifactId>spark-hive_${scala.binary.version}</artifactId>
            <version>${spark.version}</version>
        </dependency>
```
2. hive-site.xml文件放入到 {PROJECT_HOME}/src/main/resources
``` xml
<configuration>
    <property>
        <name>hive.zookeeper.quorum</name>
        <value>node68:2181</value>
    </property>
    <property>
        <name>hive.metastore.local</name>
        <value>true</value>
    </property>
    <property>
        <name>javax.jdo.option.ConnectionURL</name>
        <value>jdbc:mysql://node68:3306/hivedb</value>
    </property>
    <property>
        <name>javax.jdo.option.ConnectionDriverName</name>
        <value>com.mysql.jdbc.Driver</value>
    </property>
    <property>
        <name>javax.jdo.option.ConnectionUserName</name>
        <value>hive</value>
    </property>
    <property>
        <name>javax.jdo.option.ConnectionPassword</name>
        <value>passwd</value>
    </property>
</configuration>
```
3. 开发demo
``` scala
package com.hikvision.env.tech.hive

import org.apache.spark.sql.SparkSession
import org.slf4j.LoggerFactory

/**
  * Created by likai14 on 2017/6/14.
  */
object HiveDemo {
  val LOG = LoggerFactory.getLogger(this.getClass)

  def main(args: Array[String]): Unit = {
    val session = SparkSession.builder()
      .appName(this.getClass.getSimpleName)
      .master("local[*]")
      .enableHiveSupport()
      .config("spark.sql.warehouse.dir", "hdfs://node68:8020/user/hive/warehouse")
      .getOrCreate()

    val df = session.sql("show databases")

    df.rdd.foreach(row => LOG.error(row.toString()))

    session.stop()
  }
}
```
4 .结果概览
``` shell
...
2017-06-14 11:21:12 com.hikvision.env.tech.hive.HiveDemo$ [ERROR]: [default]
2017-06-14 11:21:12 com.hikvision.env.tech.hive.HiveDemo$ [ERROR]: [learn]
2017-06-14 11:21:12 com.hikvision.env.tech.hive.HiveDemo$ [ERROR]: [scala]
...
```

## 问题集锦
1. 异常
``` shell
Exception in thread "main" java.lang.IllegalArgumentException: Unable to instantiate SparkSession with Hive support because Hive classes are not found.
    at org.apache.spark.sql.SparkSession$Builder.enableHiveSupport(SparkSession.scala:815)
    at com.hikvision.env.tech.hive.HiveDemo$.main(HiveDemo.scala:16)
    at com.hikvision.env.tech.hive.HiveDemo.main(HiveDemo.scala)
```
解决方法：添加spark-hive maven依赖
2. 异常
``` shell
Exception in thread "main" org.apache.spark.sql.catalyst.parser.ParseException: 
extraneous(无关的) input ';' expecting <EOF>(line 1, pos 11)

== SQL ==
show tables;
-----------^^^

    at org.apache.spark.sql.catalyst.parser.ParseException.withCommand(ParseDriver.scala:197)
    at org.apache.spark.sql.catalyst.parser.AbstractSqlParser.parse(ParseDriver.scala:99)
    at org.apache.spark.sql.execution.SparkSqlParser.parse(SparkSqlParser.scala:45)
    at org.apache.spark.sql.catalyst.parser.AbstractSqlParser.parsePlan(ParseDriver.scala:53)
    at org.apache.spark.sql.SparkSession.sql(SparkSession.scala:592)
    at com.hikvision.env.tech.hive.HiveDemo$.main(HiveDemo.scala:19)
    at com.hikvision.env.tech.hive.HiveDemo.main(HiveDemo.scala)
```
解决方法：去掉SQL语句的分号;
3. 开发环境hive加载配置文件原理 
``` scala
// 类名：org.apache.hadoop.hive.conf.HiveConf

static {
    // ...
}


```


