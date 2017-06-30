---
title: oracle实战
date: 2017-06-13 09:09:30
tags: 
  - 实战 
  - sparksql
toc: true
---

[TOC]

异常现象：
``` shell
    ORA-28000: the account is locked

    sqlplus
```
``` sql
    sys/password as sysdba
    alter user ACCOUNT account unlock;
    commit;
```


oracle分页
``` scala

  /**
    * 构建分页查询语句
    *
    * @return
    */
  private def query(pageNum: Int, pageSize: Int, fieldBuf: mutable.Buffer[String], dbTable: String, conditionPart: String): String = {
    val basic = "( select " + fieldBuf.map("a." + _).mkString(",") + ", rownum as rn from " + dbTable + " a ) b "

    val condition = if (StringUtils.isNotEmpty(conditionPart))
      " where " + conditionPart + " AND  b.rn between " + ((pageNum - 1) * pageSize + 1) + " AND " + (pageNum) * pageSize
    else
      " where b.rn between " + ((pageNum - 1) * pageSize + 1) + " AND " + (pageNum) * pageSize

    "( select " + fieldBuf.mkString(",") + " from " + basic + condition + " ) c"
  }
```

spark sql
``` scala
      val ssc = new SQLContext(sc)
      val jdbcDF = (1 to index.toInt).map(index => {
        ssc.read.format("jdbc").options(
          options.getOptions
        ).load()
      }
      ).reduce(unionTableReducer)

      /**
        * dataframe结合
        *
        * @return
        */
      def unionTableReducer: (DataFrame, DataFrame) => DataFrame = (x: DataFrame, y: DataFrame) => x.union(y)
```



#### oracle rowid

##### 准备
``` sql
CREATE TABLE ZHCX_BDQ.TEST_ROWID_AS_COLUMN 
(
  ID VARCHAR2(20 BYTE) 
, ROW_ID ROWID 
) 
LOGGING 
TABLESPACE ZHCX_BDQ 
PCTFREE 10 
INITRANS 1 
STORAGE 
( 
  INITIAL 65536 
  NEXT 1048576 
  MINEXTENTS 1 
  MAXEXTENTS UNLIMITED 
  BUFFER_POOL DEFAULT 
) 
NOPARALLEL
REM INSERTING into ZHCX_BDQ.TEST_ROWID_AS_COLUMN
SET DEFINE OFF;
Insert into ZHCX_BDQ.TEST_ROWID_AS_COLUMN (ID,ROW_ID) values ('kl','AAAHOMAAIAAAACnAAA');
Insert into ZHCX_BDQ.TEST_ROWID_AS_COLUMN (ID,ROW_ID) values ('kl','AAAHOMAAIAAAACnAAA');
```

##### 异常复现
``` console
Caused by: java.sql.SQLException: Invalid column type: getLong not implemented for class oracle.jdbc.driver.T4CRowidAccessor
  at oracle.jdbc.driver.Accessor.unimpl(Accessor.java:412)
  at oracle.jdbc.driver.Accessor.getLong(Accessor.java:551)
  at oracle.jdbc.driver.OracleResultSetImpl.getLong(OracleResultSetImpl.java:939)
  at org.apache.spark.sql.execution.datasources.jdbc.JdbcUtils$$anonfun$org$apache$spark$sql$execution$datasources$jdbc$JdbcUtils$$makeGetter$8.apply(JdbcUtils.scala:365)
  at org.apache.spark.sql.execution.datasources.jdbc.JdbcUtils$$anonfun$org$apache$spark$sql$execution$datasources$jdbc$JdbcUtils$$makeGetter$8.apply(JdbcUtils.scala:364)
  at org.apache.spark.sql.execution.datasources.jdbc.JdbcUtils$$anon$1.getNext(JdbcUtils.scala:286)
  at org.apache.spark.sql.execution.datasources.jdbc.JdbcUtils$$anon$1.getNext(JdbcUtils.scala:268)
  at org.apache.spark.util.NextIterator.hasNext(NextIterator.scala:73)
  at org.apache.spark.util.CompletionIterator.hasNext(CompletionIterator.scala:32)
  at org.apache.spark.sql.catalyst.expressions.GeneratedClass$GeneratedIterator.processNext(Unknown Source)
  at org.apache.spark.sql.execution.BufferedRowIterator.hasNext(BufferedRowIterator.java:43)
  at org.apache.spark.sql.execution.WholeStageCodegenExec$$anonfun$8$$anon$1.hasNext(WholeStageCodegenExec.scala:377)
  at scala.collection.Iterator$$anon$11.hasNext(Iterator.scala:408)
  at scala.collection.Iterator$$anon$11.hasNext(Iterator.scala:408)
  at org.apache.spark.storage.memory.MemoryStore.putIteratorAsValues(MemoryStore.scala:215)
  at org.apache.spark.storage.BlockManager$$anonfun$doPutIterator$1.apply(BlockManager.scala:957)
  at org.apache.spark.storage.BlockManager$$anonfun$doPutIterator$1.apply(BlockManager.scala:948)
  at org.apache.spark.storage.BlockManager.doPut(BlockManager.scala:888)
  at org.apache.spark.storage.BlockManager.doPutIterator(BlockManager.scala:948)
  at org.apache.spark.storage.BlockManager.getOrElseUpdate(BlockManager.scala:694)
  at org.apache.spark.rdd.RDD.getOrCompute(RDD.scala:334)
  at org.apache.spark.rdd.RDD.iterator(RDD.scala:285)
  at org.apache.spark.rdd.MapPartitionsRDD.compute(MapPartitionsRDD.scala:38)
  at org.apache.spark.rdd.RDD.computeOrReadCheckpoint(RDD.scala:323)
  at org.apache.spark.rdd.RDD.iterator(RDD.scala:287)
  at org.apache.spark.rdd.MapPartitionsRDD.compute(MapPartitionsRDD.scala:38)
  at org.apache.spark.rdd.RDD.computeOrReadCheckpoint(RDD.scala:323)
  at org.apache.spark.rdd.RDD.iterator(RDD.scala:287)
  at org.apache.spark.scheduler.ResultTask.runTask(ResultTask.scala:87)
  at org.apache.spark.scheduler.Task.run(Task.scala:99)
  at org.apache.spark.executor.Executor$TaskRunner.run(Executor.scala:282)
  at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1145)
  at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:615)
  at java.lang.Thread.run(Thread.java:745)
```

#### 源码debug走读：
- 311   private def makeGetter(dt: DataType, metadata: Metadata): JDBCValueGetter = dt match {
``` console
metadata = {Metadata@13503} "{"name":"ROW_ID","scale":0}"
dt = {LongType$@13502} "LongType"
```
- org.apache.spark.sql.execution.datasources.jdbc.JdbcUtils
  + 158   private def getCatalystType(
    * 196 case java.sql.Types.ROWID         => LongType

``` scala
def getSchema(resultSet: ResultSet, dialect: JdbcDialect): StructType = {
    val rsmd = resultSet.getMetaData
    val ncols = rsmd.getColumnCount
    val fields = new Array[StructField](ncols)
    var i = 0
    while (i < ncols) {
      val columnName = rsmd.getColumnLabel(i + 1)
      val dataType = rsmd.getColumnType(i + 1)
      val typeName = rsmd.getColumnTypeName(i + 1)
      val fieldSize = rsmd.getPrecision(i + 1)
      val fieldScale = rsmd.getScale(i + 1)
      val isSigned = {
        try {
          rsmd.isSigned(i + 1)
        } catch {
          // Workaround for HIVE-14684:
          case e: SQLException if
          e.getMessage == "Method not supported" &&
            rsmd.getClass.getName == "org.apache.hive.jdbc.HiveResultSetMetaData" => true
        }
      }
      val nullable = rsmd.isNullable(i + 1) != ResultSetMetaData.columnNoNulls
      val metadata = new MetadataBuilder()
        .putString("name", columnName)
        .putLong("scale", fieldScale)
      val columnType =
        dialect.getCatalystType(dataType, typeName, fieldSize, metadata).getOrElse(
          getCatalystType(dataType, fieldSize, fieldScale, isSigned))
      fields(i) = StructField(columnName, columnType, nullable, metadata.build())
      i = i + 1
    }
    new StructType(fields)
  }


override def getCatalystType(
      sqlType: Int, typeName: String, size: Int, md: MetadataBuilder): Option[DataType] = {
    if (sqlType == Types.NUMERIC) {
      val scale = if (null != md) md.build().getLong("scale") else 0L
      size match {
        // Handle NUMBER fields that have no precision/scale in special way
        // because JDBC ResultSetMetaData converts this to 0 precision and -127 scale
        // For more details, please see
        // https://github.com/apache/spark/pull/8780#issuecomment-145598968
        // and
        // https://github.com/apache/spark/pull/8780#issuecomment-144541760
        case 0 => Option(DecimalType(DecimalType.MAX_PRECISION, 10))
        // Handle FLOAT fields in a special way because JDBC ResultSetMetaData converts
        // this to NUMERIC with -127 scale
        // Not sure if there is a more robust way to identify the field as a float (or other
        // numeric types that do not specify a scale.
        case _ if scale == -127L => Option(DecimalType(DecimalType.MAX_PRECISION, 10))
        case 1 => Option(BooleanType)
        case 3 | 5 | 10 => Option(IntegerType)
        case 19 if scale == 0L => Option(LongType)
        case 19 if scale == 4L => Option(FloatType)
        case _ => None
      }
    } else {
      None
    }
  }


  private def getCatalystType(
      sqlType: Int,
      precision: Int,
      scale: Int,
      signed: Boolean): DataType = {
    val answer = sqlType match {
      // scalastyle:off
      case java.sql.Types.ARRAY         => null
      case java.sql.Types.BIGINT        => if (signed) { LongType } else { DecimalType(20,0) }
      case java.sql.Types.BINARY        => BinaryType
      case java.sql.Types.BIT           => BooleanType // @see JdbcDialect for quirks
      case java.sql.Types.BLOB          => BinaryType
      case java.sql.Types.BOOLEAN       => BooleanType
      case java.sql.Types.CHAR          => StringType
      case java.sql.Types.CLOB          => StringType
      case java.sql.Types.DATALINK      => null
      case java.sql.Types.DATE          => DateType
      case java.sql.Types.DECIMAL
        if precision != 0 || scale != 0 => DecimalType.bounded(precision, scale)
      case java.sql.Types.DECIMAL       => DecimalType.SYSTEM_DEFAULT
      case java.sql.Types.DISTINCT      => null
      case java.sql.Types.DOUBLE        => DoubleType
      case java.sql.Types.FLOAT         => FloatType
      case java.sql.Types.INTEGER       => if (signed) { IntegerType } else { LongType }
      case java.sql.Types.JAVA_OBJECT   => null
      case java.sql.Types.LONGNVARCHAR  => StringType
      case java.sql.Types.LONGVARBINARY => BinaryType
      case java.sql.Types.LONGVARCHAR   => StringType
      case java.sql.Types.NCHAR         => StringType
      case java.sql.Types.NCLOB         => StringType
      case java.sql.Types.NULL          => null
      case java.sql.Types.NUMERIC
        if precision != 0 || scale != 0 => DecimalType.bounded(precision, scale)
      case java.sql.Types.NUMERIC       => DecimalType.SYSTEM_DEFAULT
      case java.sql.Types.NVARCHAR      => StringType
      case java.sql.Types.OTHER         => null
      case java.sql.Types.REAL          => DoubleType
      case java.sql.Types.REF           => StringType
      case java.sql.Types.ROWID         => LongType
      case java.sql.Types.SMALLINT      => IntegerType
      case java.sql.Types.SQLXML        => StringType
      case java.sql.Types.STRUCT        => StringType
      case java.sql.Types.TIME          => TimestampType
      case java.sql.Types.TIMESTAMP     => TimestampType
      case java.sql.Types.TINYINT       => IntegerType
      case java.sql.Types.VARBINARY     => BinaryType
      case java.sql.Types.VARCHAR       => StringType
      case _                            => null
      // scalastyle:on
    }

    if (answer == null) throw new SQLException("Unsupported type " + sqlType)
    answer
  }
```
