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