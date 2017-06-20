---
title: log系统实战
date: 2017-06-14 14:01:25
tags: 
    - log
    - slf4j
    - log4j
    - logback
    - log4j2
toc: true
---

[TOC]

## SLF4J
1. The Simple Logging Facade for Java (SLF4J) serves as a simple facade or abstraction for various logging frameworks (e.g. java.util.logging, logback, log4j) allowing the end user to plug in the desired logging framework at deployment time.

### SLF4J user manual
#### Typical usage pattern
``` java
    class Wombat {
        final Logger logger = LoggerFactory.getLogger(Wombat.class);
        Integer t;
        Integer oldT;

        public void setTemperature(Integer temperature) {
            oldT = t;
            t = temperature;
            logger.debug("Temperature set to {}. Old temperature was {}.", t, oldT);

            if (temperature.intValue() > 50) {
                logger.info("Temperature has risen above 50 degrees.");
            }
        }
    }
```

#### Binding with a logging framework at deployment time
1. slf4j-log4j12-1.8.0-alpha2.jar
Binding for log4j version 1.2, a widely used logging framework. You also need to place log4j.jar on your class path.
2. slf4j-jdk14-1.8.0-alpha2.jar
Binding for java.util.logging, also referred to as JDK 1.4 logging
3. slf4j-nop-1.8.0-alpha2.jar
Binding for NOP, silently discarding all logging.
4. slf4j-simple-1.8.0-alpha2.jar
Binding for Simple implementation, which outputs all events to System.err. Only messages of level INFO and higher are printed. This binding may be useful in the context of small applications.
5. slf4j-jcl-1.8.0-alpha2.jar
Binding for Jakarta Commons Logging. This binding will delegate all SLF4J logging to JCL.
6. logback-classic-1.0.13.jar (requires logback-core-1.0.13.jar)
NATIVE IMPLEMENTATION There are also SLF4J bindings external to the SLF4J project, e.g. logback which implements SLF4J natively. Logback's ch.qos.logback.classic.Logger class is a direct implementation of SLF4J's org.slf4j.Logger interface. Thus, using SLF4J in conjunction with logback involves strictly zero memory and computational overhead.

To switch logging frameworks, just replace slf4j bindings on your class path. For example, to switch from java.util.logging to log4j, just replace slf4j-jdk14-1.8.0-alpha2.jar with slf4j-log4j12-1.8.0-alpha2.jar.
SLF4J does not rely on any special class loader machinery. In fact, each SLF4J binding is hardwired at compile time to use one and only one specific logging framework. For example, the slf4j-log4j12-1.8.0-alpha2.jar binding is bound at compile time to use log4j. In your code, in addition to slf4j-api-1.8.0-alpha2.jar, you simply drop one and only one binding of your choice onto the appropriate class path location. Do not place more than one binding on your class path. Here is a graphical illustration of the general idea.![](https://www.slf4j.org/images/concrete-bindings.png)



### SLF4J Migrator
1. The SLF4J migrator is a small Java tool for migrating Java source files from the Jakarta Commons Logging (JCL) API to SLF4J. It can also migrate from the log4j API to SLF4J, or from java.util.logging API to SLF4J.
The SLF4J migrator consists of a single jar file that can be launched as a stand-alone java application. Here is the command:java -jar slf4j-migrator-1.8.0-alpha2.jar 

#### Limitations

### Bridging legacy APIs
1. Often, some of the components you depend on rely on a logging API other than SLF4J. You may also assume that these components will not switch to SLF4J in the immediate future. To deal with such circumstances, SLF4J ships with several bridging modules which redirect calls made to log4j, JCL and java.util.logging APIs to behave as if they were made to the SLF4J API instead. The figure below illustrates the idea.![](https://www.slf4j.org/images/legacy.png)
2. Please note that for source code under your control, you really should use the slf4j-migrator. The binary-based solutions described in this page are appropriate for software beyond your control.



## Logback![](https://logback.qos.ch/images/logos/lblogo.jpg)
1. Logback's architecture is sufficiently generic so as to apply under different circumstances. At present time, logback is divided into three modules, logback-core, logback-classic and logback-access.
2. The logback-core module lays the groundwork for the other two modules. The logback-classic module can be assimilated to a significantly improved version of log4j. Moreover, logback-classic natively implements the SLF4J API so that you can readily switch back and forth between logback and other logging frameworks such as log4j or java.util.logging (JUL).


### Appenders
Logback delegates the task of writing a logging event to components called appenders. Appenders must implement the ch.qos.logback.core.Appender interface.
![class_diagram](https://logback.qos.ch/manual/images/chapters/appenders/appenderClassDiagram.jpg)
#### ConsoleAppender
1. The ConsoleAppender, as the name indicates, appends on the console, or more precisely on System.out or System.err, the former being the default target. ConsoleAppender formats events with the help of an encoder specified by the user. Encoders will be discussed in a subsequent chapter. Both System.out and System.err are of type java.io.PrintStream. Consequently, they are wrapped inside an OutputStreamWriter which buffers I/O operations.

#### FileAppender
1. The FileAppender, a subclass of OutputStreamAppender, appends log events into a file. The target file is specified by the File option. If the file already exists, it is either appended to, or truncated depending on the value of the append property.

#### RollingFileAppender
1. RollingFileAppender extends FileAppender with the capability to rollover log files. For example, RollingFileAppender can log to a file named log.txt file and, once a certain condition is met, change its logging target to another file.

### Encoders
Encoders are responsible for transforming an event into a byte array as well as writing out that byte array into an OutputStream. 

### Layouts
Layouts are logback components responsible for transforming an incoming event into a String. The format() method in the Layout interface takes an object that represents an event (of any type) and returns a String.



### config
``` xml logback.xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <!--
       说明：
       1、日志级别及文件
           日志记录采用分级记录，级别与日志文件名相对应，不同级别的日志信息记录到不同的日志文件中
           例如：error级别记录到log_error_xxx.log或log_error.log（该文件为当前记录的日志文件），而log_error_xxx.log为归档日志，
           日志文件按日期记录，同一天内，若日志文件大小等于或大于2M，则按0、1、2...顺序分别命名
           例如log-level-2013-12-21.0.log
           其它级别的日志也是如此。
       2、文件路径
           若开发、测试用，在Eclipse中运行项目，则到Eclipse的安装路径查找logs文件夹，以相对路径../logs。
           若部署到Tomcat下，则在Tomcat下的logs文件中
       3、Appender
           FILEERROR对应error级别，文件名以log-error-xxx.log形式命名
           FILEWARN对应warn级别，文件名以log-warn-xxx.log形式命名
           FILEINFO对应info级别，文件名以log-info-xxx.log形式命名
           FILEDEBUG对应debug级别，文件名以log-debug-xxx.log形式命名
           stdout将日志信息输出到控制上，为方便开发测试使用
    -->

    <contextName>LOG_LEARN</contextName>
    <property name="LOG_PATH" value="/home/logs" />
    <!--设置系统日志目录-->
    <property name="APP_DIR" value="CHAOSDATA" />

    <!-- 不带彩色的日志在控制台输出时候的设置 -->
    <appender name="CONSOLE" class="ch.qos.logback.core.ConsoleAppender">
        <encoder>
            <!-- 格式化输出：%d表示日期，%thread表示线程名，%-5level：级别从左显示5个字符宽度%msg：日志消息，%n是换行符-->
            <pattern>%d{yyyy-MM-dd HH:mm:ss.SSS} [%thread] %-5level %logger{50} - %msg%n</pattern>
        </encoder>
    </appender>

    <!-- 日志记录器，日期滚动记录 -->
    <appender name="FILEERROR" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <!-- 正在记录的日志文件的路径及文件名 -->
        <file>${LOG_PATH}/${APP_DIR}/log_error.log</file>
        <!-- 日志记录器的滚动策略，按日期，按大小记录 -->
        <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
            <!-- 归档的日志文件的路径，例如今天是2013-12-21日志，当前写的日志文件路径为file节点指定，可以将此文件与file指定文件路径设置为不同路径，从而将当前日志文件或归档日志文件置不同的目录。
            而2013-12-21的日志文件在由fileNamePattern指定。%d{yyyy-MM-dd}指定日期格式，%i指定索引 -->
            <fileNamePattern>${LOG_PATH}/${APP_DIR}/error/log-error-%d{yyyy-MM-dd}.%i.log</fileNamePattern>
            <!-- 除按日志记录之外，还配置了日志文件不能超过2M，若超过2M，日志文件会以索引0开始，
            命名日志文件，例如log-error-2013-12-21.0.log -->
            <timeBasedFileNamingAndTriggeringPolicy class="ch.qos.logback.core.rolling.SizeAndTimeBasedFNATP">
                <maxFileSize>2MB</maxFileSize>
            </timeBasedFileNamingAndTriggeringPolicy>
        </rollingPolicy>
        <!-- 追加方式记录日志 -->
        <append>true</append>
        <!-- 日志文件的格式 -->
        <encoder class="ch.qos.logback.classic.encoder.PatternLayoutEncoder">
            <pattern>===%d{yyyy-MM-dd HH:mm:ss.SSS} %-5level %logger Line:%-3L - %msg%n</pattern>
            <charset>utf-8</charset>
        </encoder>
        <!-- 此日志文件只记录info级别的 -->
        <filter class="ch.qos.logback.classic.filter.LevelFilter">
            <level>error</level>
            <onMatch>ACCEPT</onMatch>
            <onMismatch>DENY</onMismatch>
        </filter>
    </appender>

    <!-- 日志记录器，日期滚动记录 -->
    <appender name="FILEWARN" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <!-- 正在记录的日志文件的路径及文件名 -->
        <file>${LOG_PATH}/${APP_DIR}/log_warn.log</file>
        <!-- 日志记录器的滚动策略，按日期，按大小记录 -->
        <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
            <!-- 归档的日志文件的路径，例如今天是2013-12-21日志，当前写的日志文件路径为file节点指定，可以将此文件与file指定文件路径设置为不同路径，从而将当前日志文件或归档日志文件置不同的目录。
            而2013-12-21的日志文件在由fileNamePattern指定。%d{yyyy-MM-dd}指定日期格式，%i指定索引 -->
            <fileNamePattern>${LOG_PATH}/${APP_DIR}/warn/log-warn-%d{yyyy-MM-dd}.%i.log</fileNamePattern>
            <!-- 除按日志记录之外，还配置了日志文件不能超过2M，若超过2M，日志文件会以索引0开始，
            命名日志文件，例如log-error-2013-12-21.0.log -->
            <timeBasedFileNamingAndTriggeringPolicy class="ch.qos.logback.core.rolling.SizeAndTimeBasedFNATP">
                <maxFileSize>2MB</maxFileSize>
            </timeBasedFileNamingAndTriggeringPolicy>
        </rollingPolicy>
        <!-- 追加方式记录日志 -->
        <append>true</append>
        <!-- 日志文件的格式 -->
        <encoder class="ch.qos.logback.classic.encoder.PatternLayoutEncoder">
            <pattern>===%d{yyyy-MM-dd HH:mm:ss.SSS} %-5level %logger Line:%-3L - %msg%n</pattern>
            <charset>utf-8</charset>
        </encoder>
        <!-- 此日志文件只记录info级别的 -->
        <filter class="ch.qos.logback.classic.filter.LevelFilter">
            <level>warn</level>
            <onMatch>ACCEPT</onMatch>
            <onMismatch>DENY</onMismatch>
        </filter>
    </appender>

    <!-- 日志记录器，日期滚动记录 -->
    <appender name="FILEINFO" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <!-- 正在记录的日志文件的路径及文件名 -->
        <file>${LOG_PATH}/${APP_DIR}/log_info.log</file>
        <!-- 日志记录器的滚动策略，按日期，按大小记录 -->
        <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
            <!-- 归档的日志文件的路径，例如今天是2013-12-21日志，当前写的日志文件路径为file节点指定，可以将此文件与file指定文件路径设置为不同路径，从而将当前日志文件或归档日志文件置不同的目录。
            而2013-12-21的日志文件在由fileNamePattern指定。%d{yyyy-MM-dd}指定日期格式，%i指定索引 -->
            <fileNamePattern>${LOG_PATH}/${APP_DIR}/info/log-info-%d{yyyy-MM-dd}.%i.log</fileNamePattern>
            <!-- 除按日志记录之外，还配置了日志文件不能超过2M，若超过2M，日志文件会以索引0开始，
            命名日志文件，例如log-error-2013-12-21.0.log -->
            <timeBasedFileNamingAndTriggeringPolicy class="ch.qos.logback.core.rolling.SizeAndTimeBasedFNATP">
                <maxFileSize>2MB</maxFileSize>
            </timeBasedFileNamingAndTriggeringPolicy>
        </rollingPolicy>
        <!-- 追加方式记录日志 -->
        <append>true</append>
        <!-- 日志文件的格式 -->
        <encoder class="ch.qos.logback.classic.encoder.PatternLayoutEncoder">
            <pattern>===%d{yyyy-MM-dd HH:mm:ss.SSS} %-5level %logger Line:%-3L - %msg%n</pattern>
            <charset>utf-8</charset>
        </encoder>
        <!-- 此日志文件只记录info级别的 -->
        <filter class="ch.qos.logback.classic.filter.LevelFilter">
            <level>info</level>
            <onMatch>ACCEPT</onMatch>
            <onMismatch>DENY</onMismatch>
        </filter>
    </appender>

    <!-- 日志记录器，日期滚动记录 -->
    <appender name="FILEDEBUG" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <!-- 正在记录的日志文件的路径及文件名 -->
        <file>${LOG_PATH}/${APP_DIR}/log_debug.log</file>
        <!-- 日志记录器的滚动策略，按日期，按大小记录 -->
        <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
            <!-- 归档的日志文件的路径，例如今天是2013-12-21日志，当前写的日志文件路径为file节点指定，可以将此文件与file指定文件路径设置为不同路径，从而将当前日志文件或归档日志文件置不同的目录。
            而2013-12-21的日志文件在由fileNamePattern指定。%d{yyyy-MM-dd}指定日期格式，%i指定索引 -->
            <fileNamePattern>${LOG_PATH}/${APP_DIR}/debug/log-debug-%d{yyyy-MM-dd}.%i.log</fileNamePattern>
            <!-- 除按日志记录之外，还配置了日志文件不能超过2M，若超过2M，日志文件会以索引0开始，
            命名日志文件，例如log-error-2013-12-21.0.log -->
            <timeBasedFileNamingAndTriggeringPolicy class="ch.qos.logback.core.rolling.SizeAndTimeBasedFNATP">
                <maxFileSize>2MB</maxFileSize>
            </timeBasedFileNamingAndTriggeringPolicy>
        </rollingPolicy>
        <!-- 追加方式记录日志 -->
        <append>true</append>
        <!-- 日志文件的格式 -->
        <encoder class="ch.qos.logback.classic.encoder.PatternLayoutEncoder">
            <pattern>===%d{yyyy-MM-dd HH:mm:ss.SSS} %-5level %logger Line:%-3L - %msg%n</pattern>
            <charset>utf-8</charset>
        </encoder>
        <!-- 此日志文件只记录info级别的 -->
        <filter class="ch.qos.logback.classic.filter.LevelFilter">
            <level>DEBUG</level>
            <onMatch>ACCEPT</onMatch>
            <onMismatch>DENY</onMismatch>
        </filter>
    </appender>

    <!-- <appender name="CONSOLE" class="ch.qos.logback.core.ConsoleAppender">
         &lt;!&ndash;encoder 默认配置为PatternLayoutEncoder&ndash;&gt;
         <encoder>
             <pattern>===%d{yyyy-MM-dd HH:mm:ss.SSS} %-5level %logger Line:%-3L - %msg%n</pattern>
             <charset>utf-8</charset>
         </encoder>
         &lt;!&ndash;此日志appender是为开发使用，只配置最底级别，控制台输出的日志级别是大于或等于此级别的日志信息&ndash;&gt;
         <filter class="ch.qos.logback.classic.filter.ThresholdFilter">
             <level>debug</level>
         </filter>
     </appender>-->

    <!-- show parameters for hibernate sql 专为 Hibernate 定制 -->
    <!-- <logger name="org.hibernate.type.descriptor.sql.BasicBinder"  level="TRACE" />
    <logger name="org.hibernate.type.descriptor.sql.BasicExtractor"  level="DEBUG" />
    <logger name="org.hibernate.SQL" level="DEBUG" />
    <logger name="org.hibernate.engine.QueryParameters" level="DEBUG" />
    <logger name="org.hibernate.engine.query.HQLQueryPlan" level="DEBUG" />  -->

    <!--myibatis log configure-->
    <!-- project default level -->
    <logger name="org.jon.lv" level="debug" />

    <!--log4jdbc -->
    <logger name="jdbc.sqltiming" level="debug"/>
    <logger name="com.ibatis" level="debug" />
    <logger name="com.ibatis.common.jdbc.SimpleDataSource" level="debug" />
    <logger name="com.ibatis.common.jdbc.ScriptRunner" level="debug" />
    <logger name="com.ibatis.sqlmap.engine.impl.SqlMapClientDelegate" level="debug" />
    <logger name="java.sql.Connection" level="debug" />
    <logger name="java.sql.Statement" level="debug" />
    <logger name="java.sql.PreparedStatement" level="debug" />
    <logger name="java.sql.ResultSet" level="debug" />

    <logger name="org.springframework" level="WARN" />

    <!-- 生产环境下，将此级别配置为适合的级别，以免日志文件太多或影响程序性能 -->
    <root level="INFO">
        <appender-ref ref="FILEERROR" />
        <appender-ref ref="FILEWARN" />
        <appender-ref ref="FILEINFO" />
        <appender-ref ref="FILEDEBUG" />
        <!-- 生产环境将请stdout,testfile去掉 -->
        <appender-ref ref="CONSOLE" />
    </root>

    <!-- 环境配置 -->
    <!--   <springProfile name="test,dev">
           <logger name="org.springframework.web" level="INFO"/>
           <logger name="org.springboot.sample" level="INFO" />
           <logger name="com.kfit" level="info" />
       </springProfile>-->
    <!-- 生产环境. -->
    <!--  <springProfile name="prod">
          <logger name="org.springframework.web" level="ERROR"/>
          <logger name="org.springboot.sample" level="ERROR" />
          <logger name="com.kfit" level="ERROR" />
      </springProfile>-->

    <!--日志异步到数据库 -->
    <!-- <appender name="DB" class="ch.qos.logback.classic.db.DBAppender">
        日志异步到数据库
        <connectionSource class="ch.qos.logback.core.db.DriverManagerConnectionSource">
           连接池
           <dataSource class="com.mchange.v2.c3p0.ComboPooledDataSource">
              <driverClass>com.mysql.jdbc.Driver</driverClass>
              <url>jdbc:mysql://127.0.0.1:3306/databaseName</url>
              <user>root</user>
              <password>root</password>
            </dataSource>
        </connectionSource>
  </appender> -->

    <!-- 测试环境+开发环境. 多个使用逗号隔开. -->

</configuration>
```



### How to setup SLF4J and LOGBack in a app - fast 
#### Step 1 - Add LOGBack dependency to your Maven POM
``` xml pom.xml
    <dependency>
        <groupId>ch.qos.logback</groupId>
        <artifactId>logback-classic</artifactId>
        <version>1.0.13</version>
    </dependency>
```

#### Step 2 - Import existing (starter) XML configuration files
- src
    - main<br>
        - resources
            - logback.xml
    - test
        - resources
            - logback-test.xml
            
#### Step 3 - Customize the XML configuration just enough to test
``` xml logback.xml
    <?xml version="1.0" encoding="UTF-8"?>
    <configuration>
      <appender name="STDOUT" class="ch.qos.logback.core.ConsoleAppender">
        <layout class="ch.qos.logback.classic.PatternLayout">
          <Pattern>%d{HH:mm:ss.SSS} [%thread] %-5level %logger{36} - %msg%n</Pattern>
        </layout>
      </appender>
      <logger name="com.base22" level="TRACE"/>
      <root level="debug">
        <appender-ref ref="STDOUT" />
      </root>
    </configuration>    
```

#### Step 4 - Put logging code in your classes
``` java
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

class EG {
    static final Logger LOG = LoggerFactory.getLogger(EG.class);

    public static void main(String[] args) {
        LOG.trace("Hello World!");
        LOG.debug("How are you today?");
        LOG.info("I am fine.");
        LOG.warn("I love programming.");
        LOG.error("I am programming.");
    }
}
```

#### Step 5 - Run your app and make sure it works

