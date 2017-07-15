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


