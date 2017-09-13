---
title: 开发IDE攻略
date: 2017-06-15 20:33:49
tags:
    - intellij idea
toc: true
---

[TOC]


## intellij idea

#### 文件注释模板
##### 实现
- File --> Settings --> Editor --> File and Code Templates 
    + Class
    + Interface
    + Enum
    + Scala Class
    + Scala Object


##### 中新网安(201503--201704)
``` shell
/**
 * Description: 
 * 
 * Project：${PROJECT_NAME}
 * Department：中新网安研发中心
 * User: ${USER}
 * Date: ${YEAR}-${MONTH}-${DAY}
 * Time: ${TIME}
 * Email: likai@cnzxsoft.com / likai14@cnzxsoft.com.cn
 * Copyright©2002-${YEAR} Rights Reserved 中新网安 版权所有 皖ICP备05016981号-3
 */
```

##### 海康威视(201704-- ) 
``` shell
/**
 * Description: 
 * 
 * Project：${PROJECT_NAME}
 * Department：海康研究院
 * User: ${USER}
 * Date: ${YEAR}-${MONTH}-${DAY}
 * Time: ${TIME}
 * Email: likai14@hikvision.com / likai14@hikvision.com.cn
 * Copyright©${YEAR} Rights Reserved 杭州海康威视数字技术股份有限公司 版权所有 浙ICP备05007700号-1
 */
```


### 快捷键


#### 问题集锦
##### Exception in thread "main" java.lang.OutOfMemoryError: Java heap space
解决方法：
- 编辑{IntelliJIDEA_HOME}/bin/idea64.exe.vmoptions
    + -Xms128m
    + -Xmx3400m
- File -> Settings -> Build,Execution,Deployment -> Compiler -> Build process heap size(Mb)


