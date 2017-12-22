---
title: shell脚本实践
date: 2017-06-15 20:27:31
tags:
    - shell
toc: true
---

[TOC]

### 传参

1. 参数携带空格
	a. 用双引号就可以，这样就是一个整体;例如：test.sh "hello world" ; 脚本中取参数时也要用双引号： "$1"
``` shell
spark-submit \
--driver-memory 5g \
--num-executors 15 \
--executor-cores 1 \
--executor-memory 5g \
--master yarn \
--deploy-mode client \
--class com.hikvision.sparta.etl.load.dataload.DataLoad \
${VULCANUS_LOAD_PATH} "-r" "/sparta/vulcanus" "--allDoneNotDo" "--originTableId" "5747" "--castColumnStr" "$1"  >> ${LOGGER_PATH} 2>&1

bash bin/task-load.sh " a.HIK, TO_CHAR(a.RES) as RES"
```

2. 参数
- linux系统除了提供位置参数还提供内置参数，内置参数如下：　
    a. $# ----传递给程序的总的参数数目
    b. $? ----上一个代码或者shell程序在shell中退出的情况，如果正常退出则返回0，反之为非0值。 　　
    c. $* ----传递给程序的所有参数组成的字符串。 　　
    d. $n ----表示第几个参数，$1 表示第一个参数，$2 表示第二个参数 ... 　　$0 ----当前程序的名称 　　
	e. $@----以"参数1" "参数2" ... 形式保存所有参数 　　
	f. $$ ----本程序的(进程ID号)PID 　　
	g. $! ----上一个命令的PID

