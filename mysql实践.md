---
title: mysql实践
date: 2017-07-14 10:43:45
tags:
---

## 使用总结
### 数据备份
``` shell
#备份mysql数据库或者某张表
mysqldump -uroot -pPASSWD vulcanus  > vulcanus.sql 
mysqldump -uroot -pPASSWD vulcanus data_source_case> data_source_case.sql 
mysqldump -uroot -pPASSWD vulcanus origin_table> origin_table.sql 
```

### group by 相关
```
select date_format(start_date,'%y-%m-%d'), count(*), GROUP_CONCAT(table_id SEPARATOR ' ') from data_load_pioneer group by date_format(start_date,'%y-%m-%d') order by table_id;

17-09-29    2545    11,12,13,14,15,16,17,18,19,20,21,22,23,25,26
17-09-30    79  14,15,19,21,25,27,28,29,41,47,50,52,81
17-10-01    78  14,15,19,21,25,26,27,29,41,47,50,52 
```

### 日期格式化
``` sql
select distinct date_format(start_date,'%y-%m-%d') from data_load_pioneer;
select date_format(now(),'%y-%m-%d');
--   %a 缩写星期名
--   %b 缩写月名
--   %c 月，数值
--   %D 带有英文前缀的月中的天
--   %d 月的天，数值(00-31)
--   %e 月的天，数值(0-31)
--   %f 微秒
--   %H 小时 (00-23)
--   %h 小时 (01-12)
--   %I 小时 (01-12)
--   %i 分钟，数值(00-59)
--   %j 年的天 (001-366)
--   %k 小时 (0-23)
--   %l 小时 (1-12)
--   %M 月名
--   %m 月，数值(00-12)
--   %p AM 或 PM
--   %r 时间，12-小时（hh:mm:ss AM 或 PM）
--   %S 秒(00-59)
--   %s 秒(00-59)
--   %T 时间, 24-小时 (hh:mm:ss)
--   %U 周 (00-53) 星期日是一周的第一天
--   %u 周 (00-53) 星期一是一周的第一天
--   %V 周 (01-53) 星期日是一周的第一天，与 %X 使用
--   %v 周 (01-53) 星期一是一周的第一天，与 %x 使用
--   %W 星期名
--   %w 周的天 （0=星期日, 6=星期六）
--   %X 年，其中的星期日是周的第一天，4 位，与 %V 使用
--   %x 年，其中的星期一是周的第一天，4 位，与 %v 使用
--   %Y 年，4 位
--   %y 年，2 位
```


## 问题集锦
1. MySql Host is blocked because of many connection errors; unblock with 'mysqladmin flush-hosts' 
    - 解决方法：
    ``` sql

    ```

## MySQL 5.7 Reference Manual

### SQL Statement Syntax
#### Data Definition Statements
##### ALTER DATABASE Syntax
``` sql
    ALTER {DATABASE | SCHEMA} [db_name]
    alter_specification ...
    alter_specification:
        [DEFAULT] CHARACTER SET [=] charset_name | [DEFAULT] COLLATE [=] collation(校对)_name
```
##### ALTER EVENT Syntax 
``` sql
    ALTER
        [DEFINER = { user | CURRENT_USER }]
        EVENT event_name
        [ON SCHEDULE schedule]
        [ON COMPLETION [NOT] PRESERVE]
        [RENAME TO new_event_name]
        [ENABLE | DISABLE | DISABLE ON SLAVE]
        [COMMENT 'comment']
        [DO event_body]
```
##### ALTER FUNCTION Syntax 
``` sql
    ALTER FUNCTION func_name [characteristic ...]
    characteristic:
        COMMENT 'string'
        | LANGUAGE SQL
        | { CONTAINS SQL | NO SQL | READS SQL DATA | MODIFIES SQL DATA }
        | SQL SECURITY { DEFINER | INVOKER }
```
##### ALTER INSTANCE Syntax 
``` sql
    ALTER INSTANCE ROTATE INNODB MASTER KEY
```
##### ALTER LOGFILE GROUP Syntax

##### ALTER PROCEDURE Syntax
``` sql
    ALTER PROCEDURE proc_name [characteristic ...]
    characteristic:
        COMMENT 'string'
        | LANGUAGE SQL
        | { CONTAINS SQL | NO SQL | READS SQL DATA | MODIFIES SQL DATA }
        | SQL SECURITY { DEFINER | INVOKER }
```
##### ALTER SERVER Syntax 
``` sql
    ALTER SERVER server_name OPTIONS (option [, option] ...)
```
##### ALTER TABLE Syntax  
``` sql
    ALTER TABLE tbl_name
    [alter_specification [, alter_specification] ...]
    [partition_options]
    alter_specification:
    table_options

    | ADD [COLUMN] col_name column_definition
    [FIRST | AFTER col_name ]
    | ADD [COLUMN] (col_name column_definition,...)
    | ADD {INDEX|KEY} [index_name]
    [index_type] (index_col_name,...) [index_option] ...
    | ADD [CONSTRAINT [symbol]] PRIMARY KEY
    [index_type] (index_col_name,...) [index_option] ...
    | ADD [CONSTRAINT [symbol]]
    UNIQUE [INDEX|KEY] [index_name]
    [index_type] (index_col_name,...) [index_option] ...
    | ADD FULLTEXT [INDEX|KEY] [index_name]
    (index_col_name,...) [index_option] ...
    | ADD SPATIAL [INDEX|KEY] [index_name]
    (index_col_name,...) [index_option] ...
    | ADD [CONSTRAINT [symbol]]
    FOREIGN KEY [index_name] (index_col_name,...)
    reference_definition
    | ALGORITHM [=] {DEFAULT|INPLACE|COPY}
    | ALTER [COLUMN] col_name {SET DEFAULT literal | DROP DEFAULT}
    | CHANGE [COLUMN] old_col_name new_col_name column_definition
    [FIRST|AFTER col_name]
    | LOCK [=] {DEFAULT|NONE|SHARED|EXCLUSIVE}
    | MODIFY [COLUMN] col_name column_definition
    [FIRST | AFTER col_name]
    | DROP [COLUMN] col_name
    | DROP PRIMARY KEY
    | DROP {INDEX|KEY} index_name
    | DROP FOREIGN KEY fk_symbol
    | ALTER INDEX index_name {VISIBLE | INVISIBLE}
    | DISABLE KEYS
    | ENABLE KEYS
    | RENAME [TO|AS] new_tbl_name
    | RENAME {INDEX|KEY} old_index_name TO new_index_name
    | ORDER BY col_name [, col_name] ...
    | CONVERT TO CHARACTER SET charset_name [COLLATE collation_name]
    | [DEFAULT] CHARACTER SET [=] charset_name [COLLATE [=] collation_name]
    | DISCARD TABLESPACE
    | IMPORT TABLESPACE
    | FORCE
    | {WITHOUT|WITH} VALIDATION
    | ADD PARTITION (partition_definition)
    | DROP PARTITION partition_names
    | DISCARD PARTITION {partition_names | ALL} TABLESPACE
    | IMPORT PARTITION {partition_names | ALL} TABLESPACE
    | TRUNCATE PARTITION {partition_names | ALL}
    | COALESCE PARTITION number
    | REORGANIZE PARTITION partition_names INTO (partition_definitions)
    | EXCHANGE PARTITION partition_name WITH TABLE tbl_name [{WITH|WITHOUT} VALIDATION]
    | ANALYZE PARTITION {partition_names | ALL}
    | CHECK PARTITION {partition_names | ALL}
    | OPTIMIZE PARTITION {partition_names | ALL}
    | REBUILD PARTITION {partition_names | ALL}
    | REPAIR PARTITION {partition_names | ALL}
    | REMOVE PARTITIONING
    | UPGRADE PARTITIONING

    index_col_name:
    col_name [(length)] [ASC | DESC]
    index_type:
    USING {BTREE | HASH}
    index_option:
    KEY_BLOCK_SIZE [=] value
    | index_type
    | WITH PARSER parser_name
    | COMMENT 'string'
    | {VISIBLE | INVISIBLE}
    table_options:
    table_option [[,] table_option] ...
    table_option:
    ENGINE [=] engine_name
    | AUTO_INCREMENT [=] value
    | AVG_ROW_LENGTH [=] value
    | [DEFAULT] CHARACTER SET [=] charset_name
    | CHECKSUM [=] {0 | 1}
    | [DEFAULT] COLLATE [=] collation_name
    | COMMENT [=] 'string'
    | COMPRESSION [=] {'ZLIB'|'LZ4'|'NONE'}
    | CONNECTION [=] 'connect_string'
    | DATA DIRECTORY [=] 'absolute path to directory'
    | DELAY_KEY_WRITE [=] {0 | 1}
    | ENCRYPTION [=] {'Y' | 'N'}
    | INDEX DIRECTORY [=] 'absolute path to directory'
    | INSERT_METHOD [=] { NO | FIRST | LAST }
    | KEY_BLOCK_SIZE [=] value
    | MAX_ROWS [=] value
    | MIN_ROWS [=] value
    | PACK_KEYS [=] {0 | 1 | DEFAULT}
    | PASSWORD [=] 'string'
    | ROW_FORMAT [=] {DEFAULT|DYNAMIC|FIXED|COMPRESSED|REDUNDANT|COMPACT}
    | STATS_AUTO_RECALC [=] {DEFAULT|0|1}
    | STATS_PERSISTENT [=] {DEFAULT|0|1}
    | STATS_SAMPLE_PAGES [=] value
    | TABLESPACE tablespace_name
    | UNION [=] (tbl_name[,tbl_name]...)
    partition_options:
    (see CREATE TABLE options)
```
##### ALTER TABLESPACE Syntax 

##### ALTER VIEW Syntax 
``` sql
    ALTER
        [ALGORITHM = {UNDEFINED | MERGE | TEMPTABLE}]
        [DEFINER = { user | CURRENT_USER }]
        [SQL SECURITY { DEFINER | INVOKER }]
        VIEW view_name [(column_list)]
        AS select_statement
        [WITH [CASCADED | LOCAL] CHECK OPTION]
```
##### CREATE DATABASE Syntax 
``` sql
    CREATE {DATABASE | SCHEMA} [IF NOT EXISTS] db_name
    [create_specification] ...
    create_specification:
    [DEFAULT] CHARACTER SET [=] charset_name
    | [DEFAULT] COLLATE [=] collation_name
```
##### CREATE EVENT Syntax 
``` sql
    CREATE
        [DEFINER = { user | CURRENT_USER }]
        EVENT
        [IF NOT EXISTS]
        event_name
        ON SCHEDULE schedule
        [ON COMPLETION [NOT] PRESERVE]
        [ENABLE | DISABLE | DISABLE ON SLAVE]
        [COMMENT 'comment']
        DO event_body;
    schedule:
        AT timestamp [+ INTERVAL interval] ...
        | EVERY interval
        [STARTS timestamp [+ INTERVAL interval] ...]
        [ENDS timestamp [+ INTERVAL interval] ...]
    interval:
        quantity {YEAR | QUARTER | MONTH | DAY | HOUR | MINUTE |
            WEEK | SECOND | YEAR_MONTH | DAY_HOUR | DAY_MINUTE |
            DAY_SECOND | HOUR_MINUTE | HOUR_SECOND | MINUTE_SECOND}
```

##### CREATE FUNCTION Syntax
``` sql

```

##### CREATE INDEX Syntax
``` sql
    CREATE [UNIQUE|FULLTEXT|SPATIAL] INDEX index_name
        [index_type]
        ON tbl_name (index_col_name,...)
        [index_option]
        [algorithm_option | lock_option] ...
    index_col_name:
        col_name [(length)] [ASC | DESC]
    index_option:
        KEY_BLOCK_SIZE [=] value
        | index_type
        | WITH PARSER parser_name
        | COMMENT 'string'
        | {VISIBLE | INVISIBLE}
    index_type:
        USING {BTREE | HASH}
    algorithm_option:
        ALGORITHM [=] {DEFAULT|INPLACE|COPY}
    lock_option:
        LOCK [=] {DEFAULT|NONE|SHARED|EXCLUSIVE}
```

##### CREATE LOGFILE GROUP Syntax 


##### CREATE PROCEDURE and CREATE FUNCTION Syntax 
``` sql
    CREATE
        [DEFINER = { user | CURRENT_USER }]
        PROCEDURE sp_name ([proc_parameter[,...]])
        [characteristic ...] routine_body
    CREATE
        [DEFINER = { user | CURRENT_USER }]
        FUNCTION sp_name ([func_parameter[,...]])
        RETURNS type
        [characteristic ...] routine_body
    proc_parameter:
        [ IN | OUT | INOUT ] param_name type
    func_parameter:
        param_name type
    type:
        Any valid MySQL data type
    characteristic:
        COMMENT 'string'
        | LANGUAGE SQL
        | [NOT] DETERMINISTIC
        | { CONTAINS SQL | NO SQL | READS SQL DATA | MODIFIES SQL DATA }
        | SQL SECURITY { DEFINER | INVOKER }
    routine_body:
        Valid SQL routine statement
```

##### CREATE SERVER Syntax 
``` sql
    CREATE SERVER server_name
        FOREIGN DATA WRAPPER wrapper_name
        OPTIONS (option [, option] ...)
    option:
        { HOST character-literal
        | DATABASE character-literal
        | USER character-literal
        | PASSWORD character-literal
        | SOCKET character-literal
        | OWNER character-literal
        | PORT numeric-literal }
```

##### CREATE TABLE Syntax 
``` sql
    CREATE [TEMPORARY] TABLE [IF NOT EXISTS] tbl_name
        (create_definition,...)
        [table_options]
        [partition_options]

    CREATE [TEMPORARY] TABLE [IF NOT EXISTS] tbl_name
        [(create_definition,...)]
        [table_options]
        [partition_options]
        [IGNORE | REPLACE]
        [AS] query_expression

    CREATE [TEMPORARY] TABLE [IF NOT EXISTS] tbl_name
        { LIKE old_tbl_name | (LIKE old_tbl_name) }
    create_definition:
        col_name column_definition
        | [CONSTRAINT [symbol]] PRIMARY KEY [index_type] (index_col_name,...)
        [index_option] ...
        | {INDEX|KEY} [index_name] [index_type] (index_col_name,...)
        [index_option] ...
        | [CONSTRAINT [symbol]] UNIQUE [INDEX|KEY]
        [index_name] [index_type] (index_col_name,...)
        [index_option] ...
        | {FULLTEXT|SPATIAL} [INDEX|KEY] [index_name] (index_col_name,...)
        [index_option] ...
        | [CONSTRAINT [symbol]] FOREIGN KEY
        [index_name] (index_col_name,...) reference_definition
        | CHECK (expr)
    column_definition:
        data_type [NOT NULL | NULL] [DEFAULT default_value]
            [AUTO_INCREMENT] [UNIQUE [KEY] | [PRIMARY] KEY]
            [COMMENT 'string']
            [COLUMN_FORMAT {FIXED|DYNAMIC|DEFAULT}]
        [reference_definition]
    | data_type [GENERATED ALWAYS] AS (expression)
        [VIRTUAL | STORED] [UNIQUE [KEY]] [COMMENT comment]
        [NOT NULL | NULL] [[PRIMARY] KEY]
    data_type:
        BIT[(length)]
        | TINYINT[(length)] [UNSIGNED] [ZEROFILL]
        | SMALLINT[(length)] [UNSIGNED] [ZEROFILL]
        | MEDIUMINT[(length)] [UNSIGNED] [ZEROFILL]
        | INT[(length)] [UNSIGNED] [ZEROFILL]
        | INTEGER[(length)] [UNSIGNED] [ZEROFILL]
        | BIGINT[(length)] [UNSIGNED] [ZEROFILL]
        | REAL[(length,decimals)] [UNSIGNED] [ZEROFILL]
        | DOUBLE[(length,decimals)] [UNSIGNED] [ZEROFILL]
        | FLOAT[(length,decimals)] [UNSIGNED] [ZEROFILL]
        | DECIMAL[(length[,decimals])] [UNSIGNED] [ZEROFILL]
        | NUMERIC[(length[,decimals])] [UNSIGNED] [ZEROFILL]
        | DATE
        | TIME[(fsp)]
        | TIMESTAMP[(fsp)]
        | DATETIME[(fsp)]
        | YEAR
        | CHAR[(length)] [BINARY]
        [CHARACTER SET charset_name] [COLLATE collation_name]
        | VARCHAR(length) [BINARY]
        [CHARACTER SET charset_name] [COLLATE collation_name]
        | BINARY[(length)]
        | VARBINARY(length)
        | TINYBLOB
        | BLOB
        | MEDIUMBLOB
        | LONGBLOB
        | TINYTEXT [BINARY]
        [CHARACTER SET charset_name] [COLLATE collation_name]
        | TEXT [BINARY]
        [CHARACTER SET charset_name] [COLLATE collation_name]
        | MEDIUMTEXT [BINARY]
        [CHARACTER SET charset_name] [COLLATE collation_name]
        | LONGTEXT [BINARY]
        [CHARACTER SET charset_name] [COLLATE collation_name]
        | ENUM(value1,value2,value3,...)
        [CHARACTER SET charset_name] [COLLATE collation_name]
        | SET(value1,value2,value3,...)
        [CHARACTER SET charset_name] [COLLATE collation_name]
        | JSON
        | spatial_type

    index_col_name:
        col_name [(length)] [ASC | DESC]
    index_type:
        USING {BTREE | HASH}
    index_option:
        KEY_BLOCK_SIZE [=] value
        | index_type
        | WITH PARSER parser_name
        | COMMENT 'string'
        | {VISIBLE | INVISIBLE}
    reference_definition:
        REFERENCES tbl_name (index_col_name,...)
            [MATCH FULL | MATCH PARTIAL | MATCH SIMPLE]
            [ON DELETE reference_option]
            [ON UPDATE reference_option]
    reference_option:
        RESTRICT | CASCADE | SET NULL | NO ACTION | SET DEFAULT
    table_options:
        table_option [[,] table_option] ...
```

##### CREATE TABLESPACE Syntax 
``` sql
    CREATE TABLESPACE tablespace_name
        ADD DATAFILE 'file_name'
        [FILE_BLOCK_SIZE = value]
            [ENGINE [=] engine_name]
```

##### CREATE TRIGGER Syntax 
``` sql
    CREATE
        [DEFINER = { user | CURRENT_USER }]
        TRIGGER trigger_name
        trigger_time trigger_event
        ON tbl_name FOR EACH ROW
        [trigger_order]
        trigger_body
    trigger_time: { BEFORE | AFTER }
    trigger_event: { INSERT | UPDATE | DELETE }
    trigger_order: { FOLLOWS | PRECEDES } other_trigger_name
```

##### CREATE VIEW Syntax 
``` sql
    CREATE
        [OR REPLACE]
        [ALGORITHM = {UNDEFINED | MERGE | TEMPTABLE}]
        [DEFINER = { user | CURRENT_USER }]
        [SQL SECURITY { DEFINER | INVOKER }]
        VIEW view_name [(column_list)]
        AS select_statement
        [WITH [CASCADED | LOCAL] CHECK OPTION]
```

##### DROP DATABASE Syntax 
``` sql
    DROP {DATABASE | SCHEMA} [IF EXISTS] db_name
```

##### DROP EVENT Syntax 
``` sql
    DROP EVENT [IF EXISTS] event_name
```

##### DROP FUNCTION Syntax 


##### DROP INDEX Syntax 
``` sql
    DROP INDEX index_name ON tbl_name
        [algorithm_option | lock_option] ...
    algorithm_option:
        ALGORITHM [=] {DEFAULT|INPLACE|COPY}
    lock_option:
        LOCK [=] {DEFAULT|NONE|SHARED|EXCLUSIVE}
```

##### DROP LOGFILE GROUP Syntax 


##### DROP PROCEDURE and DROP FUNCTION Syntax 
``` sql
    DROP {PROCEDURE | FUNCTION} [IF EXISTS] sp_name
```

##### DROP SERVER Syntax 
``` sql
    DROP SERVER [ IF EXISTS ] server_name
```

##### DROP TABLE Syntax 
``` sql
    DROP [TEMPORARY] TABLE [IF EXISTS]
        tbl_name [, tbl_name] ...
        [RESTRICT | CASCADE]
```

##### DROP TABLESPACE Syntax 
``` sql
    DROP TABLESPACE tablespace_name
        [ENGINE [=] engine_name]
```

##### DROP TRIGGER Syntax 
``` sql
    DROP TRIGGER [IF EXISTS] [schema_name.]trigger_name
```

##### DROP VIEW Syntax 
``` sql
    DROP VIEW [IF EXISTS]
        view_name [, view_name] ...
        [RESTRICT | CASCADE]
```

##### RENAME TABLE Syntax 
``` sql
    RENAME TABLE tbl_name TO new_tbl_name [, tbl_name2 TO new_tbl_name2] ...
```

##### TRUNCATE TABLE Syntax 
``` sql
    TRUNCATE [TABLE] tbl_name
```

#### Data Manipulation Statements 
##### CALL Syntax 
``` sql
    CALL sp_name([parameter[,...]])
    CALL sp_name[()]
```

##### DELETE Syntax 
``` sql
    DELETE [LOW_PRIORITY] [QUICK] [IGNORE] FROM tbl_name
        [PARTITION (partition_name,...)]
        [WHERE where_condition]
        [ORDER BY ...]
        [LIMIT row_count]

    DELETE [LOW_PRIORITY] [QUICK] [IGNORE]
        tbl_name[.*] [, tbl_name[.*]] ...
        FROM table_references
        [WHERE where_condition]

    DELETE [LOW_PRIORITY] [QUICK] [IGNORE]
        FROM tbl_name[.*] [, tbl_name[.*]] ...
        USING table_references
        [WHERE where_condition]
```

##### DO Syntax 


##### HANDLER Syntax 


##### INSERT Syntax 


##### LOAD DATA INFILE Syntax 


##### LOAD XML Syntax 


##### REPLACE Syntax 


##### SELECT Syntax 


##### Subquery Syntax 


##### UPDATE Syntax


#### Transactional and Locking Statements 

##### START TRANSACTION, COMMIT, and ROLLBACK Syntax 


##### Statements That Cannot Be Rolled Back 


##### Statements That Cause an Implicit Commit 


##### SAVEPOINT, ROLLBACK TO SAVEPOINT, and RELEASE SAVEPOINT Syntax


##### LOCK TABLES and UNLOCK TABLES Syntax 


##### SET TRANSACTION Syntax 

##### XA Transactions

#### Replication Statements
#####
#####
#####
#####
#####

#### Prepared SQL Statement Syntax 
#####
#####
#####
#####
#####

#### Compound-Statement Syntax 
#####
#####
#####
#####
#####

#### Database Administration Statements
#####
#####
#####
#####
#####

#### Utility Statements
#####
#####
#####
#####
#####



