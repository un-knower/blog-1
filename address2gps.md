

### spark-sql数据获取
``` sql
use db_name;   -- 指定数据库
create table if not exists address_table_out (
    select address_column from source_table where condition_exp;
);
-- db_name : 数据库名
-- address_table_out : 地址字段所在源表名
-- address_column : 地址字段名
-- condition_exp : 条件表达式，比如：address_column is not null
```

#### 把casemap4 目录从hdfs上get 下来；然后进行数据加密
- hadoop dfs -get /user/hive/warehouse/db_name/table_name ./
- tar -zcf  - table_name |openssl des3 -salt -k casemapHiK+ | dd of=table_name.des3

#### 数据带回本地

#### 地址数据预处理
##### 数据切割
    0. 数据解压：$dd if=table_name.des3 |openssl des3 -d -k password | tar zxf -
    1. 合并文件：$cat ./* > part
    2. 切割文件：$split -l 1000 -d -a 3 ./part caseaddr
    3. 批量添加后缀：$find . -type f |xargs -i mv {} {}.txt
    4. 数据每行添加行号及分隔符：$nl -b a -s , ./part.txt > partR
    5. 结果数据输出给张思为

#### 调用百度地图api进行转换

