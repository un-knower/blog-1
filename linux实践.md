---
title: linux实践
date: 2017-07-22 18:28:28
tags:
---


### 网络

#### ip

##### 静态ip
``` shell
DEVICE="eth0"
BOOTPROTO="dhcp"
DHCP_HOSTNAME="quickstart.cloudera"
HOSTNAME="quickstart.cloudera"
HWADDR="08:00:27:F4:65:9E"
IPV6INIT="no"
MTU="1500"
NM_CONTROLLED="yes"
ONBOOT="yes"
TYPE="Ethernet"
UUID="fe869305-39ac-485b-9ffe-52a4b5785b77"

DEVICE="eth0"
BOOTPROTO="static"
IPADDR=192.168.0.111 #本机地址
NETMASK=255.255.255.0 #子网掩码
GATEWAY=192.168.0.1 #默认网关
HOSTNAME="quickstart.cloudera"
HWADDR="08:00:27:F4:65:9E"
IPV6INIT="no"
MTU="1500"
NM_CONTROLLED="yes"
ONBOOT="yes"
TYPE="Ethernet"
UUID="fe869305-39ac-485b-9ffe-52a4b5785b77"
```


### 系统

#### 启动

##### 启动无界面
- vim /etc/inittab
	+ #id:5:initdefault
	+ id:3:initdefault