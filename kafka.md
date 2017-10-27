---
title: kafka纪要
date: 2017-06-09 11:31:12
tags: 
    - kafka
toc: true
---

[TOC]

### 观点
- 

## 使用重点积累
1. 


## 环境准备



## 实践
#### spark-streaming-kafka-0-8_2.11
- pom
``` xml
  <dependency>
      <groupId>org.apache.spark</groupId>
      <artifactId>spark-streaming-kafka-0-8_2.11</artifactId>
      <version>2.1.2</version>

      <exclusions>
          <exclusion>
              <groupId>org.apache.kafka</groupId>
              <artifactId>kafka_${scala.binary.version}</artifactId>
          </exclusion>
      </exclusions>
  </dependency>
```
- source
``` scala
  test("source") {
    val sparkConf = new SparkConf().setMaster("local[4]").setAppName(this.getClass.getSimpleName)
    val ssc = new StreamingContext(sparkConf, Milliseconds(500))
    val topic = "streaming"
    val zkAddress = "localhost:2181"

    val kafkaParams = Map("zookeeper.connect" -> zkAddress,
      "group.id" -> s"test-consumer-${Random.nextInt(10000)}",
      "auto.offset.reset" -> "smallest")

    val stream = KafkaUtils.createStream[String, String, StringDecoder, StringDecoder](ssc, kafkaParams, Map(topic -> 1), StorageLevel.MEMORY_ONLY)

    stream.foreachRDD { r =>
      r.collect().foreach { kv =>
        LOG.error(gson.toJson(kv))
      }
    }

    ssc.start()

    ssc.awaitTermination()
    ssc.stop()
  }
```
- sink
``` scala

```

#### spark-sql-kafka-0-10_2.11
- pom
``` xml
  <dependency>
      <groupId>org.apache.spark</groupId>
      <artifactId>spark-sql-kafka-0-10_2.11</artifactId>
      <version>2.1.2</version>

      <exclusions>
          <exclusion>
              <groupId>org.apache.kafka</groupId>
              <artifactId>kafka_${scala.binary.version}</artifactId>
          </exclusion>
      </exclusions>
  </dependency>
```
- source
``` scala
  test("source") {
    val brokers = "localhost:9092"
    val topic = "streaming"

    val spark = SparkSession.builder().appName(this.getClass.getSimpleName).master("local").getOrCreate()
    val df = spark.read
      .format("kafka")
      .option("kafka.bootstrap.servers", brokers)
      .option("startingOffsets", "earliest")
      .option("endingOffsets", "latest")
      .option("subscribe", topic)
      .load()

    df.printSchema()
    df.show(1000)

    spark.stop()
  }
```

- sink
``` scala
  test("sink") {
    val brokers = "localhost:9092"
    val topic = "streaming"

    val spark = SparkSession.builder().appName(this.getClass.getSimpleName).master("local").getOrCreate()
    val df = HbaseDemoTest.genDf(spark)
    val key = df.schema.toString()

    for (i <- 1 to 2) {
      import spark.implicits._
      df.map(row => (topic, key, row.toSeq.mkString("\t"))).toDF("topic", "key", "value").write
        .format("kafka")
        .option("kafka.bootstrap.servers", brokers)
        .mode(SaveMode.Append)
        .save()
    }

    spark.stop()
  }
```

#### 官方api
- pom
``` xml
  <dependency>
      <groupId>org.apache.kafka</groupId>
      <artifactId>kafka-clients</artifactId>
      <version>0.9.0.1</version>
  </dependency>
```
- proceducer
``` scala
  def sendMessages(spark: SparkSession, topic: String): Unit = {
    val kafkaBrokers = "node68:9092"

    val props = new Properties
    props.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, kafkaBrokers)
    props.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG,
      "org.apache.kafka.common.serialization.StringSerializer")
    props.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG,
      "org.apache.kafka.common.serialization.StringSerializer")

    val producer = new KafkaProducer[String, String](props)

    val df = genDf(spark).collect()

    df.foreach(row => {
      producer.send(new ProducerRecord[String, String](topic, null, row.toSeq.mkString("\t")))
    })

    producer.flush()
    producer.close()
  }
```
- consumer
``` scala

```


## 命令积累
``` shell
kafka-server-start.sh
kafka-server-stop.sh

kafka-topics.sh
kafka-topics.sh --create --zookeeper localhost:2181 --replication-factor 1 --partitions 1 --topic test
kafka-topics.sh --list --zookeeper localhost:2181

kafka-consumer-offset-checker.sh

kafka-run-class.sh
kafka-run-class.sh kafka.tools.GetOffsetShell --broker-list localhost:9092 --topic streaming --time -1 #查看offset

kafka-console-consumer.sh
kafka-console-consumer.sh --zookeeper localhost:2181 --topic streaming --from-beginning

kafka-console-producer.sh
kafka-console-producer.sh --broker-list localhost:9092 --topic test

connect-standalone.sh
kafka-acls.sh
kafka-configs.sh


#window
./zookeeper-server-start.bat ../../config/zookeeper.properties
./kafka-server-start.bat ../../config/server.properties
```


## 读书纪要






## 问题记录
1. 
  - 问题描述:
``` log
[2017-10-26 14:49:26,695] ERROR Error when sending message to topic streaming with key: null, value: 4 bytes with error: Failed to update metadata after 60000 ms. (org.apache.kafka.clients.producer.internals.ErrorLoggingCallback)
```
  - 解决办法:[不可行, 需重启该服务]
    + vim server.properties
      * change listeners=PLAINTEXT://hostname:9092 to listeners=PLAINTEXT://0.0.0.0:9092


2. 
  - 问题描述:
``` log
org.apache.kafka.common.protocol.types.SchemaException: Error reading field 'topic_metadata': Error reading array of size 619380, only 37 bytes available
```
  - 原因:
    + 原因：
      + 本机安装的kafka版本与项目pom文件中依赖的kafka版本不一致
  - 解决办法:
3.
  - 问题描述:
``` log
java.lang.NoClassDefFoundError: net/jpountz/util/SafeUtils
```  
  - 解决办法:
``` xml
  <dependency>
      <groupId>org.lz4</groupId>
      <artifactId>lz4-java</artifactId>
      <version>1.4.0</version>
  </dependency>
```

 


