---
title: linux实践
date: 2017-07-22 18:28:28
tags:
---

## 命令参考
1. 查看cpu信息	cat /proc/cpuinfo | grep name | cut -f2 -d: | uniq -c
2. 查看memory信息	free -h
3. 查看磁盘信息	df -h
4. 查看ip信息	ifconfig
5. 编辑配置文件	vim /etc/profile
6. 使修改配置文件立即生效	source /etc/profie
7. 查看系统端口	netstat –tunlp
8. 查看Java进程	jps –lv
9. 按需求得到ls部分信息：ls -l pathstr | awk '{print $5, $6, $7, $9}'
10. 查看当前linux服务器分区：df -h
11. 查看当前linux服务器硬盘：fdisk -l

## linux磁盘挂载
1. 编辑磁盘挂载信息：vi /etc/fstab 
2. fdisk -l 列出 所有/指定 磁盘设备的分区表
3. 查看磁盘历史挂载信息:dumpe2fs -h /dev/sda4




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
	+ \#id:5:init default
	+ id:3:init default


## 配置
### 时间
#### 时区
1. date -R #查看当前时区
2. tzselect	#修改时区
3. timeconfig	#适用于Redhat、centos
4. dpkg-reconfigure tzdata	#适用于Debian
5. cp /usr/share/zoneinfo/$主时区/$次时区 /etc/localtime
	a. cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime


#### 时间
1. date	#查看时间及日期
2. date -s dd/MM/yy
3. date -s HH:mm:ss
4. hwclock -w	#将时间写入BIOS，避免重启后失效


#### ntp


#### crontab
##### crontab expr
- seconds minutes hours day-of-month month day-of-week yaer
	+ seconds
		+ , - * /
	+ minutes
		+ , - * /
	+ hours
		+ , - * /
	+ day-of-month
		+ , - * / L W C
	+ month
		+ , - * /
	+ day-of-week
		+ , - * / L C #
	+ year 可选
		+ , - * /
- 符号解释
	+ *
		+ 代表整个时间段
	+ /
		+ 表示每多长时间执行一次
		+ 0/15 每隔15分钟执行一次，即：00、 15、 30、 45
		+ */15 每隔15分钟执行一次，从当前时间开始执行第一次
	+ ？
		+ 表示每月的某一天，或第几周的某一天
	+ L
		+ “6L”表示“每月的最后一个星期五”
	+ W
		+ 表示为最近工作日
	+ \#
		+ 是用来指定“的”每月第n个工作日