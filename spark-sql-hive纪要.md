---
title: spark-sql-hive纪要
date: 2017-06-09 11:31:28
tags:
    - sparksql
    - hive
    - spark

---

[TOC]

## spark practice

1. [下载数据集:](https://archive.ics.uci.edu/ml/machine-learning-databases/00210/donation.zip)
2. [听歌记录数据集:](http://www.iro.umontreal.ca/~lisa/datasets/profiledata_06-May-2005.tar.gz)


### 使用总结
1. 修改spark-sql控制台日志级别：
  a. spark-sql --driver-java-options "-Dlog4j.debug -Dlog4j.configuration=file:///etc/SPARK/log4j.error.properties"
2. DataFrame 执行groupBy(colname) 结合 [UADF](https://docs.databricks.com/spark/latest/spark-sql/udaf-scala.html)实现业务需求



### spark2 kafka

### spark2 hbase
- [hbase-spark](https://github.com/kaidata/hbase-spark)
- dataframe --> hbase table (catalog)
``` scala
  val schema = new StructType(Array(
    new StructField("id", LongType),
    new StructField("area", StringType),
    new StructField("areacode", StringType)
  }

  def schema2catalog(schema: StructType, tablename: String, family: String, rowkeyCol: String): String = {
    val buffer = new ArrayBuffer[String]()

    schema.iterator.toList.filter(field => !rowkeyCol.equals(field.name)).foreach(filed => {
      buffer.+=(s""""${filed.name}":{"cf":"${family}", "col":"${filed.name}", "type":"${filed.dataType.catalogString}"}""")
    })

    s"""{
       |"table":{"namespace":"default", "name":"${tablename}"},
       |"rowkey":"key",
       |"columns":{
       |"${rowkeyCol}":{"cf":"rowkey", "col":"key", "type":"string"},
      ${buffer.mkString(",")}
       |}
       |}""".stripMargin
  }  

  def write2hbase(spark: SparkSession, jsonRDD: RDD[String], tablename: String): Unit = {
    val df =
      if (tablename.startsWith(PropertyConstants.TRAFFIC_DATABASE)) {
        spark.read.schema(TrafficDataLoad.schema).json(jsonRDD)
      } else {
        spark.read.json(jsonRDD)
      }

    LOG.info(df.schema.toString())

    val catalog = schema2catalog(TrafficDataLoad.schema, "traffic", "i", "passid")

    LOG.info(catalog)

    df.write.options(
      Map(HBaseTableCatalog.tableCatalog -> catalog, HBaseTableCatalog.newTable -> "2", HBaseSparkConf.HBASE_CONFIG_LOCATION -> "hbase-site.xml", HBaseSparkConf.USE_HBASECONTEXT -> "false")
    ).format("org.apache.hadoop.hbase.spark").save()
  }

  def read4hbase(spark: SparkSession, lineCount: Int = 1000): DataFrame = {
    val catalog = schema2catalog(schema, "traffic", "i", "passid")

    val df = spark
      .read
      .options(Map(HBaseTableCatalog.tableCatalog -> catalog, HBaseSparkConf.HBASE_CONFIG_LOCATION -> "hbase-site.xml", HBaseSparkConf.USE_HBASECONTEXT -> "false"))
      .format("org.apache.hadoop.hbase.spark")
      .load()
    
    df.printSchema()
    df.show()

    df
  }
```


### spark Dataframe
``` scala
  test("reduce by key") {
    val spark = SparkSession.builder().appName(this.getClass.getSimpleName).master("local").getOrCreate()

    import spark.implicits._
    val df = Seq(("s", 1), ("b", 2), ("a", 35), ("b", 4)).toDF("key", "value")
    df.show()
    val dfSchema = df.schema
    dfSchema.printTreeString()

    val tmpSchema = dfSchema.add("priority", IntegerType, true)
    val tmpRdd = df.rdd.map(row => Row.fromSeq(row.toSeq ++ Array[Int](Random.nextInt(2))))
    val tmpDf = spark.createDataFrame(tmpRdd, tmpSchema)

    tmpSchema.printTreeString()
    tmpDf.show()

    val resultRdd = tmpDf.rdd.map(row => (row.getAs[String]("key"), row)).reduceByKey((left, right) => left).map(_._2)
    val resultDf = spark.createDataFrame(resultRdd, tmpDf.schema)

    resultDf.show()

    spark.stop()
  }
```


## 环境准备
### 数据测试
avro schema(person.avsc)：
``` console
{
"namespace": "com.chaosdata",
 "type": "record",
 "name": "Person",
 "fields": [
     {"name": "id", "type": "string"},
     {"name": "name",  "type": "string"},
     {"name": "sex",  "type": "string"},
     {"name": "addr",  "type": "string"},
     {"name": "phone",  "type": "string"}
 ]
 
}
```
建表：
``` sql
CREATE TABLE person
  ROW FORMAT SERDE
  'org.apache.hadoop.hive.serde2.avro.AvroSerDe'
  WITH SERDEPROPERTIES (
    'avro.schema.url'='file:///F:/datacenter/struct/avro/schema/person.avsc')
  STORED as INPUTFORMAT
  'org.apache.hadoop.hive.ql.io.avro.AvroContainerInputFormat'
  OUTPUTFORMAT
  'org.apache.hadoop.hive.ql.io.avro.AvroContainerOutputFormat';

  LOAD DATA LOCAL INPATH 'file:///F:/datacenter/output/env/avro/1501234557947' INTO TABLE person;
```
生成数据：
``` scala
   def avro(sc: SparkContext, ssc: SQLContext): Unit = {
    for (j <- 1 to 1) {
      val bufer = new ArrayBuffer[(String, String, String, String, String)]()

      for (i <- (1 to 1000000)) {
        bufer.+=(genInfos)
      }

      val schema = new Schema.Parser().parse(new File("F:\\datacenter\\struct\\avro\\schema\\person.avsc"))
      val conf = new Configuration()
      conf.set("avro.schema.output.key", schema.toString)
      val rdd = sc.parallelize(bufer).map(infos => (new AvroKey(genPerson(infos._1, infos._2, infos._3, infos._4, infos._5)), null))
        .saveAsNewAPIHadoopFile("file:///F:\\datacenter\\output\\env\\avro\\" + System.currentTimeMillis(), classOf[Person], classOf[NullWritable], classOf[AvroKeyOutputFormat[Person]], conf)
    }

    ssc.clearCache()
  }
```
#### 数据入库【important】
##### 重要问题引入：read.table  分区方案原理？(@geting)

``` scala
  def write(args: Array[String]): Unit = {
    val spark = SparkSession
      .builder()
      .appName("Spark Hive Example")
      .enableHiveSupport()
      .master("local")
      .getOrCreate()

    val df = spark.read
      .format("com.databricks.spark.avro")
      .load("file:///F:\\datacenter\\output\\env\\avro\\1501234557947\\*")

    val dbname = "learn"
    val tablename = "coder"
    df.write.mode("append").saveAsTable(s"$dbname.$tablename")

    spark.stop()
  }
```
#### 数据出库【important】
``` scala
  def read(args: Array[String]): Unit = {
    val spark = SparkSession
      .builder()
      .appName("Spark Hive Example")
      .enableHiveSupport()
      .master("local")
      .getOrCreate()

    val dbname = "learn"
    val tablename = "coder"
    val df = spark.read.table(s"$dbname.$tablename")

    df.printSchema()
    df.take(100).foreach(println)

    spark.stop()
  }
```
#### python 开发
- [api文档](http://spark.apache.org/docs/2.1.0/api/python/pyspark.sql.html#)
- sqllearn.py
``` python 
from __future__ import print_function

from os.path import expanduser, join

from pyspark.sql import SparkSession

if __name__ == "__main__":
    spark = SparkSession \
        .builder \
        .appName("Python Spark SQL Hive integration example") \
        .enableHiveSupport() \
        .getOrCreate()

    df = spark.sql("show databases")
    df.show()

    df1 = spark.read.table("learn.learn_demo")

    df1.write.csv("file:////usr/local/envTech/datas", "append")
    df1.write.saveAsTable("learn.datas")

    spark.stop()
```

``` shell
spark-submit ./sqllearn.py
```


### 研发环境
1. 下载spark代码进行编译或者下载spark-prebuild版本，下载postgre驱动postgresql-9.0-801.jdbc4.jar[https://jdbc.postgresql.org/download/postgresql-9.0-801.jdbc4.jar]到${SPARK_HOME}/jars
2. vim hive-site.xml
``` xml
<configuration>
    <property>
        <name>hive.metastore.local</name>
        <value>true</value>
    </property>

    <property>
        <name>javax.jdo.option.ConnectionURL</name>
        <value>jdbc:postgresql://localhost:5432/sparksql?</value>
        <description>JDBC connect string for a JDBC metastore</description>
    </property>
    <property>
        <name>javax.jdo.option.ConnectionDriverName</name>
        <value>org.postgresql.Driver</value>
        <description>Driver class name for a JDBC metastore</description>
    </property>
    <property>
        <name>javax.jdo.option.ConnectionUserName</name>
        <value>dev</value>
        <description>username to use against metastore database</description>
    </property>
    <property>
        <name>javax.jdo.option.ConnectionPassword</name>
        <value>chaosdata</value>
        <description>password to use against metastore database</description>
    </property>
</configuration>
```
3. vim ${SPARK_HOME}/conf/spark-defaults.conf
``` console
spark.eventLog.enabled              true
spark.eventLog.dir                  file:///F:/datacenter/sparksql/log
spark.sql.warehouse.dir             file:///F:/datacenter/sparksql/data
spark.driver.extraJavaOptions       -XX:MaxPermSize=1024m -XX:PermSize=256m
```
4. vim ${SPARK_HOME}/conf/spark-spark-env.sh
``` console

```
5. vim ${SPARK_HOME}/bin/spark-sql.cmd
``` bat
@echo off

set SPARK_HOME=%~dp0..
set _SPARK_CMD_USAGE=Usage: .\bin\spark-sql.cmd [options]

"%SPARK_HOME%\bin\spark-submit2.cmd" --class org.apache.spark.sql.hive.thriftserver.SparkSQLCLIDriver --name "Spark sql" %*
```
6. 下载hive的metadata对应的[schema](https://github.com/apache/hive/blob/release-1.2.1/metastore/scripts/upgrade/postgres/), 并执行该sql文件[schema_postgre](./annex/file/hive-schema-1.2.0.postgres.sql)


### 生产环境
1. 拷贝[mysql-connector-java-x.y.z-bin.jar](https://cdn.mysql.com//Downloads/Connector-J/mysql-connector-java-5.1.44.zip)到{SPARK_HOME}/jars
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
    spark.driver.extraJavaOptions       -XX:MaxPermSize=1024m -XX:PermSize=256m
```

6. 运行 spark-sql 命令行客户端
``` sql
    create database learn;
    use learn;

    create table if not exists person(
    id string,
    name string,
    phone string,
    address string)ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t' STORED AS TEXTFILE;

    LOAD DATA INPATH 'hdfs://hostname:8020/user/hive/warehouse/tmp/hotel/hotel' OVERWRITE INTO TABLE hotel;

    create table wzhg(  
    c0 string,  
    c1 string,  
    c2 string  
    )row format serde 'org.apache.hadoop.hive.contrib.serde2.RegexSerDe'  
    with serdeproperties (  
    'input.regex' = 'bduid\\[(.*)\\]uid\\[(\\d+)\\]uname\\[(.*)\\]',  
    'output.format.string' = '%1$s\t%2$s'  
    ) stored as textfile;  


```

## 问题记录
``` console
2017-07-14 14:43:03,387 ERROR [main] metastore.RetryingHMSHandler: Retrying HMSHandler after 2000 ms (attempt 1 of 10) with error: javax.jdo.JDODataStoreException: You have an error in your SQL syntax; check the manual that corresponds to your MySQL server version for the right syntax to use near 'OPTION SQL_SELECT_LIMIT=DEFAULT' at line 1
    at org.datanucleus.api.jdo.NucleusJDOHelper.getJDOExceptionForNucleusException(NucleusJDOHelper.java:451)
    at org.datanucleus.api.jdo.JDOQuery.execute(JDOQuery.java:275)

NestedThrowablesStackTrace:
com.mysql.jdbc.exceptions.MySQLSyntaxErrorException: You have an error in your SQL syntax; check the manual that corresponds to your MySQL server version for the right syntax to use near 'OPTION SQL_SELECT_LIMIT=DEFAULT' at line 1
    at com.mysql.jdbc.SQLError.createSQLException(SQLError.java:936)
    at com.mysql.jdbc.MysqlIO.checkErrorPacket(MysqlIO.java:2985)
    at com.mysql.jdbc.MysqlIO.sendCommand(MysqlIO.java:1631)
```
解决方法：下载最新的https://downloads.mysql.com/archives/c-j/ 的Connector/J 替换原有旧jar

``` console
17/07/23 03:55:21 ERROR Datastore: Error thrown executing CREATE TABLE `PARTITION_PARAMS`
(
    `PART_ID` BIGINT NOT NULL,
    `PARAM_KEY` VARCHAR(256) BINARY NOT NULL,
    `PARAM_VALUE` VARCHAR(4000) BINARY NULL,
    CONSTRAINT `PARTITION_PARAMS_PK` PRIMARY KEY (`PART_ID`,`PARAM_KEY`)
) ENGINE=INNODB : Specified key was too long; max key length is 767 bytes
com.mysql.jdbc.exceptions.jdbc4.MySQLSyntaxErrorException: Specified key was too long; max key length is 767 bytes
    at sun.reflect.NativeConstructorAccessorImpl.newInstance0(Native Method)
    at sun.reflect.NativeConstructorAccessorImpl.newInstance(NativeConstructorAccessorImpl.java:62)
    at sun.reflect.DelegatingConstructorAccessorImpl.newInstance(DelegatingConstructorAccessorImpl.java:45)
    at java.lang.reflect.Constructor.newInstance(Constructor.java:423)
    at com.mysql.jdbc.Util.handleNewInstance(Util.java:377)
```
解决方案:alter database sparksqlhivedb character set latin1

``` console
Exception in thread "main" java.lang.UnsatisfiedLinkError: org.apache.hadoop.io.
nativeio.NativeIO$Windows.createDirectoryWithMode0(Ljava/lang/String;I)V
```
解决方案：原因：是你的hadoop.dll 文件和你当前的hadoop版本不匹配


## [Spark SQL Reference](https://docs.databricks.com/spark/latest/spark-sql/index.html)
### Spark SQL Language Manual
#### Alter Database
``` sql
    ALTER (DATABASE|SCHEMA) db_name SET DBPROPERTIES (key1=val1, ...)
    -- Set one or more properties in the specified database. If already set, override.
```
#### Alter Table or View
``` sql
    ALTER (TABLE|VIEW) [db_name.]table_name RENAME TO [db_name.]new_table_name
    -- if destination table exists, exception; 不支持跨数据库
    ALTER (TABLE|VIEW) table_name SET TBLPROPERTIES (key1=val1, key2=val2, ...)
    -- Set the properties of an existing table or view. if already set, override
    ALTER (TABLE|VIEW) table_name UNSET TBLPROPERTIES [IF EXISTS] (key1, key2, ...)
    -- Drop one or more properties of an existing table or view. if not exist, exception
    -- IF EXISTS, If not exist, nothing will happen.
    ALTER TABLE table_name [PARTITION part_spec] SET SERDE serde [WITH SERDEPROPERTIES (key1=val1, key2=val2, ...)]
    ALTER TABLE table_name [PARTITION part_spec] SET SERDEPROPERTIES (key1=val1, key2=val2, ...)
    -- part_spec:
    --  : (part_col_name1=val1, part_col_name2=val2, ...)
    -- Set the SerDe and/or the SerDe properties of a table or partition.If property already set, override. Setting the SerDe is only allowed for tables created using the Hive format.
```
#### Alter Table Partitions
``` sql
    ALTER TABLE table_name ADD [IF NOT EXISTS]
        (PARTITION part_spec [LOCATION path], ...)
    part_spec:
        : (part_col_name1=val1, part_col_name2=val2, ...)
    -- Add partitions to the table, optionally with a custom location for each partition added. only Hive format
    
    ALTER TABLE table_name PARTITION part_spec RENAME TO PARTITION part_spec
    -- Changes the partitioning field values of a partition. only Hive format

    ALTER TABLE table_name DROP [IF EXISTS] (PARTITION part_spec, ...)
    -- Drops partitions from a table or view. only Hive format

    ALTER TABLE table_name PARTITION part_spec SET LOCATION path
    -- Sets the location of the specified partition. only Hive format
```
#### Analyze Table
``` sql
    ANALYZE TABLE [db_name.]table_name COMPUTE STATISTICS analyze_option
    -- Write statistics about a table into the underlying metastore for future query optimizations. Currently the only analyze option supported is NOSCAN, which means the table won’t be scanned to generate the statistics. only Hive format
```
#### Cache Table
``` sql
    CACHE [LAZY] TABLE [db_name.]table_name
    -- Cache the contents of the table in memory. Subsequent queries on this table will bypass scanning the original files containing its contents as much as possible.
    -- LAZY: Cache the table lazily instead of eagerly scanning the entire table.
```
#### Clear Cache
``` sql
    CLEAR CACHE
    -- Clears the cache associated with a SQLContext.
```
#### Create Database
``` sql
    CREATE (DATABASE|SCHEMA) [IF NOT EXISTS] db_name
        [COMMENT comment_text]
        [LOCATION path]
        [WITH DBPROPERTIES (key1=val1, key2=val2, ...)]
    -- Create a database. If a database exists, exception
    IF NOT EXISTS
    -- If a database with the same name already exists, nothing will happen.
    LOCATION
    -- If the specified path does not already exist in the underlying file system, this command will try to create a directory with the path. When the database is dropped later, this directory will be deleted.
```
#### Create Function
``` sql
    CREATE [TEMPORARY] FUNCTION [db_name.]function_name AS class_name
        [USING resource, ...]
    resource:
        : (JAR|FILE|ARCHIVE) file_uri
    -- Create a function. The specified class for the function must extend either UDF or UDAF in org.apache.hadoop.hive.ql.exec, or one of AbstractGenericUDAFResolver, GenericUDF, or GenericUDTF in org.apache.hadoop.hive.ql.udf.generic. If function same name exists in database, exception. 
    -- Note: This command is supported only when Hive support is enabled.
    -- TEMPORARY: The created function will be available only in this session and will not be persisted to the underlying metastore, if any. No database name may be specified for temporary functions.
    -- USING <resources>: Specify the resources that must be loaded to support this function. A list of jar, file, or archive URIs may be specified. Known issue: adding jars does not work from the Spark shell (SPARK-8586).
```
#### Create Table
``` sql
    CREATE [TEMPORARY] TABLE [IF NOT EXISTS] [db_name.]table_name
        [(col_name1[:] col_type1 [COMMENT col_comment1], ...)]
        USING datasource
        [OPTIONS (key1=val1, key2=val2, ...)]
        [PARTITIONED BY (col_name1, col_name2, ...)]
        [CLUSTERED BY (col_name3, col_name4, ...) INTO num_buckets BUCKETS]
        [AS select_statement]
    -- Create a table using a data source. If table same name exists in database, exception. 
    -- TEMPORARY: The created table will be available only in this session and will not be persisted to the underlying metastore, if any. This may not be specified with IF NOT EXISTS or AS <select_statement>. To use AS <select_statement> with TEMPORARY, one option is to create a TEMPORARY VIEW instead.
    CREATE TEMPORARY VIEW table_name AS select_statement
    -- There is also “CREATE OR REPLACE TEMPORARY VIEW” that may be handy if you don’t care whether the temporary view already exists or not. Note that for TEMPORARY VIEW you cannot specify datasource, partition or clustering options since a view is not materialized like tables.
    -- IF NOT EXISTS: If a table with the same name already exists in the database, nothing will happen. This may not be specified when creating a temporary table.
    -- USING <data source>: Specify the file format to use for this table. The data source may be one of TEXT, CSV, JSON, JDBC, PARQUET, ORC, and LIBSVM, or a fully qualified class name of a custom implementation of org.apache.spark.sql.sources.DataSourceRegister.
    -- PARTITIONED BY: The created table will be partitioned by the specified columns. A directory will be created for each partition.
    -- CLUSTERED BY: Each partition in the created table will be split into a fixed number of buckets by the specified columns. This is typically used with partitioning to read and shuffle less data. Support for SORTED BY will be added in a future version.
    -- AS <select_statement>: Populate the table with input data from the select statement. This may not be specified with TEMPORARY TABLE or with a column list. To specify it with TEMPORARY, use CREATE TEMPORARY VIEW instead.


```
##### Examples:
``` sql
    CREATE TABLE boxes (width INT, length INT, height INT) USING CSV

    CREATE TEMPORARY TABLE boxes
        (width INT, length INT, height INT)
        USING PARQUET
        OPTIONS ('compression'='snappy')

    CREATE TABLE rectangles
        USING PARQUET
        PARTITIONED BY (width)
        CLUSTERED BY (length) INTO 8 buckets
        AS SELECT * FROM boxes

    CREATE OR REPLACE TEMPORARY VIEW temp_rectangles
        AS SELECT * FROM boxes
```
##### Create Table with Hive format
``` sql
    CREATE [EXTERNAL] TABLE [IF NOT EXISTS] [db_name.]table_name
        [(col_name1[:] col_type1 [COMMENT col_comment1], ...)]
        [COMMENT table_comment]
        [PARTITIONED BY (col_name2[:] col_type2 [COMMENT col_comment2], ...)]
        [ROW FORMAT row_format]
        [STORED AS file_format]
        [LOCATION path]
        [TBLPROPERTIES (key1=val1, key2=val2, ...)]
        [AS select_statement]

    row_format:
        : SERDE serde_cls [WITH SERDEPROPERTIES (key1=val1, key2=val2, ...)]
        | DELIMITED [FIELDS TERMINATED BY char [ESCAPED BY char]]
            [COLLECTION ITEMS TERMINATED BY char]
            [MAP KEYS TERMINATED BY char]
            [LINES TERMINATED BY char]
            [NULL DEFINED AS char]

    file_format:
        : TEXTFILE | SEQUENCEFILE | RCFILE | ORC | PARQUET | AVRO
        | INPUTFORMAT input_fmt OUTPUTFORMAT output_fmt
    -- Create a table using the Hive format. If table same name exists, exception. When the table is dropped later, its data will be deleted from the file system. Note: This command is supported only when Hive support is enabled.
    -- EXTERNAL: The created table will use the custom directory specified with LOCATION. Queries on the table will be able to access any existing data previously stored in the directory. When an EXTERNAL table is dropped, its data is not deleted from the file system. This flag is implied if LOCATION is specified.
    -- IF NOT EXISTS: If a table with the same name already exists in the database, nothing will happen.
    -- PARTITIONED BY: The created table will be partitioned by the specified columns. This set of columns must be distinct from the set of non-partitioned columns. Partitioned columns may not be specified with AS <select_statement>.
    -- ROW FORMAT: Use the SERDE clause to specify a custom SerDe for this table. Otherwise, use the DELIMITED clause to use the native SerDe and specify the delimiter, escape character, null character etc.
    -- STORED AS: Specify the file format for this table. Available formats include TEXTFILE, SEQUENCEFILE, RCFILE, ORC, PARQUET and AVRO. Alternatively, the user may specify his own input and output formats through INPUTFORMAT and OUTPUTFORMAT. Note that only formats TEXTFILE, SEQUENCEFILE, and RCFILE may be used with ROW FORMAT SERDE, and only TEXTFILE may be used with ROW FORMAT DELIMITED.
    -- LOCATION: The created table will use the specified directory to store its data. This clause automatically implies EXTERNAL.
    -- AS <select_statement>: Populate the table with input data from the select statement. This may not be specified with PARTITIONED BY.
```
###### Examples:
``` sql
    CREATE TABLE my_table (name STRING, age INT)

    CREATE EXTERNAL TABLE IF NOT EXISTS my_table (name STRING, age INT)
        COMMENT 'This table is created with existing data'
        LOCATION 'spark-warehouse/tables/my_existing_table'

    CREATE TABLE my_table (name STRING, age INT)
        COMMENT 'This table is partitioned'
        PARTITIONED BY (hair_color STRING COMMENT 'This is a column comment')
        TBLPROPERTIES ('status'='staging', 'owner'='andrew')

    CREATE TABLE my_table (name STRING, age INT)
        COMMENT 'This table specifies a custom SerDe'
        ROW FORMAT SERDE 'org.apache.hadoop.hive.ql.io.orc.OrcSerde'
        STORED AS
            INPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcInputFormat'
            OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcOutputFormat'

    CREATE TABLE my_table (name STRING, age INT)
        COMMENT 'This table uses the CSV format'
        ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
        STORED AS TEXTFILE

    CREATE TABLE your_table
        COMMENT 'This table is created with existing data'
        AS SELECT * FROM my_table
```
##### Create Table Like
``` sql
    CREATE TABLE [IF NOT EXISTS] [db_name.]table_name1 LIKE [db_name.]table_name2
    -- Create a table using the metadata of an existing table. The created table always uses its own directory in the default warehouse location even if the existing table is EXTERNAL. The existing table must not be a temporary table.
```

#### Describe Database
``` sql
    DESCRIBE DATABASE [EXTENDED] db_name
    -- Return the metadata of an existing database (name, comment and location). If not exist, exception.
    -- EXTENDED: Also display the database properties.
```
#### Describe Function
``` sql
    DESCRIBE FUNCTION [EXTENDED] [db_name.]function_name
    -- Return the metadata of an existing function (implementing class and usage). If not exist, exception.
    -- EXTENDED: Also show extended usage information.
```
#### Describe Table
``` sql
    DESCRIBE [EXTENDED] [db_name.]table_name
    -- Return the metadata of an existing table (column names, data types, and comments). If not exist, exception.
    -- EXTENDED: Display detailed information about the table, including parent database, table type, storage information, and properties.
```
#### Drop Database
``` sql
    DROP (DATABASE|SCHEMA) [IF EXISTS] db_name [(RESTRICT|CASCADE)]
    -- Drop a database. If not exist, exception. This also deletes the directory associated with the database from the file system.
    -- IF EXISTS: If the database to drop does not exist, nothing will happen.
    -- RESTRICT: Dropping a non-empty database will trigger an exception. Enabled by default
    -- CASCADE: Dropping a non-empty database will also drop all associated tables and functions.
```
#### Drop Function
``` sql
    DROP [TEMPORARY] FUNCTION [IF EXISTS] [db_name.]function_name
    -- Drop an existing function. If not exist, exception. Note: This command is supported only when Hive support is enabled.
    -- TEMPORARY: Whether to function to drop is a temporary function.
    -- IF EXISTS: If the function to drop does not exist, nothing will happen.
```
#### Drop Table
``` sql
    DROP TABLE [IF EXISTS] [db_name.]table_name
    -- Drop a table. If not exist, exception. This also deletes the directory associated with the table from the file system if this is not an EXTERNAL table.
    -- IF EXISTS: If the table to drop does not exist, nothing will happen.
```
#### Explain
``` sql
    EXPLAIN [EXTENDED | CODEGEN] statement
    -- Provide detailed plan information about the given statement without actually running it. By default this only outputs information about the physical plan. Explaining `DESCRIBE TABLE` is not currently supported.
    -- EXTENDED: Also output information about the logical plan before and after analysis and optimization.
    -- CODEGEN: Output the generated code for the statement, if any.
```
#### Insert
``` sql
    INSERT INTO [TABLE] [db_name.]table_name [PARTITION part_spec] select_statement

    INSERT OVERWRITE TABLE [db_name.]table_name [PARTITION part_spec] select_statement

    part_spec:
        : (part_col_name1=val1, part_col_name2=val2, ...)
    -- Insert data into a table or a partition using a select statement.
    -- OVERWRITE: Whether to override existing data in the table or the partition. If this flag is not provided, the new data is appended.
```
#### Load Data
``` sql
    LOAD DATA [LOCAL] INPATH path [OVERWRITE] INTO TABLE [db_name.]table_name [PARTITION part_spec]

    part_spec:
        : (part_col_name1=val1, part_col_name2=val2, ...)
    -- Load data from a file into a table or a partition in the table. The target table must not be temporary. A partition spec must be provided if and only if the target table is partitioned. Note: This is only supported for tables created using the Hive format.
    -- LOCAL: If this flag is provided, the local file system will be used load the path. Otherwise, the default file system will be used.
    -- OVERWRITE: If this flag is provided, the existing data in the table will be deleted. Otherwise, the new data will be appended to the table.
```
#### Refresh Table
``` sql
    -- REFRESH TABLE [db_name.]table_name
    -- Refresh all cached entries associated with the table. If the table was previously cached, then it would be cached lazily the next time it is scanned.
```
#### Reset
``` sql
    -- RESET
    -- Reset all properties to their default values. The Set command output will be empty after this.
```
#### Select
``` sql
    SELECT [ALL|DISTINCT] named_expression[, named_expression, ...]
        FROM relation[, relation, ...]
        [lateral_view[, lateral_view, ...]]
        [WHERE boolean_expression]
        [aggregation [HAVING boolean_expression]]
        [ORDER BY sort_expressions]
        [CLUSTER BY expressions]
        [DISTRIBUTE BY expressions]
        [SORT BY sort_expressions]
        [WINDOW named_window[, WINDOW named_window, ...]]
        [LIMIT num_rows]

    named_expression:
        : expression [AS alias]

    relation:
        | join_relation
        | (table_name|query|relation) [sample] [AS alias]
        : VALUES (expressions)[, (expressions), ...]
              [AS (column_name[, column_name, ...])]

    expressions:
        : expression[, expression, ...]

    sort_expressions:
        : expression [ASC|DESC][, expression [ASC|DESC], ...]
    -- Output data from one or more relations.
    -- A relation here refers to any source of input data. It could be the contents of an existing table (or view), the joined result of two existing tables, or a subquery (the result of another select statement).
    -- ALL: Select all matching rows from the relation. Enabled by default.
    -- DISTINCT: Select all matching rows from the relation then remove duplicate results.
    -- WHERE: Filter rows by predicate.
    -- HAVING: Filter grouped result by predicate.
    -- ORDER BY: Impose total ordering on a set of expressions. Default sort direction is ascending. This may not be used with SORT BY, CLUSTER BY, or DISTRIBUTE BY.
    -- DISTRIBUTE BY: Repartition rows in the relation based on a set of expressions. Rows with the same expression values will be hashed to the same worker. This may not be used with ORDER BY or CLUSTER BY.
    -- SORT BY: Impose ordering on a set of expressions within each partition. Default sort direction is ascending. This may not be used with ORDER BY or CLUSTER BY.
    -- CLUSTER BY: Repartition rows in the relation based on a set of expressions and sort the rows in ascending order based on the expressions. In other words, this is a shorthand for DISTRIBUTE BY and SORT BY where all expressions are sorted in ascending order. This may not be used with ORDER BY, DISTRIBUTE BY, or SORT BY.
    -- WINDOW: Assign an identifier to a window specification (more details below).
    -- LIMIT: Limit the number of rows returned.
    -- VALUES: Explicitly specify values instead of reading them from a relation.
```
##### Examples:
``` sql
    SELECT * FROM boxes
    SELECT width, length FROM boxes WHERE height=3
    SELECT DISTINCT width, length FROM boxes WHERE height=3 LIMIT 2
    SELECT * FROM VALUES (1, 2, 3) AS (width, length, height)
    SELECT * FROM VALUES (1, 2, 3), (2, 3, 4) AS (width, length, height)
    SELECT * FROM boxes ORDER BY width
    SELECT * FROM boxes DISTRIBUTE BY width SORT BY width
    SELECT * FROM boxes CLUSTER BY length
```

##### Sampling
``` sql
    sample:
        | TABLESAMPLE ((integer_expression | decimal_expression) PERCENT)
        : TABLESAMPLE (integer_expression ROWS)
    -- Sample the input data. Currently, this can be expressed in terms of either a percentage (must be between 0 and 100) or a fixed number of input rows.
```
###### Examples:
``` sql
    SELECT * FROM boxes TABLESAMPLE (3 ROWS)
    SELECT * FROM boxes TABLESAMPLE (25 PERCENT)
```
##### Joins
``` sql
    join_relation:
        | relation join_type JOIN relation (ON boolean_expression | USING (column_name[, column_name, ...]))
        : relation NATURAL join_type JOIN relation
    join_type:
        | INNER
        | (LEFT|RIGHT) SEMI
        | (LEFT|RIGHT|FULL) [OUTER]
        : [LEFT] ANTI
    -- INNER JOIN: Select all rows from both relations where there is match.
    -- OUTER JOIN: Select all rows from both relations, filling with null values on the side that does not have a match.
    -- SEMI JOIN: Select only rows from the side of the SEMI JOIN where there is a match. If one row matches multiple rows, only the first match is returned.
    -- LEFT ANTI JOIN: Select only rows from the left side that match no rows on the right side.
```
###### Examples:
``` sql
    SELECT * FROM boxes INNER JOIN rectangles ON boxes.width = rectangles.width
    SELECT * FROM boxes FULL OUTER JOIN rectangles USING (width, length)
    SELECT * FROM boxes NATURAL JOIN rectangles
```
##### Lateral View
``` sql
    lateral_view:
        : LATERAL VIEW [OUTER] function_name (expressions)
              table_name [AS (column_name[, column_name, ...])]
    -- Generate zero or more output rows for each input row using a table-generating function. The most common built-in function used with LATERAL VIEW is explode.
    -- LATERAL VIEW OUTER: Generate a row with null values even when the function returned zero rows.
```
###### Examples:
``` sql
    SELECT * FROM boxes LATERAL VIEW explode(Array(1, 2, 3)) my_view
    SELECT name, my_view.grade FROM students LATERAL VIEW OUTER explode(grades) my_view AS grade
```
##### Aggregation
``` sql
    aggregation:
        : GROUP BY expressions [(WITH ROLLUP | WITH CUBE | GROUPING SETS (expressions))]
    -- Group by a set of expressions using one or more aggregate functions. Common built-in aggregate functions include count, avg, min, max, and sum.

    -- ROLLUP: Create a grouping set at each hierarchical level of the specified expressions. For instance, For instance, GROUP BY a, b, c WITH ROLLUP is equivalent to GROUP BY a, b, c GROUPING SETS ((a, b, c), (a, b), (a), ()). The total number of grouping sets will be N + 1, where N is the number of group expressions.
    -- CUBE: Create a grouping set for each possible combination of set of the specified expressions. For instance, GROUP BY a, b, c WITH CUBE is equivalent to GROUP BY a, b, c GROUPING SETS ((a, b, c), (a, b), (b, c), (a, c), (a), (b), (c), ()). The total number of grouping sets will be 2^N, where N is the number of group expressions.
    -- GROUPING SETS: Perform a group by for each subset of the group expressions specified in the grouping sets. For instance, GROUP BY x, y GROUPING SETS (x, y) is equivalent to the result of GROUP BY x unioned with that of GROUP BY y.
```
###### Examples:
``` sql
    SELECT height, COUNT(*) AS num_rows FROM boxes GROUP BY height
    SELECT width, AVG(length) AS average_length FROM boxes GROUP BY width
    SELECT width, length, height FROM boxes GROUP BY width, length, height WITH ROLLUP
    SELECT width, length, avg(height) FROM boxes GROUP BY width, length GROUPING SETS (width, length)
```
##### Window Functions
``` sql
    window_expression:
        : expression OVER window_spec

    named_window:
        : window_identifier AS window_spec

    window_spec:
        | window_identifier
        : ((PARTITION|DISTRIBUTE) BY expressions
              [(ORDER|SORT) BY sort_expressions] [window_frame])

    window_frame:
        | (RANGE|ROWS) frame_bound
        : (RANGE|ROWS) BETWEEN frame_bound AND frame_bound

    frame_bound:
        | CURRENT ROW
        | UNBOUNDED (PRECEDING|FOLLOWING)
        : expression (PRECEDING|FOLLOWING)
    -- Compute a result over a range of input rows. A windowed expression is specified using the OVER keyword, which is followed by either an identifier to the window (defined using the WINDOW keyword) or the specification of a window.
    -- PARTITION BY: Specify which rows will be in the same partition, aliased by DISTRIBUTE BY.
    -- ORDER BY: Specify how rows within a window partition are ordered, aliased by SORT BY.
    -- RANGE bound: Express the size of the window in terms of a value range for the expression.
    -- ROWS bound: Express the size of the window in terms of the number of rows before and/or after the current row.
    -- CURRENT ROW: Use the current row as a bound.
    -- UNBOUNDED: Use negative infinity as the lower bound or infinity as the upper bound.
    -- PRECEDING: If used with a RANGE bound, this defines the lower bound of the value range. If used with a ROWS bound, this determines the number of rows before the current row to keep in the window.
    -- FOLLOWING: If used with a RANGE bound, this defines the upper bound of the value range. If used with a ROWS bound, this determines the number of rows after the current row to keep in the window.
```


#### Set
``` sql
    SET [-v]
    SET property_key[=property_value]
    -- Set a property, return the value of an existing property, or list all existing properties. If existing, overridden.
    -- -v: Also output the meaning of the existing properties.
    -- <property_key>: Set or return the value of an individual property.
```
#### Show Columns
``` sql
    SHOW COLUMNS (FROM | IN) [db_name.]table_name
    -- Return the list of columns in a table. If table not exist, exception
```
#### Show Create Table
``` sql
    SHOW CREATE TABLE [db_name.]table_name
    -- Return the command used to create an existing table. If table not exist, exception.
```
#### Show Functions
``` sql
    -- SHOW [USER|SYSTEM|ALL] FUNCTIONS ([LIKE] regex | [db_name.]function_name)
    -- Show functions matching the given regex or function name. If no regex or name is provided then all functions will be shown. IF USER or SYSTEM is declared then these will only show user-defined Spark SQL functions and system-defined Spark SQL functions respectively.

    -- LIKE: This qualifier is allowed only for compatibility and has no effect.
```
#### Show Partitions
``` sql
    SHOW PARTITIONS [db_name.]table_name [PARTITION part_spec]

    part_spec:
        : (part_col_name1=val1, part_col_name2=val2, ...)
    -- List the partitions of a table, filtering by given partition values. Listing partitions is only supported for tables created using the Hive format and only when the Hive support is enabled.
```
#### Show Table Properties
``` sql
    SHOW TBLPROPERTIES [db_name.]table_name [(property_key)]
    -- Return all properties or the value of a specific property set in a table. If table not exist, exception.
```
#### Truncate Table
``` sql
    TRUNCATE TABLE table_name [PARTITION part_spec]

    part_spec:
        : (part_col1=value1, part_col2=value2, ...)
    -- Delete all rows from a table or matching partitions in the table. The table must not be a temporary table, an external table, or a view.

    -- PARTITION: Specify a partial partition spec to match partitions to be truncated. This is only supported for tables created using the Hive format.
```
#### Uncache Table
``` sql
    UNCACHE TABLE [db_name.]table_name
    -- Drop all cached entries associated with the table.
```
#### Use Database
``` sql
    USE db_name
    -- Set the current database. All subsequent commands that do not explicitly specify a database will use this one. If not exist, exception. The default current database is “default”.
```

### Spark SQL Examples
#### Transforming Complex Data Types
##### Transforming Complex Data Types in Scala
``` scala
    // Spark SQL supports many built-in transformation functions in the module org.apache.spark.sql.functions._ therefore we will start off by importing that.
    import org.apache.spark.sql.DataFrame
    import org.apache.spark.sql.functions._
    import org.apache.spark.sql.types._

    // Convenience function for turning JSON strings into DataFrames.
    def jsonToDataFrame(json: String, schema: StructType = null): DataFrame = {
      // SparkSessions are available with Spark 2.0+
      val reader = spark.read
      Option(schema).foreach(reader.schema)
      reader.json(sc.parallelize(Array(json)))
    }
    import org.apache.spark.sql.DataFrame
    import org.apache.spark.sql.functions._
    import org.apache.spark.sql.types._
    jsonToDataFrame: (json: String, schema: org.apache.spark.sql.types.StructType)org.apache.spark.sql.DataFrame

    //Selecting from nested columns - Dots (".") can be used to access nested columns for structs and maps.
    // Using a struct
    val schema = new StructType().add("a", new StructType().add("b", IntegerType))
                              
    val events = jsonToDataFrame("""
    {
      "a": {
         "b": 1
      }
    }
    """, schema)

    display(events.select("a.b"))
    1
    b
     // Using a map
    val schema = new StructType().add("a", MapType(StringType, IntegerType))
                              
    val events = jsonToDataFrame("""
    {
      "a": {
         "b": 1
      }
    }
    """, schema)

    display(events.select("a.b"))
    1
    b
    // Flattening structs - A star ("*") can be used to select all of the subfields in a struct.
    val events = jsonToDataFrame("""
    {
      "a": {
         "b": 1,
         "c": 2
      }
    }
    """)

    display(events.select("a.*"))
    1   2
    b   c
    // Nesting columns - The struct() function or just parentheses in SQL can be used to create a new struct.
    val events = jsonToDataFrame("""
    {
      "a": 1,
      "b": 2,
      "c": 3
    }
    """)

    display(events.select(struct('a as 'y) as 'x))
    {"y":1}
    x
    // Nesting all columns - The star ("*") can also be used to include all columns in a nested struct.
    val events = jsonToDataFrame("""
    {
      "a": 1,
      "b": 2
    }
    """)

    display(events.select(struct("*") as 'x))
    {"a":1,"b":2}
    x
    // Selecting a single array or map element - getItem() or square brackets (i.e. [ ]) can be used to select a single element out of an array or a map.
    val events = jsonToDataFrame("""
    {
      "a": [1, 2]
    }
    """)

    display(events.select('a.getItem(0) as 'x))
    1
    x
     // Using a map
    val schema = new StructType().add("a", MapType(StringType, IntegerType))

    val events = jsonToDataFrame("""
    {
      "a": {
        "b": 1
      }
    }
    """, schema)

    display(events.select('a.getItem("b") as 'x))
    1
    x
    // Creating a row for each array or map element - explode() can be used to create a new row for each element in an array or each key-value pair. This is similar to LATERAL VIEW EXPLODE in HiveQL.
    val events = jsonToDataFrame("""
    {
      "a": [1, 2]
    }
    """)

    display(events.select(explode('a) as 'x))
    1
    2
    x
     // Using a map
    val schema = new StructType().add("a", MapType(StringType, IntegerType))

    val events = jsonToDataFrame("""
    {
      "a": {
        "b": 1,
        "c": 2
      }
    }
    """, schema)

    display(events.select(explode('a) as (Seq("x", "y"))))
    b   1
    c   2
    x   y
    // Collecting multiple rows into an array - collect_list() and collect_set() can be used to aggregate items into an array.
    val events = jsonToDataFrame("""
    [{ "x": 1 }, { "x": 2 }]
    """)

    display(events.select(collect_list('x) as 'x))
    [1,2]
    x
     // using an aggregation
    val events = jsonToDataFrame("""
    [{ "x": 1, "y": "a" }, { "x": 2, "y": "b" }]
    """)

    display(events.groupBy("y").agg(collect_list('x) as 'x))
    b   [2]
    a   [1]
    y   x
    
    // Selecting one field from each item in an array - when you use dot notation on an array we return a new array where that field has been selected from each array element.
    val events = jsonToDataFrame("""
    {
      "a": [
        {"b": 1},
        {"b": 2}
      ]
    }
    """)

    display(events.select("a.b"))
    [1,2]
    b
    
    // Convert a group of columns to json - to_json() can be used to turn structs into json strings. This method is particularly useful when you would like to re-encode multiple columns into a single one when writing data out to Kafka. This method is not presently available in SQL.
    val events = jsonToDataFrame("""
    {
      "a": {
        "b": 1
      }
    }
    """)

    display(events.select(to_json('a) as 'c))
    {"b":1}
    c
    
    // Parse a column containing json - from_json() can be used to turn a string column with json data into a struct. Then you may flatten the struct as described above to have individual columns. This method is not presently available in SQL. This method is available since Spark 2.1
    val events = jsonToDataFrame("""
    {
      "a": "{\"b\":1}"
    }
    """)

    val schema = new StructType().add("b", IntegerType)
    display(events.select(from_json('a, schema) as 'c))
    {"b":1}
    c
    
    // Sometimes you may want to leave a part of the JSON string still as JSON to avoid too much complexity in your schema.
    val events = jsonToDataFrame("""
    {
      "a": "{\"b\":{\"x\":1,\"y\":{\"z\":2}}}"
    }
    """)

    val schema = new StructType().add("b", new StructType().add("x", IntegerType)
      .add("y", StringType))
    display(events.select(from_json('a, schema) as 'c))
    {"b":{"x":1,"y":"{\"z\":2}"}}
    c
    
    // Parse a set of fields from a column containing json - json_tuple() can be used to extract a fields available in a string column with json data.
    val events = jsonToDataFrame("""
    {
      "a": "{\"b\":1}"
    }
    """)

    display(events.select(json_tuple('a, "b") as 'c))
    1
    c
    
    // Parse a well formed string column - regexp_extract() can be used to parse strings using regular expressions.
    val events = jsonToDataFrame("""
    [{ "a": "x: 1" }, { "a": "y: 2" }]
    """)

    display(events.select(regexp_extract('a, "([a-z]):", 1) as 'c))
    x
    y
    c

```
#### Data Skipping Index
#### Transactional Writes to Cloud Storage with DBIO
#### Higher Order Functions
#### Task Preemption for High Concurrency
#### Query Watchdog
#### User Defined Aggregate Functions - Scala
##### Implement the UserDefinedAggregateFunction
``` scala
    import org.apache.spark.sql.expressions.MutableAggregationBuffer
    import org.apache.spark.sql.expressions.UserDefinedAggregateFunction
    import org.apache.spark.sql.Row
    import org.apache.spark.sql.types._

    class GeometricMean extends UserDefinedAggregateFunction {
      // This is the input fields for your aggregate function.
      override def inputSchema: org.apache.spark.sql.types.StructType =
        StructType(StructField("value", DoubleType) :: Nil)

      // This is the internal fields you keep for computing your aggregate.
      override def bufferSchema: StructType = StructType(
        StructField("count", LongType) ::
        StructField("product", DoubleType) :: Nil
      )

      // This is the output type of your aggregatation function.
      override def dataType: DataType = DoubleType

      override def deterministic: Boolean = true

      // This is the initial value for your buffer schema.
      override def initialize(buffer: MutableAggregationBuffer): Unit = {
        buffer(0) = 0L
        buffer(1) = 1.0
      }

      // This is how to update your buffer schema given an input.
      override def update(buffer: MutableAggregationBuffer, input: Row): Unit = {
        buffer(0) = buffer.getAs[Long](0) + 1
        buffer(1) = buffer.getAs[Double](1) * input.getAs[Double](0)
      }

      // This is how to merge two objects with the bufferSchema type.
      override def merge(buffer1: MutableAggregationBuffer, buffer2: Row): Unit = {
        buffer1(0) = buffer1.getAs[Long](0) + buffer2.getAs[Long](0)
        buffer1(1) = buffer1.getAs[Double](1) * buffer2.getAs[Double](1)
      }

      // This is where you output the final value, given the final value of your bufferSchema.
      override def evaluate(buffer: Row): Any = {
        math.pow(buffer.getDouble(1), 1.toDouble / buffer.getLong(0))
      }
    }
```
##### Register the UDAF with Spark SQL
``` scala
    sqlContext.udf.register("gm", new GeometricMean)
```
##### Use your UDAF
``` scala
    // Create a DataFrame and Spark SQL Table to query.
    import org.apache.spark.sql.functions._

    val ids = sqlContext.range(1, 20)
    ids.registerTempTable("ids")
    val df = sqlContext.sql("select id, id % 3 as group_id from ids")
    df.registerTempTable("simple")
   
    // Or use Dataframe syntax to call the aggregate function.
    // Create an instance of UDAF GeometricMean.
    val gm = new GeometricMean

    // Show the geometric mean of values of column "id".
    df.groupBy("group_id").agg(gm(col("id")).as("GeometricMean")).show()

    // Invoke the UDAF by its assigned name.
    df.groupBy("group_id").agg(expr("gm(id) as GeometricMean")).show()
```
``` sql
    -- Use a group_by statement and call the UDAF.
    select group_id, gm(id) from simple group by group_id
```

#### User Defined Functions - Scala
##### Register the function as a UDF
``` sql
    val squared = (s: Int) => {
      s * s
    }
    sqlContext.udf.register("square", squared)
```
##### Call the UDF in Spark SQL
``` sql
    sqlContext.range(1, 20).registerTempTable("test")
    // %sql select id, square(id) as id_squared from test
```


### Compatibility with other systems
#### SerDes and UDFs
Currently Hive SerDes and UDFs are based on Hive 1.2.1.
#### Metastore Connectivity
#### Supported Hive Features
Spark SQL supports the vast majority of Hive features, such as:
- Hive query statements, including:
    + SELECT
    + GROUP BY
    + ORDER BY
    + CLUSTER BY
    + SORT BY
- All Hive expressions, including:
    + Relational expressions (=, ⇔, ==, <>, <, >, >=, <=, etc)
    + Arithmetic expressions (+, -, *, /, %, etc)
    + Logical expressions (AND, &&, OR, ||, etc)
    + Complex type constructors
    + Mathematical expressions (sign, ln, cos, etc)
    + String expressions (instr, length, printf, etc)
- User defined functions (UDF)
- User defined aggregation functions (UDAF)
- User defined serialization formats (SerDes)
- Window functions
- Joins
    + JOIN
    + {LEFT|RIGHT|FULL} OUTER JOIN
    + LEFT SEMI JOIN
    + CROSS JOIN
- Unions
- Sub-queries
    + SELECT col FROM ( SELECT a + b AS col from t1) t2
- Sampling
- Explain
- Partitioned tables including dynamic partition insertion
- View
- Vast majority of DDL statements, including:
    + CREATE TABLE
    + CREATE TABLE AS SELECT
    + ALTER TABLE
- Most Hive Data types, including:
    + TINYINT
    + SMALLINT
    + INT
    + BIGINT
    + BOOLEAN
    + FLOAT
    + DOUBLE
    + STRING
    + BINARY
    + TIMESTAMP
    + DATE
    + ARRAY<>
    + MAP<>
    + STRUCT<>

#### Unsupported Hive Functionality
##### Major Hive Features
##### Esoteric Hive Features
##### Hive Input/Output Formats

##### Hive Optimizations


## Hive LanguageManual

### File Formats

#### SerDe
- STORED AS AVRO 
    + ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.avro.AvroSerDe' STORED AS INPUTFORMAT 'org.apache.hadoop.hive.ql.io.avro.AvroContainerInputFormat' OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.avro.AvroContainerOutputFormat'
- STORED AS ORC
    + ROW FORMAT SERDE 'org.apache.hadoop.hive.ql.io.orc.OrcSerde' STORED AS INPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcInputFormat' OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcOutputFormat'
- STORED AS PARQUET
    + ROW FORMAT SERDE 'org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe' STORED AS INPUTFORMAT 'org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat' OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat'
- STORED AS RCFILE
    + STORED AS INPUTFORMAT 'org.apache.hadoop.hive.ql.io.RCFileInputFormat' OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.RCFileOutputFormat' 
- STORED AS SEQUENCEFILE
    + STORED AS INPUTFORMAT 'org.apache.hadoop.mapred.SequenceFileInputFormat' OUTPUTFORMAT 'org.apache.hadoop.mapred.SequenceFileOutputFormat'
- STORED AS TEXTFILE
    + STORED AS INPUTFORMAT 'org.apache.hadoop.mapred.TextInputFormat' OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.IgnoreKeyTextOutputFormat'
    + ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.RegexSerDe' WITH SERDEPROPERTIES ("input.regex" = "regEx") STORED AS TEXTFILE;
    + ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde' WITH SERDEPROPERTIES ("separatorChar" = "\t", "quoteChar" = "'", "escapeChar" = "\\") STORED AS TEXTFILE;
    + ROW FORMAT SERDE 'org.apache.hive.hcatalog.data.JsonSerDe' STORED AS TEXTFILE;

#### Avro

#### ORC

#### Parquet

#### Compressed Data Storage

#### LZO Compression


### DataType
|Data type|Value type in Scala|API to access or create a data type|
|:--|:--|:--|
|ByteType|Byte|ByteType|
|ShortType|Short|ShortType|
|IntegerType|Int|IntegerType|
|LongType|Long|LongType|
|FloatType|Float|FloatType|
|DoubleType|Double|DoubleType|
|DecimalType|java.math.BigDecimal|DecimalType|
|StringType|String|StringType|
|BinaryType|Array[Byte]|BinaryType|
|BooleanType|Boolean|BooleanType|
|TimestampType|java.sql.Timestamp|TimestampType|
|DateType|java.sql.Date|DateType|
|ArrayType|scala.collection.Seq|ArrayType(elementType, [containsNull])|
|||Note: The default value of containsNull is true.|
|MapType|scala.collection.Map|MapType(keyType, valueType, [valueContainsNull])|
|||Note: The default value of valueContainsNull is true.|
|StructType|org.apache.spark.sql.Row|StructType(fields)|
|||Note: fields is a Seq of StructFields. Also, two fields with the same name are not allowed.|
|StructField|The value type in Scala of the data type of this field (For example, Int for a StructField with the data type IntegerType)|StructField(name, dataType, [nullable])|
|||Note: The default value of nullable is true|

### DDL Data Definition Statements
#### Overview
- HiveQL DDL statements are documented here, including:
    + CREATE DATABASE/SCHEMA, TABLE, VIEW, FUNCTION, INDEX
    + DROP DATABASE/SCHEMA, TABLE, VIEW, INDEX
    + TRUNCATE TABLE
    + ALTER DATABASE/SCHEMA, TABLE, VIEW
    + MSCK REPAIR TABLE (or ALTER TABLE RECOVER PARTITIONS)
    + SHOW DATABASES/SCHEMAS, TABLES, TBLPROPERTIES, VIEWS, PARTITIONS, FUNCTIONS, INDEX[ES], COLUMNS, CREATE TABLE
    + DESCRIBE DATABASE/SCHEMA, table_name, view_name
- PARTITION statements are usually options of TABLE statements, except for SHOW PARTITIONS.

#### Create/Drop/Alter/Use Database
##### Create Database
``` sql
    CREATE (DATABASE|SCHEMA) [IF NOT EXISTS] database_name
    [COMMENT database_comment]
    [LOCATION hdfs_path]
    [WITH DBPROPERTIES (property_name=property_value, ...)];
```
##### Drop Database
``` sql
    DROP (DATABASE|SCHEMA) [IF EXISTS] database_name [RESTRICT|CASCADE];
    -- The default behavior is RESTRICT, where DROP DATABASE will fail if the database is not empty. To drop the tables in the database as well, use DROP DATABASE ... CASCADE
```
##### Alter Database
``` sql
    ALTER (DATABASE|SCHEMA) database_name SET DBPROPERTIES (property_name=property_value, ...)
    ALTER (DATABASE|SCHEMA) database_name SET OWNER [USER|ROLE] user_or_role
```
##### Use Database
``` sql
    USE database_name;  -- To check which database is currently being used: SELECT current_database()
    USE DEFAULT;
```

#### Create/Drop/Truncate Table
##### Create Table
``` sql
    CREATE [TEMPORARY] [EXTENAL] TABLE [IF NOT EXISTS] [db_name.]table_name
    [(
        col_name data_type [COMMENT col_comment], 
        ... 
        [constraint_specification]
    )]
    [COMMENT table_comment]
    [PARTITIONED BY (col_name data_type [COMMENT col_comment], ...)]
    [CLUSTERED BY (col_name, col_name, ...) [SORTED BY (col_name [ASC|DESC], ...)] INTO num_buckets BUCKETS]
    [SKEWED BY (col_name, col_name, ...)]
        ON ((col_value, col_value, ...), (col_value, col_value, ...), ...)
        [STORED AS DIRECTORIES]
    [
        [ROW FORMAT row_format]
        [STORED AS file_format]
            | STORED BY 'storage.handler.class.name' [WITH SERDEPROPERTIES (...)]
    ]
    [LOCATION hdfs_path]
    [TBLPROPERTIES (property_name=property_value, ...)]
    [AS select_statement];

    CREATE [TEMPORARY] [EXTERNAL] TABLE [IF NOT EXISTS] [db_name.]table_name
        LIKE existing_table_or_view_name
        [LOCATION hdfs_path];

    -- CREATE TABLE creates a table with the given name. An error is thrown if a table or view with the same name already exists. You can use IF NOT EXISTS to skip the error.

    data_type
      : primitive_type
      | array_type
      | map_type
      | struct_type
      | union_type  -- (Note: Available in Hive 0.7.0 and later)
     
    primitive_type
      : TINYINT
      | SMALLINT
      | INT
      | BIGINT
      | BOOLEAN
      | FLOAT
      | DOUBLE
      | DOUBLE PRECISION -- (Note: Available in Hive 2.2.0 and later)
      | STRING
      | BINARY      -- (Note: Available in Hive 0.8.0 and later)
      | TIMESTAMP   -- (Note: Available in Hive 0.8.0 and later)
      | DECIMAL     -- (Note: Available in Hive 0.11.0 and later)
      | DECIMAL(precision, scale)  -- (Note: Available in Hive 0.13.0 and later)
      | DATE        -- (Note: Available in Hive 0.12.0 and later)
      | VARCHAR     -- (Note: Available in Hive 0.12.0 and later)
      | CHAR        -- (Note: Available in Hive 0.13.0 and later)
     
    array_type
      : ARRAY < data_type >
     
    map_type
      : MAP < primitive_type, data_type >
     
    struct_type
      : STRUCT < col_name : data_type [COMMENT col_comment], ...>
     
    union_type
       : UNIONTYPE < data_type, data_type, ... >  -- (Note: Available in Hive 0.7.0 and later)
     
    row_format
      : DELIMITED [FIELDS TERMINATED BY char [ESCAPED BY char]] [COLLECTION ITEMS TERMINATED BY char]
            [MAP KEYS TERMINATED BY char] [LINES TERMINATED BY char]
            [NULL DEFINED AS char]   -- (Note: Available in Hive 0.13 and later)
      | SERDE serde_name [WITH SERDEPROPERTIES (property_name=property_value, property_name=property_value, ...)]
     
    file_format:
      : SEQUENCEFILE
      | TEXTFILE    -- (Default, depending on hive.default.fileformat configuration)
      | RCFILE      -- (Note: Available in Hive 0.6.0 and later)
      | ORC         -- (Note: Available in Hive 0.11.0 and later)
      | PARQUET     -- (Note: Available in Hive 0.13.0 and later)
      | AVRO        -- (Note: Available in Hive 0.14.0 and later)
      | INPUTFORMAT input_format_classname OUTPUTFORMAT output_format_classname
     
    constraint_specification:
      : [, PRIMARY KEY (col_name, ...) DISABLE NOVALIDATE ]
        [, CONSTRAINT constraint_name FOREIGN KEY (col_name, ...) REFERENCES table_name(col_name, ...) DISABLE NOVALIDATE 
```
###### Managed and External Tables
- managed tables(default):files, metadata and statistics are managed by internal Hive processes. A managed table is stored under the hive.metastore.warehouse.dir path property
``` sql 
    CREATE TABLE page_view(viewTime INT, userid BIGINT,
         page_url STRING, referrer_url STRING,
         ip STRING COMMENT 'IP Address of the User')
     COMMENT 'This is the page view table'
     PARTITIONED BY(dt STRING, country STRING)
     ROW FORMAT DELIMITED
       FIELDS TERMINATED BY '\001'
    STORED AS SEQUENCEFILE;
```

- external table: metadata / schema on external files. External table files can be accessed and managed by processes outside of Hive.
``` sql
    CREATE EXTERNAL TABLE page_view(viewTime INT, userid BIGINT,
         page_url STRING, referrer_url STRING,
         ip STRING COMMENT 'IP Address of the User',
         country STRING COMMENT 'country of origination')
     COMMENT 'This is the staging page view table'
     ROW FORMAT DELIMITED FIELDS TERMINATED BY '\054'
     STORED AS TEXTFILE
     LOCATION '<hdfs_location>';
```
- Create Table As Select (CTAS)
``` sql
    CREATE TABLE new_key_value_store
       ROW FORMAT SERDE "org.apache.hadoop.hive.serde2.columnar.ColumnarSerDe"
       STORED AS RCFile
       AS
    SELECT (key % 1024) new_key, concat(key, value) key_value_pair
    FROM key_value_store
    SORT BY new_key, key_value_pair;
```
- Create Table Like
``` sql
    CREATE TABLE empty_key_value_store
    LIKE key_value_store;
```
- Bucketed Sorted Tables
``` sql
    CREATE TABLE page_view(viewTime INT, userid BIGINT,
         page_url STRING, referrer_url STRING,
         ip STRING COMMENT 'IP Address of the User')
     COMMENT 'This is the page view table'
     PARTITIONED BY(dt STRING, country STRING)
     CLUSTERED BY(userid) SORTED BY(viewTime) INTO 32 BUCKETS
     ROW FORMAT DELIMITED
       FIELDS TERMINATED BY '\001'
       COLLECTION ITEMS TERMINATED BY '\002'
       MAP KEYS TERMINATED BY '\003'
     STORED AS SEQUENCEFILE;
```
- Skewed Tables
``` sql
    CREATE TABLE list_bucket_single (key STRING, value STRING)
      SKEWED BY (key) ON (1,5,6) [STORED AS DIRECTORIES];

    CREATE TABLE list_bucket_multiple (col1 STRING, col2 int, col3 STRING)
      SKEWED BY (col1, col2) ON (('s1',1), ('s3',3), ('s13',13), ('s78',78)) [STORED AS DIRECTORIES];
```
- Temporary Tables
- Constraints
``` sql
    create table pk(id1 integer, id2 integer,
      primary key(id1, id2) disable novalidate);
     
    create table fk(id1 integer, id2 integer,
      constraint c1 foreign key(id1, id2) references pk(id2, id1) disable novalidate);
```


###### Storage Formats

##### Drop Table
``` sql
    DROP TABLE [IF EXISTS] table_name [PURGE];
    -- DROP TABLE removes metadata and data for this table. The data is actually moved to the .Trash/Current directory if Trash is configured (and PURGE is not specified). The metadata is completely lost.
```

##### Truncate Table
``` sql
    TRUNCATE TABLE table_name [PARTITION partition_spec];
    partition_spec:
        :(partition_column = partition_col_value, partition_column = partition_col_value, ...)
    -- User can specify partial partition_spec for truncating multiple partitions at once and omitting partition_spec will truncate all partitions in the table
```

#### Alter Table/Partition/Column
##### Alter Table
###### Rename Table

###### Alter Table Properties

###### Add SerDe Properties

###### Alter Table Storage Properties

###### Alter Table Skewed or Stored as Directories
- Alter Table Skewed
- Alter Table Not Skewed
- Alter Table Not Stored as Directories
- Alter Table Set Skewed Location

###### Alter Table Constraints

###### Additional Alter Table Statements


##### Alter Partition
###### Add Partitions
- Dynamic Partitions

###### Rename Partition
###### Exchange Partition
###### Recover Partitions (MSCK REPAIR TABLE)
###### Drop Partitions
###### (Un)Archive Partition

##### Alter Either Table or Partition
###### Alter Table/Partition File Format
###### Alter Table/Partition Location
###### Alter Table/Partition Touch
###### Alter Table/Partition Protections
###### Alter Table/Partition Compact
###### Alter Table/Partition Concatenate

##### Alter Column
###### Rules for Column Names
###### Change Column Name/Type/Position/Comment
###### Add/Replace Columns
###### Partial Partition Specification


#### Create/Drop/Alter View
##### Create View
##### Drop View
##### Alter View Properties
##### Alter View As Select

#### Create/Drop/Alter Index


#### Create/Drop/Reload Function


#### Create/Drop/Grant/Revoke Roles and Privileges
##### CREATE ROLE
##### GRANT ROLE
##### REVOKE ROLE
##### GRANT privilege_type
##### REVOKE privilege_type
##### DROP ROLE
##### SHOW ROLE GRANT
##### SHOW GRANT
##### Role Management Commands
###### CREATE ROLE
###### GRANT ROLE
###### REVOKE ROLE
###### DROP ROLE
###### SHOW ROLES
###### SHOW ROLE GRANT
###### SHOW CURRENT ROLES
###### SET ROLE
###### SHOW PRINCIPALS
##### Object Privilege Commands
###### GRANT privilege_type
###### REVOKE privilege_type
###### SHOW GRANT

#### Show

##### Show Databases
##### Show Tables/Views/Partitions/Indexes
- Show Tables
- Show Views
- Show Table/Partition Extended
- Show Table Properties
- Show Create Table
- Show Indexes

##### Show Columns
##### Show Functions
##### Show Granted Roles and Privileges
- SHOW ROLE GRANT
- SHOW GRANT
- SHOW ROLE GRANT
- SHOW GRANT
- SHOW CURRENT ROLES
- SHOW ROLES
- SHOW PRINCIPALS

##### Show Locks
##### Show Conf
##### Show Transactions
##### Show Compactions

#### Describe
##### Describe Database
##### Describe Table/View/Column
- Display Column Statistics

##### Describe Partition



### DML Data Manipulation Statements
#### DML: Load, Insert, Update, Delete
##### Loading files into tables
Hive does not do any transformation while loading data into tables. Load operations are currently pure copy/move operations that move datafiles into locations corresponding to Hive tables.
###### Syntax
``` sql
    LOAD DATA [LOCAL] INPATH 'filepath' [OVERWRITE] INTO TABLE tablename [PARTITION (partcol1=val1, partcol2=val2 ...)]
```
###### Synopsis(概要)
- Load operations are currently pure copy/move operations that move datafiles into locations corresponding to Hive tables.
    + filepath can be:
        * a relative path, such as project/data1
        * an absolute path, such as /user/hive/project/data1
        * a full URI with scheme and (optionally) an authority, such as hdfs://namenode:9000/user/hive/project/data1
    + The target being loaded to can be a table or a partition. If the table is partitioned, then one must specify a specific partition of the table by specifying values for all of the partitioning columns.
    + filepath can refer to a file (in which case Hive will move the file into the table) or it can be a directory (in which case Hive will move all the files within that directory into the table). In either case, filepath addresses a set of files.
    + If the keyword LOCAL is specified, then:
        * the load command will look for filepath in the local file system. If a relative path is specified, it will be interpreted relative to the user's current working directory. The user can specify a full URI for local files as well - for example: file:///user/hive/project/data1
        * the load command will try to copy all the files addressed by filepath to the target filesystem. The target file system is inferred by looking at the location attribute of the table. The copied data files will then be moved to the table.
    + If the keyword LOCAL is not specified, then Hive will either use the full URI of filepath, if one is specified, or will apply the following rules:
        * If scheme or authority are not specified, Hive will use the scheme and authority from the hadoop configuration variable fs.default.name that specifies the Namenode URI.
        * If the path is not absolute, then Hive will interpret it relative to /user/<username>
        * Hive will move the files addressed by filepath into the table (or partition)
    + If the OVERWRITE keyword is used then the contents of the target table (or partition) will be deleted and replaced by the files referred to by filepath; otherwise the files referred by filepath will be added to the table.
- Notes
    + filepath cannot contain subdirectories.
    + If the keyword LOCAL is not given, filepath must refer to files within the same filesystem as the table's (or partition's) location.
    + Hive does some minimal checks to make sure that the files being loaded match the target table. Currently it checks that if the table is stored in sequencefile format, the files being loaded are also sequencefiles, and vice versa.
    + A bug that prevented loading a file when its name includes the "+" character is fixed in release 0.13.0 (HIVE-6048).
    + Please read CompressedStorage if your datafile is compressed.
    
##### Inserting data into Hive Tables from queries
Query Results can be inserted into tables by using the insert clause.
###### Syntax
``` sql
    -- Standard syntax:
    INSERT OVERWRITE TABLE tablename1 [PARTITION (partcol1=val1, partcol2=val2 ...) [IF NOT EXISTS]] select_statement1 FROM from_statement;
    INSERT INTO TABLE tablename1 [PARTITION (partcol1=val1, partcol2=val2 ...)] select_statement1 FROM from_statement;
     
    -- Hive extension (multiple inserts):
    FROM from_statement
    INSERT OVERWRITE TABLE tablename1 [PARTITION (partcol1=val1, partcol2=val2 ...) [IF NOT EXISTS]] select_statement1
    [INSERT OVERWRITE TABLE tablename2 [PARTITION ... [IF NOT EXISTS]] select_statement2]
    [INSERT INTO TABLE tablename2 [PARTITION ...] select_statement2] ...;
    FROM from_statement
    INSERT INTO TABLE tablename1 [PARTITION (partcol1=val1, partcol2=val2 ...)] select_statement1
    [INSERT INTO TABLE tablename2 [PARTITION ...] select_statement2]
    [INSERT OVERWRITE TABLE tablename2 [PARTITION ... [IF NOT EXISTS]] select_statement2] ...;
     
    -- Hive extension (dynamic partition inserts):
    INSERT OVERWRITE TABLE tablename PARTITION (partcol1[=val1], partcol2[=val2] ...) select_statement FROM from_statement;
    INSERT INTO TABLE tablename PARTITION (partcol1[=val1], partcol2[=val2] ...) select_statement FROM from_statement;
```
###### Dynamic Partition Inserts
- Example
``` sql
    FROM page_view_stg pvs
    INSERT OVERWRITE TABLE page_view PARTITION(dt='2008-06-08', country)
           SELECT pvs.viewTime, pvs.userid, pvs.page_url, pvs.referrer_url, null, null, pvs.ip, pvs.cnt
```

##### Writing data into the filesystem from queries
###### Syntax
``` sql
    -- Standard syntax:
    INSERT OVERWRITE [LOCAL] DIRECTORY directory1
      [ROW FORMAT row_format] [STORED AS file_format] -- (Note: Only available starting with Hive 0.11.0)
      SELECT ... FROM ...
     
    -- Hive extension (multiple inserts):
    FROM from_statement
    INSERT OVERWRITE [LOCAL] DIRECTORY directory1 select_statement1
    [INSERT OVERWRITE [LOCAL] DIRECTORY directory2 select_statement2] ...
     
    row_format
      : DELIMITED [FIELDS TERMINATED BY char [ESCAPED BY char]] [COLLECTION ITEMS TERMINATED BY char]
            [MAP KEYS TERMINATED BY char] [LINES TERMINATED BY char]
            [NULL DEFINED AS char] -- (Note: Only available starting with Hive 0.13)
```
##### Inserting values into tables from SQL
###### Syntax
``` sql
    INSERT INTO TABLE tablename [PARTITION (partcol1[=val1], partcol2[=val2] ...)] VALUES values_row [, values_row ...]
     
    Where values_row is:
    ( value [, value ...] )
    where a value is either null or any valid SQL literal
```
###### Examples
``` sql
    CREATE TABLE students (name VARCHAR(64), age INT, gpa DECIMAL(3, 2))
      CLUSTERED BY (age) INTO 2 BUCKETS STORED AS ORC;
     
    INSERT INTO TABLE students
      VALUES ('fred flintstone', 35, 1.28), ('barney rubble', 32, 2.32);
     
     
    CREATE TABLE pageviews (userid VARCHAR(64), link STRING, came_from STRING)
      PARTITIONED BY (datestamp STRING) CLUSTERED BY (userid) INTO 256 BUCKETS STORED AS ORC;
     
    INSERT INTO TABLE pageviews PARTITION (datestamp = '2014-09-23')
      VALUES ('jsmith', 'mail.com', 'sports.com'), ('jdoe', 'mail.com', null);
     
    INSERT INTO TABLE pageviews PARTITION (datestamp)
      VALUES ('tjohnson', 'sports.com', 'finance.com', '2014-09-23'), ('tlee', 'finance.com', null, '2014-09-21');
```
##### Update
###### Syntax
``` sql
    UPDATE tablename SET column = value [, column = value ...] [WHERE expression]
```
##### Delete
###### Syntax
``` sql
    DELETE FROM tablename [WHERE expression]
```
##### Merge
###### Syntax
``` sql
    -- Standard Syntax:
    MERGE INTO <target table> AS T USING <source expression/table> AS S
    ON <boolean expression1>
    WHEN MATCHED [AND <boolean expression2>] THEN UPDATE SET <set clause list>
    WHEN MATCHED [AND <boolean expression3>] THEN DELETE
    WHEN NOT MATCHED [AND <boolean expression4>] THEN INSERT VALUES<value list>
```


#### Import/Export
##### Export Syntax
``` sql
    EXPORT TABLE tablename [PARTITION (part_column="value"[, ...])]
      TO 'export_target_path' [ FOR replication('eventid') ]
```
##### Import Syntax
``` sql
    IMPORT [[EXTERNAL] TABLE new_or_original_tablename [PARTITION (part_column="value"[, ...])]]
      FROM 'source_path'
      [LOCATION 'import_target_path']
```
##### Replication usage
###### Examples
``` sql
    -- Simple export and import:
    export table department to 'hdfs_exports_location/department';
    import from 'hdfs_exports_location/department';
    -- Rename table on import:
    export table department to 'hdfs_exports_location/department';
    import table imported_dept from 'hdfs_exports_location/department';
    -- Export partition and import:
    export table employee partition (emp_country="in", emp_state="ka") to 'hdfs_exports_location/employee';
    import from 'hdfs_exports_location/employee';
    -- Export table and import partition:
    export table employee to 'hdfs_exports_location/employee';
    import table employee partition (emp_country="us", emp_state="tn") from 'hdfs_exports_location/employee';
    -- Specify the import location:
    export table department to 'hdfs_exports_location/department';
    import table department from 'hdfs_exports_location/department' 
           location 'import_target_location/department';
    -- Import as an external table:
    export table department to 'hdfs_exports_location/department';
    import external table department from 'hdfs_exports_location/department';
```


#### Data Retrieval: Queries
##### Select
``` sql
    [WITH CommonTableExpression (, CommonTableExpression)*]    -- (Note: Only available starting with Hive 0.13.0)
    SELECT [ALL | DISTINCT] select_expr, select_expr, ...
      FROM table_reference
      [WHERE where_condition]
      [GROUP BY col_list]
      [ORDER BY col_list]
      [CLUSTER BY col_list
        | [DISTRIBUTE BY col_list] [SORT BY col_list]
      ]
     [LIMIT [offset,] rows]

     -- WHERE Clause
     SELECT * FROM sales WHERE amount > 10 AND region = "US"
     -- ALL(default) and DISTINCT Clauses
     SELECT DISTINCT col1, col2 FROM t1
     -- Partition Based Queries
     SELECT page_views.*
     FROM page_views
     WHERE page_views.date >= '2008-03-01' AND page_views.date <= '2008-03-31'

     SELECT page_views.*
     FROM page_views JOIN dim_users
        ON (page_views.user_id = dim_users.id AND page_views.date >= '2008-03-01' AND page_views.date <= '2008-03-31')
     -- HAVING Clause
     SELECT col1 FROM t1 GROUP BY col1 HAVING SUM(col2) > 10
     SELECT col1 FROM (SELECT col1, SUM(col2) AS col2sum FROM t1 GROUP BY col1) t2 WHERE t2.col2sum > 10
     -- LIMIT Clause
     SELECT * FROM customers LIMIT 5
     SELECT * FROM customers ORDER BY create_date LIMIT 5
     SELECT * FROM customers ORDER BY create_date LIMIT 2,5
     -- REGEX Column Specification
     SELECT `(ds|hr)?+.+` FROM sales
```
###### Group By
###### Sort/Distribute/Cluster/Order By
###### Transform and Map-Reduce Scripts
###### Operators and User-Defined Functions (UDFs)
###### XPath-specific Functions
###### Joins
###### Join Optimization
###### Union
###### Lateral View
##### Sub Queries
##### Sampling
##### Virtual Columns
##### Windowing and Analytics Functions
##### Enhanced Aggregation, Cube, Grouping and Rollup




## 原理探索
### metadata db


## 细节积累
### 日常操作
- spark-sql安全退出：$quit;


## 概念
### DataFrame & Dataset
#### Dataset:distributed collection of data,benefits of
- RDDs(strong typing,ability to use powerful lambda functions)
- spark SQL's optimized execution engine

#### DataFrame:Dataset organized into named columns
- (Dataset of Rows \ Dataset[Row])
- like:[- table in relational db - data frame in R,Python]{but with richer optimizations under the hood}


## 积累
1. json数据形成dataframe,并写入spark-sql
``` scala
  val schema = new StructType(Array(
    new StructField("id", LongType),
    ...
    ))

  def write(spark: SparkSession, jsonRDD: RDD[String], tablename: String): Unit = {
    //  schema创建并关联, 形成dataframe
    val df = spark.read.schema(schema).json(jsonRDD)
     
    LOG.info(df.schema.toString())

    df.write.mode(SaveMode.Append).saveAsTable(tablename)
  }
```


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
4. class not found
``` console
org.spark_project.guava.util.concurrent.ExecutionError: java.lang.NoClassDefFoundError: org/apache/hadoop/fs/CanUnbuffer

    at org.spark_project.guava.cache.LocalCache$Segment.get(LocalCache.java:2261)
    at org.spark_project.guava.cache.LocalCache.get(LocalCache.java:4000)
    at org.spark_project.guava.cache.LocalCache.getOrLoad(LocalCache.java:4004)
    at org.spark_project.guava.cache.LocalCache$LocalLoadingCache.get(LocalCache.java:4874)
    at org.spark_project.guava.cache.LocalCache$LocalLoadingCache.getUnchecked(LocalCache.java:4880)
    at org.spark_project.guava.cache.LocalCache$LocalLoadingCache.apply(LocalCache.java:4898)
    at org.apache.spark.sql.hive.HiveMetastoreCatalog.lookupRelation(HiveMetastoreCatalog.scala:110)
    at org.apache.spark.sql.hive.HiveSessionCatalog.lookupRelation(HiveSessionCatalog.scala:69)
    at org.apache.spark.sql.DataFrameReader.table(DataFrameReader.scala:473)
    at com.hikvision.sparta.map.cases.CaseDataProcess$.main(CaseDataProcess.scala:27)
    at com.hikvision.sparta.cases.CaseDataProcessTest.test(CaseDataProcessTest.scala:13)
    at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
    at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
    at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
    at java.lang.reflect.Method.invoke(Method.java:498)
    at org.junit.runners.model.FrameworkMethod$1.runReflectiveCall(FrameworkMethod.java:50)
    at org.junit.internal.runners.model.ReflectiveCallable.run(ReflectiveCallable.java:12)
    at org.junit.runners.model.FrameworkMethod.invokeExplosively(FrameworkMethod.java:47)
    at org.junit.internal.runners.statements.InvokeMethod.evaluate(InvokeMethod.java:17)
    at org.junit.runners.ParentRunner.runLeaf(ParentRunner.java:325)
    at org.junit.runners.BlockJUnit4ClassRunner.runChild(BlockJUnit4ClassRunner.java:78)
    at org.junit.runners.BlockJUnit4ClassRunner.runChild(BlockJUnit4ClassRunner.java:57)
    at org.junit.runners.ParentRunner$3.run(ParentRunner.java:290)
    at org.junit.runners.ParentRunner$1.schedule(ParentRunner.java:71)
    at org.junit.runners.ParentRunner.runChildren(ParentRunner.java:288)
    at org.junit.runners.ParentRunner.access$000(ParentRunner.java:58)
    at org.junit.runners.ParentRunner$2.evaluate(ParentRunner.java:268)
    at org.junit.runners.ParentRunner.run(ParentRunner.java:363)
    at org.junit.runner.JUnitCore.run(JUnitCore.java:137)
    at com.intellij.junit4.JUnit4IdeaTestRunner.startRunnerWithArgs(JUnit4IdeaTestRunner.java:68)
    at com.intellij.rt.execution.junit.IdeaTestRunner$Repeater.startRunnerWithArgs(IdeaTestRunner.java:51)
    at com.intellij.rt.execution.junit.JUnitStarter.prepareStreamsAndStart(JUnitStarter.java:242)
    at com.intellij.rt.execution.junit.JUnitStarter.main(JUnitStarter.java:70)
Caused by: java.lang.NoClassDefFoundError: org/apache/hadoop/fs/CanUnbuffer
```
解决方法：
hadoop版本不一致导致，去掉项目中其他的hadoop依赖