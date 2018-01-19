---
title: oracle实战
date: 2017-06-13 09:09:30
tags: 
  - 实战 
  - sparksql
toc: true
---

[TOC]

## Performance Tuning
### 手动ORACLE数据库导出AWR报告方法记录
1. 配置概要
  a. ORACLE_INSTALL_HOEM=/u01/app/oracle/product/11.2.0/xe/
  b. http port:28080
  c. monitor port:1521
2. STEPS
``` shell
cd ${ORACLE_INSTALL_HOEM}
sqlplus 
sys/learning12345 as sysdba
@?/rdbms/admin/awrrpt.sql
-- 1. 确定awr生成格式
-- 2. 报告涉及天数
-- 3. 输入开始和结束的snapshot编号
-- 4. 确定awr名称
```

### 生成AWR、ASH、ADDM、AWRINFO报告脚本
``` sql
@?rdbms/admin/awrrpt.sql是以前statspack的扩展，收集信息更详细，查看长期的数据库情况。
@?rdbms/admin/ashrpt.sql查看当前的数据库情况，因为ash是每秒从v$session进行进行取样，awr收集的数据要比ash多得多。
-- 一般收集数据库信息的话要结合awr和ash。
@?rdbms/admin/addmrpt .sql相当于是驻留在oracle里的一位专家，是一个自我诊断引擎。产生symptom，problem，infomation，提供解决问题的建议，并自动修复一些具体的故障。
@?rdbms/admin/awrinfo.sql显示的都是awr的相关信息，包括快照信息、sysaux空间使用、awr组件、ash等信息。
```



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
        /**
         * 更新options里面的sql采集语句
         */
        
        /**
         * end
         */
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

#### oracle session 内存监控
``` sql
SELECT
    TO_CHAR(
        ssn.sid,
        '9999'
    )
     || ' - '
     || nvl(
        ssn.username,
        nvl(
            bgp.name,
            'background'
        )
    )
     || nvl(
        lower(ssn.machine),
        ins.host_name
    ) "SESSION",
    TO_CHAR(
        prc.spid,
        '999999999'
    ) "PID/THREAD",
    TO_CHAR(
        (se1.value / 1024) / 1024,
        '999G999G990D00'
    )
     || ' MB' " CURRENT SIZE",
    TO_CHAR(
        (se2.value / 1024) / 1024,
        '999G999G990D00'
    )
     || ' MB' " MAXIMUM SIZE"
FROM
    v$sesstat se1,
    v$sesstat se2,
    v$session ssn,
    v$bgprocess bgp,
    v$process prc,
    v$instance ins,
    v$statname stat1,
    v$statname stat2
WHERE
        se1.statistic# = stat1.statistic#
    AND
        stat1.name = 'session pga memory'
    AND
        se2.statistic# = stat2.statistic#
    AND
        stat2.name = 'session pga memory max'
    AND
        se1.sid = ssn.sid
    AND
        se2.sid = ssn.sid
    AND
        ssn.paddr = bgp.paddr (+)
    AND
        ssn.paddr = prc.addr (+);
```

#### oracle NUMBER
``` sql
alter table "ZHCX_BDQ"."海康" modify(RES number(*, 100) not null);
```
  number类型的语法很简单,就是：
    number(p,s)
    p,s都是可选的，假如都不填，p默认为38，s默认为-48~127。
    1. 精度（precision），或总位数。默认情况下，精度为38位，取值范围是1～38之间。也可以用字符*表示38。
    2. 小数位置（scale），或小数点右边的位数。小数位数的合法值为-48～127，其默认值取决于是否指定了精度。如果没有知道精度，小数位数则默认有最大的取值区间。如果指定了精度，小数位数默认为0（小数点右边一位都没有）。例如，定义为NUMBER的列会存储浮点数（有小数），而NUMBER(38)只存储整数数据（没有小数），因为在第二种情况下小数位数默认为0.

    如下SQL语句：
      create table t ( msg varchar2(12.), num_col number(5,2) );
      insert into t (msg,num_col) values ( '123.456', 123.456 );//执行成功，保存的是123.46
      insert into t (msg,num_col) values ( '1234', 1234 );//执行失败，要保留2位小数，那么整数位最多3位，现在是4位。
 
    如果scale是负数怎么样，表示左边整数位舍入几位：
      create table t ( msg varchar2(12.), num_col number(5,-2) );
      insert into t (msg,num_col) values ( '123.45', 123.45 );//执行成功，保存的是100
      insert into t (msg,num_col) values ( '123.456', 123.456 );//执行成功，保存的是100
 
   其他数据类型：
     1. NUMERIC(p,s)：完全映射至NUMBER(p,s)。如果p未指定，则默认为38.
     2. DECIMAL(p,s)或DEC(p,s)：完全映射至NUMBER(p,s)。如果p为指定，则默认为38.
     3. INTEGER或INT：完全映射至NUMBER(38)类型。
     4. SMALLINT：完全映射至NUMBER(38)类型。
     5. FLOAT(b)：映射至NUMBER类型。
     6. DOUBLE PRECISION：映射至NUMBER类型。
     7. REAL：映射至NUMBER类型。
 
   性能考虑：
     一般而言，Oracle NUMBER类型对大多数应用来讲都是最佳的选择。不过，这个类型会带来一些性能影响。Oracle NUMBER类型是一种软件数据类型，在Oracle软件本身中实现。我们不能使用固有硬件操作将两个NUMBER类型相加，这要在软件中模拟。不过，浮点数没有这种实现。将两个浮点数相加时，Oracle会使用硬件来执行运算。
     换而言之，将一些列的number列相加，没有将一系列float列相加来得快。因为float列的精度低很多，一般是6~12位。
     比如：select sum(ln(cast( num_type as binary_double ) )) from t
     比：select sum(ln(cast( num_type) )) from t 要快很多。

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

### 密度侦测
``` scala
package com.chaosdata.etl.load.density

import java.sql.Connection
import java.text.SimpleDateFormat
import java.util.Date

import com.chaosdata.etl.db.model.DataSourceCase
import com.chaosdata.etl.load.meta.MetaDataService
import com.twitter.util.Time
import oracle.jdbc.pool.OracleDataSource
import org.slf4j.LoggerFactory

import scala.collection.mutable
import scala.collection.mutable.ArrayBuffer


object DataDensityAnalysis {
  private val LOG = LoggerFactory.getLogger(this.getClass)
  val sdf = new SimpleDateFormat("yyyy-MM-dd hh:mm:ss")

  /**
    * 执行入口
    *
    * @param tableId
    * @param startDate
    * @param endDate
    * @param limitCount
    * @param column
    * @return
    */
  def run(tableId: String, startDate: Date, endDate: Date, limitCount: Long, column: String): ArrayBuffer[(String, String, String, String, Long, String)] = {
    val resultBufeer: mutable.ArrayBuffer[(String, String, Date, Date, Long)] = new ArrayBuffer[(String, String, Date, Date, Long)]

    val (dsc, table, ds) = MetaDataService.loadInfoByTableId(tableId.toInt)
    val (conn, owner) = getConn(dsc = dsc)

    analysis(conn = conn, id = table.getOriginTableId.toString, tablename = table.getOriginTableName, owner = owner, startDate = startDate, endDate = endDate, limitCount = limitCount, resultList = resultBufeer, column = column)

    closeConn(conn)

    val result = resultBufeer.map(infos => (infos._1, infos._2, sdf.format(infos._3), sdf.format(infos._4), infos._5, s"where ${column} >= TO_DATE('${sdf.format(infos._3)}', 'yyyy-mm-dd hh24:mi:ss') AND ${column} < TO_DATE('${sdf.format(infos._4)}', 'yyyy-mm-dd hh24:mi:ss')"))

    LOG.info(result.mkString("\n"))

    result
  }

  def runRetWhereSql(tableId: String, startDate: Date, endDate: Date, limitCount: Long, column: String): ArrayBuffer[String] = {
    run(tableId = tableId, startDate = startDate, endDate = endDate, limitCount = limitCount, column = column).map(_._6)
  }

  /**
    * 分析数据列密度
    *
    * @param conn
    * @param id
    * @param tablename
    * @param owner
    * @param startDate
    * @param endDate
    * @param limitCount
    * @param resultList
    * @param column
    */
  def analysis(conn: Connection, id: String, tablename: String, owner: String, startDate: Date, endDate: Date, limitCount: Long, resultList: mutable.ArrayBuffer[(String, String, Date, Date, Long)], column: String = "ETLTIME"): Unit = {
    val (count, countSql) = queryTableCount(tablename = tablename, owner = owner, conn = conn, startDate = startDate, endDate = endDate, column = column)

    if (count > limitCount) {
      if (startDate.getTime == endDate.getTime) {
        LOG.info(s"该sql语句为：$countSql , 结果条数为：$count")
        resultList.+=((id, tablename, startDate, endDate, count))

        return
      } else {
        val newDate = Time.fromMilliseconds((startDate.getTime + endDate.getTime) / 2)
        // 递归
        analysis(conn = conn, id = id, tablename = tablename, owner = owner, startDate = startDate, endDate = newDate.toDate, limitCount = limitCount, resultList = resultList, column = column)
        analysis(conn = conn, id = id, tablename = tablename, owner = owner, startDate = newDate.toDate, endDate = endDate, limitCount = limitCount, resultList = resultList, column = column)
      }
    } else if (count != 0) {
      resultList.+=((id, tablename, startDate, endDate, count))

      return
    } else {
      /**
        * do somnething
        */
      LOG.info(s"当前表查询条数为 0， 查询语句为：${countSql}")

      return
    }
  }

  /**
    * 查询数据条数
    *
    * @param tablename
    * @param owner
    * @param conn
    * @param startDate
    * @param endDate
    * @param column
    * @return
    */
  private def queryTableCount(tablename: String, owner: String, conn: Connection, startDate: Date, endDate: Date, column: String): (Long, String) = {
    val countSql = genStatsCountSql(tablename = tablename, owner = owner, startDate = startDate, endDate = endDate, column = column)
    //    LOG.info(countSql)
    val result = conn.createStatement().executeQuery(countSql)
    val count = if (!result.next()) 0 else result.getLong(1)

    /**
      * ORA-01000: maximum open cursors exceeded
      * Cursor leak: The applications is not closing ResultSets (in JDBC) or cursors (in stored procedures on the database)
      */
    result.close()

    (count, countSql)
  }

  /**
    * 生成统计条数查询语句
    *
    * @param tablename
    * @param owner
    * @param startDate
    * @param endDate
    * @param column
    * @return
    */
  private def genStatsCountSql(tablename: String, owner: String, startDate: Date, endDate: Date, column: String): String = {
    // 生成sql 统计语句
    s"select count(*) from ${owner}.${tablename} where ${column} >= TO_DATE('${sdf.format(startDate)}', 'yyyy-mm-dd hh24:mi:ss') AND ${column} < TO_DATE('${sdf.format(endDate)}', 'yyyy-mm-dd hh24:mi:ss')"
  }
}

```