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


## Spark SQL Reference
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


