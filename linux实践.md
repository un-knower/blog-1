---
title: linux实践
date: 2017-07-22 18:28:28
tags:
---


## file
### linux 下文件加密压缩和解压的方法
#### 方法一：用tar命令 对文件加密压缩和解压
压缩：tar -zcf  - filename |openssl des3 -salt -k password | dd of=filename.des3  
此命令对filename文件进行加码压缩 生成filename.des3加密压缩文件， password 为加密的密码

解压：dd if=filename.des3 |openssl des3 -d -k password | tar zxf -  
注意命令最后面的“-”  它将释放所有文件， -k password 可以没有，没有时在解压时会提示输入密码

#### 方法二：用zip命令对文件加密压缩和解压
压缩：zip -re filename.zip filename 回车，输入2次密码  
zip -rP passwork filename.zip filename  passwork是要输入的密码  
 
解压：unzip filename.zip 按提示输入密码  
unzip -P passwork filename.zip passwork是要解压的密码，这个不会有提示输入密码的操作  

### 文件切割合并
#### 在Linux下用split进行文件分割：
##### 模式一：指定分割后文件行数
命令：split -l 300 large_file.txt new_file_prefix
    split -l 1000 -d -a 3 ./part caseaddr
    -l：按行分割，上面表示将caseaddr文件按1000行一个文件分割为多个文件
    -d：添加数字后缀
    -a 3：表示用两位数据来顺序命名
##### 模式二：指定分割后文件大小
命令：split -b 10m large_file.bin new_file_prefix

#### 在Linux下用cat进行文件合并：
命令：cat small_files* > large_file




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
	+ #id:5:init default
	+ id:3:init default