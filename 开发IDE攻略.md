---
title: 开发IDE攻略
date: 2017-06-15 20:33:49
tags:
    - intellij idea
toc: true
---

[TOC]


## intellij idea

### 快捷键


#### 问题集锦
##### Exception in thread "main" java.lang.OutOfMemoryError: Java heap space
解决方法：
- 编辑{IntelliJIDEA_HOME}/bin/idea64.exe.vmoptions
    + -Xms128m
    + -Xmx3400m
- File -> Settings -> Build,Execution,Deployment -> Compiler -> Build process heap size(Mb)
