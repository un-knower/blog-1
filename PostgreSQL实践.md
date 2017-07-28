---
title: PostgreSQL实践
date: 2017-07-23 20:56:42
tags:
    - postgreSql
---

### 安装
POSTGRE_SQL_HOME=               // 安装目录
#### 密码
- press WIN, 搜索pgadmin, 右键服务器实例->停止服务
- vim ${POSTGRE_SQL_HOME}/data/pg_hba.conf
    ``` console
    # TYPE  DATABASE        USER            ADDRESS                 METHOD

    # IPv4 local connections:
    host    all             all             127.0.0.1/32            md5
    # IPv6 local connections:
    host    all             all             ::1/128                 md5
    ```
    替换为：
    ``` console
    # TYPE  DATABASE        USER            ADDRESS                 METHOD

    # IPv4 local connections:
    host    all             all             127.0.0.1/32            trust
    # IPv6 local connections:
    host    all             all             ::1/128                 trust
    ```
- 右键服务器实例->开启服务
- 右键登录角色->新建登录角色
    + dev/chaosdata  -- 全部权限
- 右键数据库->新建数据库
    + sparksql -- owner：dev，权限：ALL