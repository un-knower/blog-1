---
title: oozie纪要
date: 2017-06-09 11:29:28
tags: 
    - component 
    - doing
    - oozie
toc: true
---

[TOC]

## 使用经验
- catch-up mode (job's start time is in the past): 当开始时间小于当前时间，以前的定时任务也会被执行


### 对比
#### 对比Oozie以及Azkaban，个人觉得选择Oozie作为流程引擎的选型比较好，理由如下：
1. Oozie是基于Hadoop系统进行操作，而Azkaban是基于命令行进行操作。使用hadoop提供的第三方包JobClient比直接在底层跑shell命令开发成本小，可能遇到的坑也少（一个是基于平台，一个是基于系统）。
2. Oozie的操作是放在Hadoop中，而Azkaban的运行是服务器运行shell命令。为保证服务器的稳定，使用Oozie靠谱点。
3. Ooize提供查询任务执行状态，Azkaban查询的是进程执行的结果，如果某进程执行的shell命令出错，其进程仍展示位成功，混淆了任务输出。
4. Oozie将任务执行的状态持久化到数据库中，Azkaban将任务的状态存储在服务器内存中，如果掉电，则Azkaban会丢失任务信息。
5. Ooize中定义的action类型更为丰富，而Azkaban中的依赖较为简单，当面对复杂的逻辑时Oozie执行的比较顺畅

#### Oozie方案
##### 使用场景
- 需要按顺序并能够并行处理的工作流（DAG）
- 对运行结果或异常需要报警、重启
- 需要Cron的任务
- 适用于批量处理的任务，不适合实时的情况

##### 优点
- Oozie与Hadoop生态系统紧密结合，提供做种场景的抽象
- Oozie有更强大的社区支持，文档
- Job提交到hadoop集群，server本身并不启动任何job
- 通过control node/action node能够覆盖大多数的应用场景
- Coordinator支持时间、数据触发的启动模式
- 支持参数化和EL语言定义workflow，方便复用
- 结合HUE，能够方便的对workflow查看以及运维
- 结合HUE，能够完成workflow在前端页面的编辑、提交
- 支持action之间内存数据的交互（默认2K）
- 支持workflow的rerun（从某一个节点重启）

#### 以Oozie作为流程引擎的难点：
1. 定义workflow.xml的过程，需要保证有效的完成用户的逻辑且运行的过程中job不出错。
2. 部署有点麻烦。
3. 学习的成本会略高。【仁者见仁】

### oozie安装
1. oozie功能测试
2. 无非3种安装模式
    1. cdh 等提供的cloudera manager 安装方式，文档简单具体；
    2. 原生oozie官网的源码编译模式，文档清晰明了；
    3. 自己公司的安装方法模式
3. export OOZIE_URL=http://localhost:11000/oozie
4. oozie job -config ./job.properties -run
5. oozie job -kill buddle_id | coord_id | wf_id 

### oozie 实践
#### WorkflowFunctionalSpec

##### Workflow Nodes

###### Control Flow Nodes
- Start Control Node
The start node is the entry point for a workflow job, it indicates the first workflow node the workflow job must transition to.
``` xml
    <start to='BDQ_CXB_3_load'/>
```
- End Control Node
The end node is the end for a workflow job, it indicates that the workflow job has completed successfully.
- Kill Control Node
The kill node allows a workflow job to kill itself.
``` xml
    <kill name='kill'>
        <message>Something went wrong: ${wf:errorCode('firstdemo')}</message>
    </kill>
    <end name='end'/>
```
- Decision Control Node
A decision node enables a workflow to make a selection on the execution path to follow.The behavior of a decision node can be seen as a switch-case statement.
``` xml 
    <decision name="mydecision">
        <switch>
            <case to="reconsolidatejob">
                <!-- The predicate ELs are evaluated in order until one returns true and the corresponding transition is taken. -->
                ${fs:fileSize(secondjobOutputDir) gt 10 * GB}
            </case>
            <case to="rexpandjob">
                ${fs:filSize(secondjobOutputDir) lt 100 * MB}
            </case>
            <case to="recomputejob">
                ${ hadoop:counters('secondjob')[RECORDS][REDUCE_OUT] lt 1000000 }
            </case>
            <default to="end"/>
        </switch>
    </decision>
```

- Fork and Join Control Nodes
    A fork node splits one path of execution into multiple concurrent paths of execution.
    A join node waits until every concurrent execution path of a previous fork node arrives to it.
    The fork and join nodes must be used in pairs. The join node assumes concurrent execution paths are children of the same fork node.
``` xml
    <fork name="BDQ_CXB_3_fork">
        <path start="BDQ_CXB_QG_1_load"/>
        <path start="BDQ_CXB_3_core"/>
    </fork>

    <join name="end_join" to="end"/>
```


#### oozie功能测试
1. 准备文件如下：
    1. 带wordcount功能的jar包
    2. 任务配置文件目录结构如下
        --cron
            --job.properties
            --workflow.xml
            --coordinator.xml
2.具体文件内容如下：
    1. job.properties
    ``` shell
    nameNode=hdfs://master66:8020
    jobTracker=master66:18040
    queueName=default

    oozie.coord.application.path=${nameNode}/dev/oozieJob/cron
    #oozie.wf.application.path=${nameNode}/dev/oozieJob/cron
    start=2017-06-05T02:00+0800
    end=2017-06-07T03:00+0800
    workflowAppUri=${nameNode}/dev/oozieJob/cron
    oozie.use.system.libpath=true

    frequency=*/15 * * * *
    master=yarn
    deploy_mode=client
    jar_path=/usr/local/envtch/ooziejobs/envtest.jar
    class=com.chaosdata.env.WordCount
    spark_opts=--num-executors 3 --executor-cores 1 --executor-memory 1G --driver-memory 512m --conf spark.yarn.historyServer.address=http://master66:18088 --conf spark.eventLog.dir=hdfs://master66:8020/var/log/spark_hislog --conf spark.eventLog.enabled=true
    ```
    2. workflow.xml
    ``` shell
    <workflow-app name="firstdemo-wf" xmlns="uri:oozie:workflow:0.1">
        <start to='firstdemo'/>
        <action name="firstdemo">
            <spark xmlns="uri:oozie:spark-action:0.1">
                <job-tracker>${jobTracker}</job-tracker>
                <name-node>${nameNode}</name-node>
                <configuration>
                    <property>
                        <name>mapred.compress.map.output</name>
                        <value>true</value>
                    </property>
                </configuration>
                <master>${master}</master>
                <mode>${deploy_mode}</mode>
                <name>Spark wc</name>
                <class>${class}</class>
                <jar>${jar_path}</jar>
                <spark-opts>${spark_opts}</spark-opts>
            </spark>
            <ok to="end"/>
            <error to="kill"/>
        </action>
        <kill name='kill'>
            <message>Something went wrong: ${wf:errorCode('firstdemo')}</message>
        </kill>
        <end name='end'/>
    </workflow-app>
    ```
    3. coordinator.xml
    ``` shell
    <coordinator-app name="cron-wc-coord" frequency="${frequency}" start="${start}" end="${end}" timezone="Asia/Shanghai"
                     xmlns="uri:oozie:coordinator:0.2">
            <action>
            <workflow>
                <app-path>${workflowAppUri}</app-path>
                <configuration>
                    <property>
                        <name>jobTracker</name>
                        <value>${jobTracker}</value>
                    </property>
                    <property>
                        <name>nameNode</name>
                        <value>${nameNode}</value>
                    </property>
                    <property>
                        <name>queueName</name>
                        <value>${queueName}</value>
                    </property>
                </configuration>
            </workflow>
        </action>
    </coordinator-app>
    ```
3. WordCount.scala
``` scala
    package com.chaosdata.env

    import org.apache.spark.{SparkConf, SparkContext}

    object WordCount {
      def main(args: Array[String]): Unit = {
        val splitor = "\\s+"
        val conf = new SparkConf().setAppName(this.getClass.getSimpleName)
        //    .setMaster("yarn-cluster")
    //          .setMaster("local")

        val sc = new SparkContext(conf)
        val resultRdd = sc.textFile("/dev/datacenter/input/env/*").flatMap(_.split(splitor).map(word => (word, 1))).reduceByKey(_ + _)
        resultRdd.saveAsTextFile("/dev/datacenter/output/env/spark/output/" + System.currentTimeMillis())

        sc.stop()
      }
    }
```
4. 打成uber jar；即全量jar
    1. intellij默认打包：
        1. Project Structure --> Project Settings --> Artifacts --> 点击绿色+ --> JAR --> from Modules with Dependencies --> OK
        2. Build --> Build Artifact --> 选择Artifact --> rebuild
    2. maven shade插件


#### oozie sharelib 部署
1. 编译形成sharelib并压缩成tar文件
2. 部署sharelib到hdfs上：
    ``` shell
        $oozie-setup.sh sharelib create -fs hdfs://master66:8020 -locallib ./
        ${OOZIE_HOME}bin/oozie-sharelib-4.1.0-cdh5.4.1.tar.gz
        ${OOZIE_HOME}bin/oozie admin -sharelibupdate  -oozie http://localhost:11000/oozie
        ${OOZIE_HOME}bin/oozie admin -shareliblist -oozie http://localhost:11000/oozie
    ```

#### oozie sharelib 编译
1. 签下对应版本源代码,假设路劲 OOZIE_SRC_HOME=E:\developPlat\openSrc\oozie-cdh5-4.1.0_5.11.0
``` shell
    git https://github.com/cloudera/oozie.git #签下代码
    cd ${OOZIE_SRC_HOME}/sharelib/spark
    mvn -DskipTests clean package assembly:single
    cd ../oozie
    mvn -DskipTests clean package assembly:single
    cd ${OOZIE_SRC_HOME}/sharelib ##最终版本
    mvn -DskipTests clean package assembly:single
```
2. 取出编译好的文件备用
    1. ${OOZIE_SRC_HOME}/sharelib/spark/target/partial-sharelib/share/lib/oozie/oozie-sharelib-spark-4.1.0-cdh5.11.0.jar
    2. ${OOZIE_SRC_HOME}/sharelib/oozie/target/partial-sharelib/share/lib/oozie/oozie-sharelib-oozie-4.1.0-cdh5.11.0.jar
    3. ${OOZIE_SRC_HOME}/sharelib/oozie/target/partial-sharelib/share/lib/oozie/oozie-hadoop-utils-2.6.0-cdh5.11.0.oozie-4.1.0-cdh5.11.0.jar
    4. 取出${OOZIE_SRC_HOME}/sharelib/target/oozie-sharelib-4.1.0-cdh5.11.0-sharelib.tar.gz ##最终版本

#### oozie配置使用mysql数据库
1. 创建数据库：
    ``` sql
        create database ooziedb;
        grant all privileges on ooziedb to 'oozie'@'localhost' identified by 'passwd';
        grant all privileges on ooziedb to 'oozie'@'%' identified by 'passwd';
        flush privileges;

        -- ERROR 1045 (28000): Access denied for user 'root'@'localhost' (using password: NO)


    ```
2. 修改配置使用mysql数据库
    ``` xml
        <property>
            <name>oozie.db.schema.id</name>
            <value>ooziedb</value>
        </property>
        <property>
            <name>oozie.service.JPAService.create.db.schema</name>
            <value>true</value>
        </property>
        <property>
            <name>oozie.service.StoreService.jdbc.driver</name>
            <value>com.mysql.jdbc.Driver</value>
        </property>
        <property>
            <name>oozie.service.StoreService.jdbc.url</name>
            <value>jdbc:mysql://localhost:3306/ooziedb</value>
        </property>
        <property>
            <name>oozie.service.StoreService.jdbc.username</name>
            <value>oozie</value>
        </property>
        <property>
            <name>oozie.service.StoreService.jdbc.password</name>
            <value>passwd</value>
        </property>
    ```
3. 拷贝mysql-connector-java-x.y.z.jar到${OOZIE_HOME}/bin/libtools/
4. 重启

### oozie metadata

#### oozie db
1. BUNDLE_ACTIONS
2. BUNDLE_JOBS
3. COORD_ACTIONS
4. COORD_JOBS
5. WF_ACTIONS
6. WF_JOBS

7. OPENJPA_SEQUENCE_TABLE
8. SLA_EVENTS
9. SLA_REGISTRATION
10. SLA_SUMMARY
11. VALIDATE_CONN


### oozie workflow ReRun

#### Configs
1. oozie.wf.application.path
2. only one of following two configurations is mandatory(强制性). both should not be defined at the same time
    1. oozie.wf.rerun.skip.nodes
    Skip nodes are comma separated list of action names. They can be any action nodes including decision node.
    2. oozie.wf.rerun.failnodes
    The valid value of oozie.wf.rerun.failnodes is true or false.
3. if secured hadoop version is used, the following two properties needs to be specified as well
    1. mapreduce.jobtracker.kerberos.principal
    2. dfs.namenode.kerberos.principal.
4. configurations can be passed as -D param.
5. eg:
``` shell
    oozie job -oozie http://localhost:11000/oozie -rerun 14-20090525161321-oozie-joe -Doozie.wf.rerun.skip.nodes=<>
```


#### Pre-Conditions
1. workflow with id wfId should exist.
2. workflow with id wfId should be in SUCCEEDED/KILLED/FAILED.
3. if specified, nodes in the config oozie.wf.rerun.skip.nodes must be completed successfully.

#### Rerun
1. reloads the configs
2. if no configuration is passed, existing coordinator/workflow configuration will be used. If configuration is passed then, it will be merged with existing workflow configuration. Input configuration will take the precedence
3. currently there is no way to renove an existing configuration but only override by passing a different value in the input configuration.
4. creates a new workflow instance with the same wfId
5. Deletes the actions that are not skipped from the DB and copies data from old Workflow Instance to new one for skipped actions.
6. Action handler will skip the nodes given in the config with the same exit transition as before.

#### 实践
- job DAG: start-->one-->two-->three-->four-->end
- $oozie job -oozie http://localhost:11000/oozie -config ./job.properties -run
- job: 0000001-170621145954325-oozie-root-W
- $oozie job -oozie http://localhost:11000/oozie -kill 0000001-170621145954325-oozie-root-W   执行到three
- $oozie job -rerun 0000001-170621145954325-oozie-root-W -Doozie.wf.rerun.failnodes=true      重新执行完three-->four-->end
- oozie job -rerun 0000002-170630001302466-oozie-root-W -Doozie.wf.rerun.failnodes=true -config ./job_cm.properties #更新配置文件，需带上-config生效



### oozie restful
    



### Oozie Command Line Usage
usage:
      the env variable 'OOZIE_URL' is used as default value for the '-oozie' option
      the env variable 'OOZIE_TIMEZONE' is used as default value for the '-timezone' option
      the env variable 'OOZIE_AUTH' is used as default value for the '-auth' option
      custom headers for Oozie web services can be specified using '-Dheader:NAME=VALUE'

#### Oozie basic commands
oozie help      : display usage
oozie version   : show client version

#### Oozie job operation commands
``` shell
oozie job <OPTIONS>           : job operations
          -action <arg>         coordinator rerun/kill on action ids (requires -rerun/-kill);
                                coordinator log retrieval on action ids (requires -log)
          -allruns              Get workflow jobs corresponding to a coordinator action
                                including all the reruns
          -auth <arg>           select authentication type [SIMPLE|KERBEROS]
          -change <arg>         change a coordinator or bundle job
          -config <arg>         job configuration file '.xml' or '.properties'
          -configcontent <arg>  job configuration
          -coordinator <arg>    bundle rerun on coordinator names (requires -rerun)
          -D <property=value>   set/override value for given property
          -date <arg>           coordinator/bundle rerun on action dates (requires -rerun);
                                coordinator log retrieval on action dates (requires -log)
          -debug                Use debug mode to see debugging statements on stdout
          -definition <arg>     job definition
          -diff <arg>           Show diff of the new coord definition and properties with the
                                existing one (default true)
          -doas <arg>           doAs user, impersonates as the specified user
          -dryrun               Dryrun a workflow (since 3.3.2) or coordinator (since 2.0)
                                job without actually executing it
          -failed               re-runs the failed workflow actions of the coordinator actions (requires -rerun)
          -filter <arg>         <key><comparator><value>[;<key><comparator><value>]*
                                (All Coordinator actions satisfying the filters will be retrieved).
                                key: status or nominaltime
                                comparator: =, !=, <, <=, >, >=. = is used as OR and others as AND
                                status: values are valid status like SUCCEEDED, KILLED etc. Only = and != apply
                                 for status.
                                nominaltime: time of format yyyy-MM-dd'T'HH:mm'Z'
          -ignore <arg>         change status of a coordinator job or action to IGNORED
                                (-action required to ignore coord actions)
          -info <arg>           info of a job
          -interval <arg>       polling interval in minutes (default is 5, requires -poll)
          -kill <arg>           kill a job (coordinator can mention -action or -date)
          -len <arg>            number of actions (default TOTAL ACTIONS, requires -info)
          -localtime            use local time (same as passing your time zone to -timezone).
                                Overrides -timezone option
          -log <arg>            job log
          -errorlog <arg>       job error log
          -auditlog <arg>       job audit log
          -logfilter <arg>      job log search parameter. Can be specified as -logfilter
                                opt1=val1;opt2=val1;opt3=val1. Supported options are recent,
                                start, end, loglevel, text, limit and debug
          -nocleanup            do not clean up output-events of the coordinator rerun
                                actions (requires -rerun)
          -offset <arg>         job info offset of actions (default '1', requires -info)
          -oozie <arg>          Oozie URL
          -order <arg>          order to show coord actions (default ascending order, 'desc'
                                for descending order, requires -info)
          -poll <arg>           poll Oozie until a job reaches a terminal state or a timeout
                                occurs
          -refresh              re-materialize the coordinator rerun actions (requires
                                -rerun)
          -rerun <arg>          rerun a job  (coordinator requires -action or -date, bundle
                                requires -coordinator or -date)
          -resume <arg>         resume a job
          -run                  run a job
          -start <arg>          start a job
          -submit               submit a job
          -suspend <arg>        suspend a job
          -timeout <arg>        timeout in minutes (default is 30, negative values indicate
                                no timeout, requires -poll)
          -timezone <arg>       use time zone with the specified ID (default GMT).
                                See 'oozie info -timezones' for a list
          -update <arg>         Update coord definition and properties
          -value <arg>          new endtime/concurrency/pausetime value for changing a
                                coordinator job
          -verbose              verbose mode
          -sladisable           disables sla alerts for the job and its children
          -slaenable            enables sla alerts for the job and its children
          -slachange            Update sla param for jobs, supported param are should-start, should-end and max-duration
```
#### Oozie jobs operation commands
``` shell
oozie jobs <OPTIONS>          : jobs status
           -auth <arg>          select authentication type [SIMPLE|KERBEROS]
           -doas <arg>          doAs user, impersonates as the specified user.
           -filter <arg>        user=<U>\;name=<N>\;group=<G>\;status=<S>\;frequency=<F>\;unit=<M>\;startcreatedtime=<SC>\;
                                endcreatedtime=<EC>\;sortby=<SB>
           -jobtype <arg>       job type ('Supported in Oozie-2.0 or later versions ONLY - coordinator' or 'wf' (default))
           -len <arg>           number of jobs (default '100')
           -localtime           use local time (same as passing your time zone to -timezone). Overrides -timezone option
           -offset <arg>        jobs offset (default '1')
           -oozie <arg>         Oozie URL
           -timezone <arg>      use time zone with the specified ID (default GMT). See 'oozie info -timezones' for a list
           -kill                kill all jobs that satisfy the filter, len, offset, or/and jobtype options. If it's used without
                                other options, it will kill all the first 50 workflow jobs. Command will fail if one or more
                                of the jobs is in wrong state.
           -suspend             suspend all jobs that satisfy the filter, len, offset, or/and jobtype options. If it's used without
                                other options, it will suspend all the first 50 workflow jobs. Command will fail if one or more
                                of the jobs is in wrong state.
           -resume              resume all jobs that satisfy the filter, len, offset, or/and jobtype options. If it's used without
                                other options, it will resume all the first 50 workflow jobs. Command will fail if one or more
                                of the jobs is in wrong state.
           -verbose             verbose mode
```

#### Oozie admin operation commands
``` shell
oozie admin <OPTIONS>         : admin operations
            -auth <arg>         select authentication type [SIMPLE|KERBEROS]
            -configuration      show Oozie system configuration
            -doas <arg>         doAs user, impersonates as the specified user
            -instrumentation    show Oozie system instrumentation
            -javasysprops       show Oozie Java system properties
            -metrics            show Oozie system metrics
            -oozie <arg>        Oozie URL
            -osenv              show Oozie system OS environment
            -queuedump          show Oozie server queue elements
            -servers            list available Oozie servers (more than one only if HA is enabled)
            -shareliblist       List available sharelib that can be specified in a workflow action
            -sharelibupdate     Update server to use a newer version of sharelib
            -status             show the current system status
            -systemmode <arg>   Supported in Oozie-2.0 or later versions ONLY. Change oozie
                                system mode [NORMAL|NOWEBSERVICE|SAFEMODE]
            -version            show Oozie server build version
```
#### Oozie validate command
oozie validate <OPTIONS> <ARGS>   : validate a workflow, coordinator, bundle XML file
                     -auth <arg>    select authentication type [SIMPLE|KERBEROS]
                     -oozie <arg>   Oozie URL

#### Oozie SLA operation commands
oozie sla <OPTIONS>           : sla operations (Deprecated as of Oozie 4.0)
          -auth <arg>           select authentication type [SIMPLE|KERBEROS]
          -len <arg>            number of results (default '100', max limited by oozie server setting which defaults to '1000')
          -offset <arg>         start offset (default '0')
          -oozie <arg>          Oozie URL
          -filter <arg>         jobid=<JobID/ActionID>\;appname=<Application Name>

#### Oozie Pig submit command
oozie pig <OPTIONS> -X <ARGS> : submit a pig job, everything after '-X' are pass-through parameters to pig, any '-D' arguments
                                after '-X' are put in <configuration>
          -auth <arg>           select authentication type [SIMPLE|KERBEROS]
          -doas <arg>           doAs user, impersonates as the specified user.
          -config <arg>         job configuration file '.properties'
          -D <property=value>   set/override value for given property
          -file <arg>           Pig script
          -oozie <arg>          Oozie URL
          -P <property=value>   set parameters for script

#### Oozie Hive submit command
oozie hive <OPTIONS> -X<ARGS>  : submit a hive job, everything after '-X' are pass-through parameters to hive, any '-D' arguments
 after '-X' are put in <configuration>
           -auth <arg>           select authentication type [SIMPLE|KERBEROS]
           -config <arg>         job configuration file '.properties'
           -D <property=value>   set/override value for given property
           -doas <arg>           doAs user, impersonates as the specified user
           -file <arg>           hive script
           -oozie <arg>          Oozie URL
           -P <property=value>   set parameters for script

#### Oozie Sqoop submit command
oozie sqoop <OPTIONS> -X<ARGS> : submit a sqoop job, any '-D' arguments after '-X' are put in <configuration>
           -auth <arg>           select authentication type [SIMPLE|KERBEROS]
           -config <arg>         job configuration file '.properties'
           -D <property=value>   set/override value for given property
           -doas <arg>           doAs user, impersonates as the specified user
           -command <arg>        sqoop command
           -oozie <arg>          Oozie URL

#### Oozie info command
oozie info <OPTIONS>           : get more detailed info about specific topics
          -timezones             display a list of available time zones

#### Oozie MapReduce job command
oozie mapreduce <OPTIONS>           : submit a mapreduce job
                -auth <arg>           select authentication type [SIMPLE|KERBEROS]
                -config <arg>         job configuration file '.properties'
                -D <property=value>   set/override value for given property
                -doas <arg>           doAs user, impersonates as the specified user
                -oozie <arg>          Oozie URL


#### 生成workflow.xml文件
##### 生成action xml单元
``` scala
package com.chaosdata.oozie

/**
  * Created by likai on 2017/6/20.
  * 构造oozie workflow.xml 文件 action配置单元
  */
class SparkActionXml(name: String, okto: String, appname: String, clzname: String, args: String) {

  val baseSparkXml =
    "    <action name=\"" + name + "\">\n" +
      "        <spark xmlns=\"uri:oozie:spark-action:0.1\">\n" +
      "            <job-tracker>${jobTracker}</job-tracker>\n" +
      "            <name-node>${nameNode}</name-node>\n" +
      "            <configuration>\n" +
      "                <property>\n" +
      "                    <name>mapred.compress.map.output</name>\n" +
      "                    <value>true</value>\n" +
      "                </property>\n" +
      "            </configuration>\n" +
      "            <master>${master}</master>\n" +
      "            <mode>${deploy_mode}</mode>\n" +
      "            <name>" + appname + "</name>\n" +
      "            <class>" + clzname + "</class>\n" +
      "            <jar>${jar_path}</jar>\n" +
      args +
      "            <spark-opts>${spark_opts}</spark-opts>\n" +
      "        </spark>\n" +
      "        <ok to=\"" + okto + "\"/>\n" +
      "        <error to=\"kill\"/>\n" +
      "    </action>\n"
}
```
##### 生成workflow 单元
``` scala
/**
  * Created by likai14 on 2017/6/20.
  * 构造oozie workflow 文件
  */
class WorkflowXml(appname: String, startto: String, actionsXml: String) {
  val baseXml =
    "<workflow-app name=\"" + appname + "-wf\" xmlns=\"uri:oozie:workflow:0.1\">\n" +
      "    <start to='" + startto + "'/>\n" +
      actionsXml +
      "    <kill name='kill'>\n" +
      "        <message>Something went wrong: ${wf:errorCode('firstdemo')}</message>\n" +
      "    </kill>\n" +
      "    <end name='end'/>\n" +
      "</workflow-app>\n"
}
```
##### 生成workflow.xml 业务逻辑



## 作业调度




### 借鉴
#### oozie 重新提交作业
在oozie的运行过程当中可能会出现错误，比如数据库连接不上，或者作业执行报错导致流程进入suspend或者killed状态，这个时候我们就要分析了，如果确实是数据或者是网络有问题，我们比如把问题解决了才可以重新运行作业。重新运行作业分两种情况，suspend状态和killed状态的，这两种状态是要通过不同的处理方式来处理的。
1. suspend状态的我们可以用resume方式来在挂起的地方恢复作业，重新运行，或者是先杀掉它，让它进入killed状态，再进行重新运行
``` java
    public static void resumeJob(String jobId) {
        try {
            OozieClient wc = new OozieClient("http://192.168.1.133:11000/oozie");
            wc.resume(jobId);
        } catch (OozieClientException e) {
            log.error(e);
        }
    }
    public static void killJob(String jobId) {
        try {
            OozieClient wc = new OozieClient("http://192.168.1.133:11000/oozie");
            wc.kill(jobId);
        } catch (OozieClientException e) {
            log.error(e);
        }
    }
```
2. killed状态的重新运行方法和它不一样，下面先贴出代码
``` java
    public static void reRunJob(String jobId, Properties conf) {
        OozieClient wc = new OozieClient("http://192.168.1.133:11000/oozie");
        try {
            Properties properties = wc.createConfiguration();
            properties.setProperty("nameNode", "hdfs://192.168.1.133:9000");
            properties.setProperty("queueName", "default");
            properties.setProperty("examplesRoot", "examples");
            properties
                    .setProperty("oozie.wf.application.path",
                            "${nameNode}/user/cenyuhai/${examplesRoot}/apps/map-reduce");
            properties.setProperty("outputDir", "map-reduce");
            properties.setProperty("jobTracker", "http://192.168.1.133:9001");
            properties.setProperty("inputDir",
                    "/user/cenyuhai/examples/input-data/text");
            properties.setProperty("outputDir",
                    "/user/cenyuhai/examples/output-data/map-reduce");
            properties.setProperty("oozie.wf.rerun.failnodes", "true");
            //这两个参数只能选一个，第一个是重新运行失败的节点，第二个是需要跳过的节点
            // properties.setProperty("oozie.wf.rerun.skip.nodes", ":start:");
            wc.reRun(jobId, properties);
        } catch (OozieClientException e) {
            log.error(e);
        }
    }
```

#### oozie java api提交作业
1. java demo
``` java
        OozieClient wc = new OozieClient("http://192.168.1.133:11000/oozie"); 
        Properties conf = wc.createConfiguration(); 
        //conf.setProperty(OozieClient.APP_PATH,"hdfs://192.168.1.133:9000"  + appPath); 
        conf.setProperty("nameNode", "hdfs://192.168.1.133:9000"); 
        conf.setProperty("queueName", "default"); 
        conf.setProperty("examplesRoot", "examples"); 
        conf.setProperty("oozie.wf.application.path", "${nameNode}/user/cenyuhai/${examplesRoot}/apps/map-reduce"); 
        conf.setProperty("outputDir", "map-reduce"); 
        conf.setProperty("jobTracker", "http://192.168.1.133:9001"); 
        conf.setProperty("inputDir", input); 
        conf.setProperty("outputDir", output);

        try { 
            String jobId = wc.run(conf); 
            return jobId; 
        } catch (OozieClientException e) { 
            log.error(e); 
        }
```



### 问题集锦
1. ERROR 1819 (HY000): Your password does not satisfy the current policy requirements
解决办法：密码需要同时包含大小写字母及数字
2. javax.servlet.jsp.el.ELException: variable [spark] cannot be resolved
解决办法：oozei变量命名不可以有“-”等特殊字符，如spark-opts是非法的，可改成spark_opts
3. 版本不一致：
    ``` shell
    Failing Oozie Launcher, Main class [org.apache.oozie.action.hadoop.SparkMain], main() threw exception, Expected static method org.apache.oozie.action.hadoop.SparkMain.loadActionConf()Lorg/apache/hadoop/conf/Configuration;
    java.lang.IncompatibleClassChangeError: Expected static method org.apache.oozie.action.hadoop.SparkMain.loadActionConf()Lorg/apache/hadoop/conf/Configuration;
        at org.apache.oozie.action.hadoop.SparkMain.run(SparkMain.java:84)
        at org.apache.oozie.action.hadoop.LauncherMain.run(LauncherMain.java:46)
        at org.apache.oozie.action.hadoop.SparkMain.main(SparkMain.java:78)
        at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
        at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:57)
        at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
        at java.lang.reflect.Method.invoke(Method.java:606)
        at org.apache.oozie.action.hadoop.LauncherMapper.map(LauncherMapper.java:228)
        at org.apache.hadoop.mapred.MapRunner.run(MapRunner.java:54)
        at org.apache.hadoop.mapred.MapTask.runOldMapper(MapTask.java:453)
        at org.apache.hadoop.mapred.MapTask.run(MapTask.java:343)
        at org.apache.hadoop.mapred.LocalContainerLauncher$EventHandler.runSubtask(LocalContainerLauncher.java:388)
        at org.apache.hadoop.mapred.LocalContainerLauncher$EventHandler.runTask(LocalContainerLauncher.java:302)
        at org.apache.hadoop.mapred.LocalContainerLauncher$EventHandler.access$200(LocalContainerLauncher.java:187)
        at org.apache.hadoop.mapred.LocalContainerLauncher$EventHandler$1.run(LocalContainerLauncher.java:230)
        at java.util.concurrent.Executors$RunnableAdapter.call(Executors.java:471)
        at java.util.concurrent.FutureTask.run(FutureTask.java:262)
        at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1145)
        at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:615)
        at java.lang.Thread.run(Thread.java:745)
    ```
解决办法：
    1. 编译相应版本的jar
        1. oozie-sharelib-spark-4.1.0-cdh5.11.0.jar
        2. oozie-hadoop-utils-2.6.0-cdh5.11.0.oozie-4.1.0-cdh5.11.0.jar
        3. oozie-sharelib-oozie-4.1.0-cdh5.11.0.jar
    2. 替换${OOZIE_HOME}/oozie-server/webapps/oozie/WEB-INF/lib 下这3个对应的jar
    3. 替换${OOZIE_HOME}/libtools 下这3个对应的jar  
4. oozie yarn-cluster 部署运行失败
日志：
    1. Log Type: stderr
    ``` shell
    Log Type: stderr
    Log Upload Time: Wed Jun 14 14:07:51 +0800 2017
    Log Length: 33883

    Parsed arguments:
      master                  yarn
      deployMode              cluster
      executorMemory          1G
      executorCores           1
      totalExecutorCores      null
      propertiesFile          null
      driverMemory            512m
      driverCores             null
      driverExtraClassPath    $PWD/*
      driverExtraLibraryPath  null
      driverExtraJavaOptions  -Dlog4j.configuration=spark-log4j.properties
      supervise               false
      queue                   null
      numExecutors            3
      pyFiles                 null
      archives                null
      mainClass               com.hikvision.env.WordCount
      primaryResource         file:/usr/local/envtch/ooziejobs/envtest.jar
      name                    Spark wc
      childArgs               []
      jars                    null
      packages                null
      packagesExclusions      null
      repositories            null
      verbose                 true

    Spark properties used, including those specified through
     --conf and those from the properties file null:
      spark.oozie.action.id -> 0000202-170613162811875-oozie-root-W@firstdemo
      spark.oozie.HadoopAccessorService.created -> true
      spark.yarn.security.tokens.hive.enabled -> false
      spark.yarn.tags -> oozie-8ae6608c2b483ad28959eb0cb5308ca3
      spark.yarn.jars -> hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/spark-yarn_2.11-2.1.0.jar
      spark.yarn.historyServer.address -> http://master66:18088
      spark.eventLog.enabled -> true
      spark.oozie.job.id -> 0000202-170613162811875-oozie-root-W
      spark.executor.extraJavaOptions -> -Dlog4j.configuration=spark-log4j.properties
      spark.yarn.security.tokens.hbase.enabled -> false
      spark.driver.extraJavaOptions -> -Dlog4j.configuration=spark-log4j.properties
      spark.eventLog.dir -> hdfs://master66:8020/var/log/spark_hislog
      spark.executor.extraClassPath -> $PWD/*
      spark.driver.extraClassPath -> $PWD/*

        
    Main class:
    org.apache.spark.deploy.yarn.Client
    Arguments:
    --jar
    file:/usr/local/envtch/ooziejobs/envtest.jar
    --class
    com.hikvision.env.WordCount
    System properties:
    spark.oozie.action.id -> 0000202-170613162811875-oozie-root-W@firstdemo
    spark.oozie.HadoopAccessorService.created -> true
    spark.yarn.security.tokens.hive.enabled -> false
    spark.yarn.tags -> oozie-8ae6608c2b483ad28959eb0cb5308ca3
    spark.executor.memory -> 1G
    spark.driver.memory -> 512m
    spark.yarn.jars -> hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/spark-yarn_2.11-2.1.0.jar
    spark.executor.instances -> 3
    spark.yarn.historyServer.address -> http://master66:18088
    spark.eventLog.enabled -> true
    spark.oozie.job.id -> 0000202-170613162811875-oozie-root-W
    SPARK_SUBMIT -> true
    spark.executor.extraJavaOptions -> -Dlog4j.configuration=spark-log4j.properties
    spark.app.name -> Spark wc
    spark.yarn.security.tokens.hbase.enabled -> false
    spark.driver.extraJavaOptions -> -Dlog4j.configuration=spark-log4j.properties
    spark.submit.deployMode -> cluster
    spark.executor.extraClassPath -> $PWD/*
    spark.eventLog.dir -> hdfs://master66:8020/var/log/spark_hislog
    spark.master -> yarn
    spark.executor.cores -> 1
    spark.driver.extraClassPath -> $PWD/*
    Classpath elements:



    Failing Oozie Launcher, Main class [org.apache.oozie.action.hadoop.SparkMain], main() threw exception, Application application_1497340444423_0429 finished with failed status
    org.apache.spark.SparkException: Application application_1497340444423_0429 finished with failed status
        at org.apache.spark.deploy.yarn.Client.run(Client.scala:1167)
        at org.apache.spark.deploy.yarn.Client$.main(Client.scala:1213)
        at org.apache.spark.deploy.yarn.Client.main(Client.scala)
        at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
        at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:57)
        at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
        at java.lang.reflect.Method.invoke(Method.java:606)
        at org.apache.spark.deploy.SparkSubmit$.org$apache$spark$deploy$SparkSubmit$$runMain(SparkSubmit.scala:738)
        at org.apache.spark.deploy.SparkSubmit$.doRunMain$1(SparkSubmit.scala:187)
        at org.apache.spark.deploy.SparkSubmit$.submit(SparkSubmit.scala:212)
        at org.apache.spark.deploy.SparkSubmit$.main(SparkSubmit.scala:126)
        at org.apache.spark.deploy.SparkSubmit.main(SparkSubmit.scala)
        at org.apache.oozie.action.hadoop.SparkMain.runSpark(SparkMain.java:372)
        at org.apache.oozie.action.hadoop.SparkMain.run(SparkMain.java:282)
        at org.apache.oozie.action.hadoop.LauncherMain.run(LauncherMain.java:64)
        at org.apache.oozie.action.hadoop.SparkMain.main(SparkMain.java:82)
        at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
        at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:57)
        at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
        at java.lang.reflect.Method.invoke(Method.java:606)
        at org.apache.oozie.action.hadoop.LauncherMapper.map(LauncherMapper.java:234)
        at org.apache.hadoop.mapred.MapRunner.run(MapRunner.java:54)
        at org.apache.hadoop.mapred.MapTask.runOldMapper(MapTask.java:453)
        at org.apache.hadoop.mapred.MapTask.run(MapTask.java:343)
        at org.apache.hadoop.mapred.LocalContainerLauncher$EventHandler.runSubtask(LocalContainerLauncher.java:388)
        at org.apache.hadoop.mapred.LocalContainerLauncher$EventHandler.runTask(LocalContainerLauncher.java:302)
        at org.apache.hadoop.mapred.LocalContainerLauncher$EventHandler.access$200(LocalContainerLauncher.java:187)
        at org.apache.hadoop.mapred.LocalContainerLauncher$EventHandler$1.run(LocalContainerLauncher.java:230)
        at java.util.concurrent.Executors$RunnableAdapter.call(Executors.java:471)
        at java.util.concurrent.FutureTask.run(FutureTask.java:262)
        at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1145)
        at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:615)
        at java.lang.Thread.run(Thread.java:745)
    ```
2. Log Type: stdout
    ``` console
    Log Type: stdout
    Log Upload Time: Wed Jun 14 14:07:51 +0800 2017
    Log Length: 200386
    Oozie Launcher starts

    Heart beat
    {"properties":[{"key":"oozie.launcher.job.id","value":"job_1497340444423_0428","isFinal":false,"resource":"programatically"},{"key":"oozie.job.id","value":"0000202-170613162811875-oozie-root-W","isFinal":false,"resource":"programatically"},{"key":"oozie.action.id","value":"0000202-170613162811875-oozie-root-W@firstdemo","isFinal":false,"resource":"programatically"}]}Starting the execution of prepare actions
    Completed the execution of prepare actions successfully

    Oozie Java/Map-Reduce/Pig action launcher-job configuration
    =================================================================
    Workflow job id   : 0000202-170613162811875-oozie-root-W
    Workflow action id: 0000202-170613162811875-oozie-root-W@firstdemo

    Classpath         :
    ------------------------
     
    ------------------------

    Main class        : org.apache.oozie.action.hadoop.SparkMain

    Maximum output    : 2048

    Arguments         :

    Java System Properties:
    ------------------------
    #
    #Wed Jun 14 14:07:34 CST 2017
    java.runtime.name=Java(TM) SE Runtime Environment

    ------------------------

    =================================================================

    >>> Invoking Main class now >>>

    Fetching child yarn jobs
    Could not find Yarn tags property oozie.child.mapreduce.job.tagsSpark Version 2.1.0
    Spark Action Main class        : org.apache.spark.deploy.SparkSubmit

    Oozie Spark action configuration
    =================================================================

                        --master
                        yarn
                        --deploy-mode
                        cluster
                        --name
                        Spark wc
                        --class
                        com.hikvision.env.WordCount
                        --conf
                        spark.oozie.action.id=0000202-170613162811875-oozie-root-W@firstdemo
                        --conf
                        spark.oozie.HadoopAccessorService.created=true
                        --conf
                        spark.oozie.job.id=0000202-170613162811875-oozie-root-W
                        --num-executors
                        3
                        --executor-cores
                        1
                        --executor-memory
                        1G
                        --driver-memory
                        512m
                        --conf
                        spark.yarn.historyServer.address=http://master66:18088
                        --conf
                        spark.eventLog.dir=hdfs://master66:8020/var/log/spark_hislog
                        --conf
                        spark.eventLog.enabled=true
                        --conf
                        spark.executor.extraClassPath=$PWD/*
                        --conf
                        spark.driver.extraClassPath=$PWD/*
                        --conf
                        spark.yarn.tags=oozie-8ae6608c2b483ad28959eb0cb5308ca3
                        --conf
                        spark.yarn.security.tokens.hive.enabled=false
                        --conf
                        spark.yarn.security.tokens.hbase.enabled=false
                        --conf
                        spark.executor.extraJavaOptions=-Dlog4j.configuration=spark-log4j.properties
                        --conf
                        spark.driver.extraJavaOptions=-Dlog4j.configuration=spark-log4j.properties
                        --files
                        hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/parquet-format-2.3.0-incubating.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/jackson-annotations-2.6.5.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/jersey-media-jaxb-2.22.2.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/commons-crypto-1.0.0.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/commons-net-3.1.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/javax.inject-2.4.0-b34.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/spark-graphx_2.11-2.1.0.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/httpclient-4.2.5.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/httpcore-4.2.5.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/xz-1.0.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/parquet-encoding-1.8.1.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/spire_2.11-0.7.4.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/commons-pool-1.5.4.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/jackson-databind-2.6.5.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/derby-10.10.1.1.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/snappy-java-1.0.4.1.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/pmml-model-1.2.15.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/commons-lang3-3.3.2.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/osgi-resource-locator-1.0.1.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/kryo-shaded-3.0.3.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/metrics-graphite-3.1.2.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/spark-sql_2.11-2.1.0.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/commons-io-2.4.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/jackson-core-2.6.5.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/commons-math3-3.4.1.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/javax.servlet-api-3.1.0.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/jersey-server-2.22.2.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/scala-library-2.11.8.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/commons-codec-1.4.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/commons-collections-3.2.2.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/avro-1.7.6-cdh5.11.0.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/metrics-json-3.1.2.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/datanucleus-core-3.2.2.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/spark-sketch_2.11-2.1.0.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/calcite-linq4j-1.2.0-incubating.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/javax.ws.rs-api-2.0.1.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/commons-compress-1.4.1.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/minlog-1.3.0.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/javassist-3.18.1-GA.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/jackson-module-scala_2.11-2.6.5.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/spark-catalyst_2.11-2.1.0.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/kryo-2.21.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/spark-network-shuffle_2.11-2.1.0.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/avro-ipc-1.7.6-cdh5.11.0.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/libfb303-0.9.2.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/commons-compiler-3.0.0.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/stream-2.7.0.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/parquet-jackson-1.8.1.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/paranamer-2.3.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/jersey-guava-2.22.2.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/json4s-ast_2.11-3.2.11.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/parquet-hadoop-1.8.1.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/scalap-2.11.0.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/reflectasm-1.07-shaded.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/scalatest_2.11-2.2.6.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/ivy-2.0.0-rc2.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/spark-tags_2.11-2.1.0.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/validation-api-1.1.0.Final.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/xbean-asm5-shaded-4.4.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/netty-all-4.0.42.Final.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/breeze_2.11-0.12.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/unused-1.0.0.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/hk2-locator-2.4.0-b34.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/spark-launcher_2.11-2.1.0.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/hk2-api-2.4.0-b34.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/calcite-avatica-1.2.0-incubating.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/spark-mllib-local_2.11-2.1.0.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/guava-14.0.1.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/chill_2.11-0.8.0.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/breeze-macros_2.11-0.12.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/asm-4.0.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/json4s-jackson_2.11-3.2.11.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/hk2-utils-2.4.0-b34.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/calcite-core-1.2.0-incubating.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/metrics-jvm-3.1.2.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/aopalliance-repackaged-2.4.0-b34.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/jcl-over-slf4j-1.7.5.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/RoaringBitmap-0.5.11.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/univocity-parsers-2.2.1.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/spark-core_2.11-2.1.0.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/arpack_combined_all-0.1.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/jackson-mapper-asl-1.8.8.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/oozie-sharelib-spark-4.1.0-cdh5.11.0.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/antlr4-runtime-4.5.3.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/jersey-common-2.22.2.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/commons-httpclient-3.1.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/json4s-core_2.11-3.2.11.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/javax.annotation-api-1.2.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/scala-compiler-2.11.8.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/spire-macros_2.11-0.7.4.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/oozie/json-simple-1.1.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/scala-parser-combinators_2.11-1.0.4.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/zookeeper-3.4.5-cdh5.11.0.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/commons-dbcp-1.4.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/objenesis-1.2.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/spark-repl_2.11-2.1.0.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/parquet-common-1.8.1.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/libthrift-0.9.3.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/commons-lang-2.4.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/jackson-core-asl-1.8.8.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/compress-lzf-1.0.3.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/spark-mllib_2.11-2.1.0.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/janino-3.0.0.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/spark-unsafe_2.11-2.1.0.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/jersey-container-servlet-2.22.2.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/spark-hive_2.11-2.1.0.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/eigenbase-properties-1.1.5.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/parquet-hadoop-bundle-1.6.0.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/opencsv-2.3.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/avro-mapred-1.7.6-cdh5.11.0-hadoop2.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/joda-time-2.1.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/slf4j-api-1.7.5.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/minlog-1.2.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/commons-logging-1.1.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/py4j-0.10.4.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/pmml-schema-1.2.15.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/avro-ipc-1.7.6-cdh5.11.0-tests.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/chill-java-0.8.0.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/lz4-1.3.0.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/oozie/oozie-sharelib-oozie-4.1.0-cdh5.11.0.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/core-1.1.2.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/jackson-module-paranamer-2.6.5.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/oozie/oozie-hadoop-utils-2.6.0-cdh5.11.0.oozie-4.1.0-cdh5.11.0.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/netty-3.8.0.Final.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/curator-client-2.7.1.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/log4j-1.2.17.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/jets3t-0.6.1.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/jersey-container-servlet-core-2.22.2.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/scala-reflect-2.11.8.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/scala-xml_2.11-1.0.4.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/jul-to-slf4j-1.7.5.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/leveldbjni-all-1.8.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/jline-2.11.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/spark-streaming_2.11-2.1.0.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/curator-framework-2.7.1.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/oro-2.0.8.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/parquet-column-1.8.1.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/pyrolite-4.13.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/curator-recipes-2.7.1.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/jodd-core-3.5.2.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/metrics-core-3.1.2.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/shapeless_2.11-2.0.0.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/jsr305-1.3.9.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/slf4j-log4j12-1.7.5.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/jtransforms-2.4.0.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/spark-network-common_2.11-2.1.0.jar,hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/jersey-client-2.22.2.jar
                        --conf
                        spark.yarn.jars=hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/spark-yarn_2.11-2.1.0.jar
                        --verbose
                        /usr/local/envtch/ooziejobs/envtest.jar

    =================================================================

    >>> Invoking Spark class now >>>

    2017-06-14 14:07:35,094 [uber-SubtaskRunner] WARN  org.apache.spark.deploy.yarn.security.ConfigurableCredentialManager  - spark.yarn.security.tokens.hbase.enabled is deprecated, using spark.yarn.security.credentials.hbase.enabled instead
    2017-06-14 14:07:35,096 [uber-SubtaskRunner] WARN  org.apache.spark.deploy.yarn.security.ConfigurableCredentialManager  - spark.yarn.security.tokens.hive.enabled is deprecated, using spark.yarn.security.credentials.hive.enabled instead
    2017-06-14 14:07:35,123 [uber-SubtaskRunner] INFO  org.apache.hadoop.yarn.client.RMProxy  - Connecting to ResourceManager at master66/10.17.139.66:18040
    2017-06-14 14:07:35,288 [uber-SubtaskRunner] INFO  org.apache.spark.deploy.yarn.Client  - Requesting a new application from cluster with 1 NodeManagers
    2017-06-14 14:07:35,305 [uber-SubtaskRunner] INFO  org.apache.spark.deploy.yarn.Client  - Verifying our application has not requested more than the maximum memory capability of the cluster (8192 MB per container)
    2017-06-14 14:07:35,306 [uber-SubtaskRunner] INFO  org.apache.spark.deploy.yarn.Client  - Will allocate AM container, with 896 MB memory including 384 MB overhead
    2017-06-14 14:07:35,306 [uber-SubtaskRunner] INFO  org.apache.spark.deploy.yarn.Client  - Setting up container launch context for our AM
    2017-06-14 14:07:35,307 [uber-SubtaskRunner] INFO  org.apache.spark.deploy.yarn.Client  - Setting up the launch environment for our AM container
    2017-06-14 14:07:35,329 [uber-SubtaskRunner] INFO  org.apache.spark.deploy.yarn.Client  - Preparing resources for our AM container
    2017-06-14 14:07:35,403 [uber-SubtaskRunner] INFO  org.apache.spark.deploy.yarn.Client  - Source and destination file systems are the same. Not copying hdfs://master66:8020/user/root/share/lib/lib_20170613161821/spark/spark-yarn_2.11-2.1.0.jar
    2017-06-14 14:07:35,448 [uber-SubtaskRunner] INFO  org.apache.spark.deploy.yarn.Client  - Uploading resource file:/usr/local/envtch/ooziejobs/envtest.jar -> hdfs://master66:8020/user/root/.sparkStaging/application_1497340444423_0429/envtest.jar
    2017-06-14 14:07:36,767 [uber-SubtaskRunner] INFO  org.apache.spark.deploy.yarn.Client  - Uploading resource file:/mnt/disk1/data/LOCALCLUSTER/SERVICE-HADOOP-79dbed26cf7f49729e42a75f0f84c3e7/nm/local/usercache/root/appcache/application_1497340444423_0428/spark-21c9a435-52a5-4b1e-a6cd-ffacdd70b412/__spark_conf__569672878293781495.zip -> hdfs://master66:8020/user/root/.sparkStaging/application_1497340444423_0429/__spark_conf__.zip
    2017-06-14 14:07:36,862 [uber-SubtaskRunner] INFO  org.apache.spark.SecurityManager  - Changing view acls to: root
    2017-06-14 14:07:36,862 [uber-SubtaskRunner] INFO  org.apache.spark.SecurityManager  - Changing modify acls to: root
    2017-06-14 14:07:36,863 [uber-SubtaskRunner] INFO  org.apache.spark.SecurityManager  - Changing view acls groups to: 
    2017-06-14 14:07:36,864 [uber-SubtaskRunner] INFO  org.apache.spark.SecurityManager  - Changing modify acls groups to: 
    2017-06-14 14:07:36,864 [uber-SubtaskRunner] INFO  org.apache.spark.SecurityManager  - SecurityManager: authentication disabled; ui acls disabled; users  with view permissions: Set(root); groups with view permissions: Set(); users  with modify permissions: Set(root); groups with modify permissions: Set()
    2017-06-14 14:07:36,886 [uber-SubtaskRunner] INFO  org.apache.spark.deploy.yarn.Client  - Submitting application application_1497340444423_0429 to ResourceManager
    2017-06-14 14:07:36,929 [uber-SubtaskRunner] INFO  org.apache.hadoop.yarn.client.api.impl.YarnClientImpl  - Submitted application application_1497340444423_0429
    2017-06-14 14:07:37,743 [1181406396@qtp-2108523906-0] WARN  com.google.inject.servlet.InternalServletModule  - You are attempting to use a deprecated API (specifically, attempting to @Inject ServletContext inside an eagerly created singleton. While we allow this for backwards compatibility, be warned that this MAY have unexpected behavior if you have more than one injector (with ServletModule) running in the same JVM. Please consult the Guice documentation at http://code.google.com/p/google-guice/wiki/Servlets for more information.
    2017-06-14 14:07:37,933 [uber-SubtaskRunner] INFO  org.apache.spark.deploy.yarn.Client  - Application report for application_1497340444423_0429 (state: ACCEPTED)
    2017-06-14 14:07:37,942 [uber-SubtaskRunner] INFO  org.apache.spark.deploy.yarn.Client  - 
         client token: N/A
         diagnostics: N/A
         ApplicationMaster host: N/A
         ApplicationMaster RPC port: -1
         queue: root.root
         start time: 1497420456907
         final status: UNDEFINED
         tracking URL: http://master66:18088/proxy/application_1497340444423_0429/
         user: root
    2017-06-14 14:07:38,055 [1181406396@qtp-2108523906-0] INFO  com.sun.jersey.guice.spi.container.GuiceComponentProviderFactory  - Registering org.apache.hadoop.mapreduce.v2.app.webapp.JAXBContextResolver as a provider class
    2017-06-14 14:07:38,056 [1181406396@qtp-2108523906-0] INFO  com.sun.jersey.guice.spi.container.GuiceComponentProviderFactory  - Registering org.apache.hadoop.yarn.webapp.GenericExceptionHandler as a provider class
    2017-06-14 14:07:38,056 [1181406396@qtp-2108523906-0] INFO  com.sun.jersey.guice.spi.container.GuiceComponentProviderFactory  - Registering org.apache.hadoop.mapreduce.v2.app.webapp.AMWebServices as a root resource class
    2017-06-14 14:07:38,059 [1181406396@qtp-2108523906-0] INFO  com.sun.jersey.server.impl.application.WebApplicationImpl  - Initiating Jersey application, version 'Jersey: 1.9 09/02/2011 11:17 AM'
    2017-06-14 14:07:38,160 [1181406396@qtp-2108523906-0] INFO  com.sun.jersey.guice.spi.container.GuiceComponentProviderFactory  - Binding org.apache.hadoop.mapreduce.v2.app.webapp.JAXBContextResolver to GuiceManagedComponentProvider with the scope "Singleton"
    2017-06-14 14:07:38,519 [1181406396@qtp-2108523906-0] INFO  com.sun.jersey.guice.spi.container.GuiceComponentProviderFactory  - Binding org.apache.hadoop.yarn.webapp.GenericExceptionHandler to GuiceManagedComponentProvider with the scope "Singleton"
    2017-06-14 14:07:38,943 [uber-SubtaskRunner] INFO  org.apache.spark.deploy.yarn.Client  - Application report for application_1497340444423_0429 (state: ACCEPTED)
    2017-06-14 14:07:38,949 [1181406396@qtp-2108523906-0] INFO  com.sun.jersey.guice.spi.container.GuiceComponentProviderFactory  - Binding org.apache.hadoop.mapreduce.v2.app.webapp.AMWebServices to GuiceManagedComponentProvider with the scope "PerRequest"
    2017-06-14 14:07:39,945 [uber-SubtaskRunner] INFO  org.apache.spark.deploy.yarn.Client  - Application report for application_1497340444423_0429 (state: ACCEPTED)
    2017-06-14 14:07:40,171 [communication thread] INFO  org.apache.hadoop.mapred.TaskAttemptListenerImpl  - Progress of TaskAttempt attempt_1497340444423_0428_m_000000_0 is : 1.0
    2017-06-14 14:07:40,947 [uber-SubtaskRunner] INFO  org.apache.spark.deploy.yarn.Client  - Application report for application_1497340444423_0429 (state: ACCEPTED)
    2017-06-14 14:07:41,948 [uber-SubtaskRunner] INFO  org.apache.spark.deploy.yarn.Client  - Application report for application_1497340444423_0429 (state: ACCEPTED)
    2017-06-14 14:07:42,951 [uber-SubtaskRunner] INFO  org.apache.spark.deploy.yarn.Client  - Application report for application_1497340444423_0429 (state: FAILED)
    2017-06-14 14:07:42,952 [uber-SubtaskRunner] INFO  org.apache.spark.deploy.yarn.Client  - 
         client token: N/A
         diagnostics: Application application_1497340444423_0429 failed 2 times due to AM Container for appattempt_1497340444423_0429_000002 exited with  exitCode: 1
    For more detailed output, check application tracking page:http://master66:18088/proxy/application_1497340444423_0429/Then, click on links to logs of each attempt.
    Diagnostics: Exception from container-launch.
    Container id: container_1497340444423_0429_02_000001
    Exit code: 1
    Stack trace: ExitCodeException exitCode=1: 
        at org.apache.hadoop.util.Shell.runCommand(Shell.java:561)
        at org.apache.hadoop.util.Shell.run(Shell.java:478)
        at org.apache.hadoop.util.Shell$ShellCommandExecutor.execute(Shell.java:738)
        at org.apache.hadoop.yarn.server.nodemanager.DefaultContainerExecutor.launchContainer(DefaultContainerExecutor.java:211)
        at org.apache.hadoop.yarn.server.nodemanager.containermanager.launcher.ContainerLaunch.call(ContainerLaunch.java:302)
        at org.apache.hadoop.yarn.server.nodemanager.containermanager.launcher.ContainerLaunch.call(ContainerLaunch.java:82)
        at java.util.concurrent.FutureTask.run(FutureTask.java:262)
        at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1145)
        at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:615)
        at java.lang.Thread.run(Thread.java:745)


    Container exited with a non-zero exit code 1
    Failing this attempt. Failing the application.
         ApplicationMaster host: N/A
         ApplicationMaster RPC port: -1
         queue: root.root
         start time: 1497420456907
         final status: FAILED
         tracking URL: http://master66:18088/cluster/app/application_1497340444423_0429
         user: root
    2017-06-14 14:07:42,971 [uber-SubtaskRunner] INFO  org.apache.spark.deploy.yarn.Client  - Deleted staging directory hdfs://master66:8020/user/root/.sparkStaging/application_1497340444423_0429

    <<< Invocation of Spark command completed <<<

    Hadoop Job IDs executed by Spark: job_1497340444423_0429


    <<< Invocation of Main class completed <<<

    Failing Oozie Launcher, Main class [org.apache.oozie.action.hadoop.SparkMain], main() threw exception, Application application_1497340444423_0429 finished with failed status
    org.apache.spark.SparkException: Application application_1497340444423_0429 finished with failed status
        at org.apache.spark.deploy.yarn.Client.run(Client.scala:1167)
        at org.apache.spark.deploy.yarn.Client$.main(Client.scala:1213)
        at org.apache.spark.deploy.yarn.Client.main(Client.scala)
        at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
        at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:57)
        at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
        at java.lang.reflect.Method.invoke(Method.java:606)
        at org.apache.spark.deploy.SparkSubmit$.org$apache$spark$deploy$SparkSubmit$$runMain(SparkSubmit.scala:738)
        at org.apache.spark.deploy.SparkSubmit$.doRunMain$1(SparkSubmit.scala:187)
        at org.apache.spark.deploy.SparkSubmit$.submit(SparkSubmit.scala:212)
        at org.apache.spark.deploy.SparkSubmit$.main(SparkSubmit.scala:126)
        at org.apache.spark.deploy.SparkSubmit.main(SparkSubmit.scala)
        at org.apache.oozie.action.hadoop.SparkMain.runSpark(SparkMain.java:372)
        at org.apache.oozie.action.hadoop.SparkMain.run(SparkMain.java:282)
        at org.apache.oozie.action.hadoop.LauncherMain.run(LauncherMain.java:64)
        at org.apache.oozie.action.hadoop.SparkMain.main(SparkMain.java:82)
        at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
        at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:57)
        at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
        at java.lang.reflect.Method.invoke(Method.java:606)
        at org.apache.oozie.action.hadoop.LauncherMapper.map(LauncherMapper.java:234)
        at org.apache.hadoop.mapred.MapRunner.run(MapRunner.java:54)
        at org.apache.hadoop.mapred.MapTask.runOldMapper(MapTask.java:453)
        at org.apache.hadoop.mapred.MapTask.run(MapTask.java:343)
        at org.apache.hadoop.mapred.LocalContainerLauncher$EventHandler.runSubtask(LocalContainerLauncher.java:388)
        at org.apache.hadoop.mapred.LocalContainerLauncher$EventHandler.runTask(LocalContainerLauncher.java:302)
        at org.apache.hadoop.mapred.LocalContainerLauncher$EventHandler.access$200(LocalContainerLauncher.java:187)
        at org.apache.hadoop.mapred.LocalContainerLauncher$EventHandler$1.run(LocalContainerLauncher.java:230)
        at java.util.concurrent.Executors$RunnableAdapter.call(Executors.java:471)
        at java.util.concurrent.FutureTask.run(FutureTask.java:262)
        at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1145)
        at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:615)
        at java.lang.Thread.run(Thread.java:745)

    Oozie Launcher failed, finishing Hadoop job gracefully

    Oozie Launcher, uploading action data to HDFS sequence file: hdfs://master66:8020/user/root/oozie-root/0000202-170613162811875-oozie-root-W/firstdemo--spark/action-data.seq
    2017-06-14 14:07:43,017 [uber-SubtaskRunner] INFO  org.apache.hadoop.io.compress.CodecPool  - Got brand-new compressor [.deflate]
    Successfully reset security manager from org.apache.oozie.action.hadoop.LauncherSecurityManager@679311a5 to null

    Oozie Launcher ends

    2017-06-14 14:07:43,046 [uber-SubtaskRunner] INFO  org.apache.hadoop.mapred.TaskAttemptListenerImpl  - Progress of TaskAttempt attempt_1497340444423_0428_m_000000_0 is : 1.0
    2017-06-14 14:07:43,092 [uber-SubtaskRunner] INFO  org.apache.hadoop.mapred.Task  - Task:attempt_1497340444423_0428_m_000000_0 is done. And is in the process of committing
    2017-06-14 14:07:43,173 [uber-SubtaskRunner] INFO  org.apache.hadoop.mapred.TaskAttemptListenerImpl  - Commit-pending state update from attempt_1497340444423_0428_m_000000_0
    2017-06-14 14:07:43,173 [uber-SubtaskRunner] INFO  org.apache.hadoop.mapred.TaskAttemptListenerImpl  - Commit go/no-go request from attempt_1497340444423_0428_m_000000_0
    2017-06-14 14:07:43,174 [AsyncDispatcher event handler] INFO  org.apache.hadoop.mapreduce.v2.app.job.impl.TaskAttemptImpl  - attempt_1497340444423_0428_m_000000_0 TaskAttempt Transitioned from RUNNING to COMMIT_PENDING
    2017-06-14 14:07:43,175 [AsyncDispatcher event handler] INFO  org.apache.hadoop.mapreduce.v2.app.job.impl.TaskImpl  - attempt_1497340444423_0428_m_000000_0 given a go for committing the task output.
    2017-06-14 14:07:44,174 [uber-SubtaskRunner] INFO  org.apache.hadoop.mapred.TaskAttemptListenerImpl  - Commit go/no-go request from attempt_1497340444423_0428_m_000000_0
    2017-06-14 14:07:44,175 [uber-SubtaskRunner] INFO  org.apache.hadoop.mapreduce.v2.app.job.impl.TaskImpl  - Result of canCommit for attempt_1497340444423_0428_m_000000_0:true
    2017-06-14 14:07:44,175 [uber-SubtaskRunner] INFO  org.apache.hadoop.mapred.Task  - Task attempt_1497340444423_0428_m_000000_0 is allowed to commit now
    2017-06-14 14:07:44,200 [uber-SubtaskRunner] INFO  org.apache.hadoop.mapreduce.lib.output.FileOutputCommitter  - Saved output of task 'attempt_1497340444423_0428_m_000000_0' to hdfs://master66:8020/user/root/oozie-root/0000202-170613162811875-oozie-root-W/firstdemo--spark/output/_temporary/1/task_1497340444423_0428_m_000000
    2017-06-14 14:07:44,260 [uber-SubtaskRunner] INFO  org.apache.hadoop.mapred.TaskAttemptListenerImpl  - Progress of TaskAttempt attempt_1497340444423_0428_m_000000_0 is : 1.0
    2017-06-14 14:07:44,260 [uber-SubtaskRunner] INFO  org.apache.hadoop.mapred.TaskAttemptListenerImpl  - Done acknowledgement from attempt_1497340444423_0428_m_000000_0
    2017-06-14 14:07:44,261 [uber-SubtaskRunner] INFO  org.apache.hadoop.mapred.Task  - Task 'attempt_1497340444423_0428_m_000000_0' done.
    2017-06-14 14:07:44,263 [AsyncDispatcher event handler] INFO  org.apache.hadoop.mapreduce.v2.app.job.impl.TaskAttemptImpl  - attempt_1497340444423_0428_m_000000_0 TaskAttempt Transitioned from COMMIT_PENDING to SUCCESS_FINISHING_CONTAINER
    2017-06-14 14:07:44,274 [AsyncDispatcher event handler] INFO  org.apache.hadoop.mapreduce.v2.app.job.impl.TaskImpl  - Task succeeded with attempt attempt_1497340444423_0428_m_000000_0
    2017-06-14 14:07:44,275 [AsyncDispatcher event handler] INFO  org.apache.hadoop.mapreduce.v2.app.job.impl.TaskImpl  - task_1497340444423_0428_m_000000 Task Transitioned from RUNNING to SUCCEEDED
    2017-06-14 14:07:44,276 [AsyncDispatcher event handler] INFO  org.apache.hadoop.mapreduce.v2.app.job.impl.JobImpl  - Num completed Tasks: 1
    2017-06-14 14:07:44,277 [AsyncDispatcher event handler] INFO  org.apache.hadoop.mapreduce.v2.app.job.impl.JobImpl  - job_1497340444423_0428Job Transitioned from RUNNING to COMMITTING
    2017-06-14 14:07:44,277 [CommitterEvent Processor #1] INFO  org.apache.hadoop.mapreduce.v2.app.commit.CommitterEventHandler  - Processing the event EventType: JOB_COMMIT
    2017-06-14 14:07:44,287 [uber-SubtaskRunner] INFO  org.apache.hadoop.mapred.LocalContainerLauncher  - removed attempt attempt_1497340444423_0428_m_000000_0 from the futures to keep track of
    2017-06-14 14:07:44,287 [AsyncDispatcher event handler] INFO  org.apache.hadoop.mapreduce.v2.app.job.impl.TaskAttemptImpl  - attempt_1497340444423_0428_m_000000_0 TaskAttempt Transitioned from SUCCESS_FINISHING_CONTAINER to SUCCEEDED
    2017-06-14 14:07:44,287 [uber-EventHandler] INFO  org.apache.hadoop.mapred.LocalContainerLauncher  - Processing the event EventType: CONTAINER_COMPLETED for container container_1497340444423_0428_01_000001 taskAttempt attempt_1497340444423_0428_m_000000_0
    2017-06-14 14:07:44,378 [AsyncDispatcher event handler] INFO  org.apache.hadoop.mapreduce.v2.app.job.impl.JobImpl  - Calling handler for JobFinishedEvent 
    2017-06-14 14:07:44,379 [AsyncDispatcher event handler] INFO  org.apache.hadoop.mapreduce.v2.app.job.impl.JobImpl  - job_1497340444423_0428Job Transitioned from COMMITTING to SUCCEEDED
    2017-06-14 14:07:44,380 [Thread-86] INFO  org.apache.hadoop.mapreduce.v2.app.MRAppMaster  - We are finishing cleanly so this is the last retry
    2017-06-14 14:07:44,381 [Thread-86] INFO  org.apache.hadoop.mapreduce.v2.app.MRAppMaster  - Notify RMCommunicator isAMLastRetry: true
    2017-06-14 14:07:44,381 [Thread-86] INFO  org.apache.hadoop.mapreduce.v2.app.rm.RMContainerAllocator  - RMCommunicator notified that shouldUnregistered is: true
    2017-06-14 14:07:44,381 [Thread-86] INFO  org.apache.hadoop.mapreduce.v2.app.MRAppMaster  - Notify JHEH isAMLastRetry: true
    2017-06-14 14:07:44,381 [Thread-86] INFO  org.apache.hadoop.mapreduce.jobhistory.JobHistoryEventHandler  - JobHistoryEventHandler notified that forceJobCompletion is true
    2017-06-14 14:07:44,381 [Thread-86] INFO  org.apache.hadoop.mapreduce.v2.app.MRAppMaster  - Calling stop for all the services
    2017-06-14 14:07:44,382 [Thread-86] INFO  org.apache.hadoop.mapreduce.jobhistory.JobHistoryEventHandler  - Stopping JobHistoryEventHandler. Size of the outstanding queue size is 0
    2017-06-14 14:07:44,442 [eventHandlingThread] INFO  org.apache.hadoop.mapreduce.jobhistory.JobHistoryEventHandler  - Copying hdfs://master66:8020/user/root/.staging/job_1497340444423_0428/job_1497340444423_0428_1.jhist to hdfs://master66:8020/user/history/done_intermediate/root/job_1497340444423_0428-1497420448305-root-oozie%3Alauncher%3AT%3Dspark%3AW%3Dfirstdemo%2Dwf%3AA%3Dfirstdemo%3A-1497420464376-1-0-SUCCEEDED-root.root-1497420453321.jhist_tmp
    2017-06-14 14:07:44,480 [eventHandlingThread] INFO  org.apache.hadoop.mapreduce.jobhistory.JobHistoryEventHandler  - Copied to done location: hdfs://master66:8020/user/history/done_intermediate/root/job_1497340444423_0428-1497420448305-root-oozie%3Alauncher%3AT%3Dspark%3AW%3Dfirstdemo%2Dwf%3AA%3Dfirstdemo%3A-1497420464376-1-0-SUCCEEDED-root.root-1497420453321.jhist_tmp
    2017-06-14 14:07:44,488 [eventHandlingThread] INFO  org.apache.hadoop.mapreduce.jobhistory.JobHistoryEventHandler  - Copying hdfs://master66:8020/user/root/.staging/job_1497340444423_0428/job_1497340444423_0428_1_conf.xml to hdfs://master66:8020/user/history/done_intermediate/root/job_1497340444423_0428_conf.xml_tmp
    2017-06-14 14:07:44,521 [eventHandlingThread] INFO  org.apache.hadoop.mapreduce.jobhistory.JobHistoryEventHandler  - Copied to done location: hdfs://master66:8020/user/history/done_intermediate/root/job_1497340444423_0428_conf.xml_tmp
    2017-06-14 14:07:44,538 [eventHandlingThread] INFO  org.apache.hadoop.mapreduce.jobhistory.JobHistoryEventHandler  - Moved tmp to done: hdfs://master66:8020/user/history/done_intermediate/root/job_1497340444423_0428.summary_tmp to hdfs://master66:8020/user/history/done_intermediate/root/job_1497340444423_0428.summary
    2017-06-14 14:07:44,546 [eventHandlingThread] INFO  org.apache.hadoop.mapreduce.jobhistory.JobHistoryEventHandler  - Moved tmp to done: hdfs://master66:8020/user/history/done_intermediate/root/job_1497340444423_0428_conf.xml_tmp to hdfs://master66:8020/user/history/done_intermediate/root/job_1497340444423_0428_conf.xml
    2017-06-14 14:07:44,554 [eventHandlingThread] INFO  org.apache.hadoop.mapreduce.jobhistory.JobHistoryEventHandler  - Moved tmp to done: hdfs://master66:8020/user/history/done_intermediate/root/job_1497340444423_0428-1497420448305-root-oozie%3Alauncher%3AT%3Dspark%3AW%3Dfirstdemo%2Dwf%3AA%3Dfirstdemo%3A-1497420464376-1-0-SUCCEEDED-root.root-1497420453321.jhist_tmp to hdfs://master66:8020/user/history/done_intermediate/root/job_1497340444423_0428-1497420448305-root-oozie%3Alauncher%3AT%3Dspark%3AW%3Dfirstdemo%2Dwf%3AA%3Dfirstdemo%3A-1497420464376-1-0-SUCCEEDED-root.root-1497420453321.jhist
    2017-06-14 14:07:44,555 [Thread-86] INFO  org.apache.hadoop.mapreduce.jobhistory.JobHistoryEventHandler  - Stopped JobHistoryEventHandler. super.stop()
    2017-06-14 14:07:44,555 [uber-EventHandler] ERROR org.apache.hadoop.mapred.LocalContainerLauncher  - Returning, interrupted : java.lang.InterruptedException
    2017-06-14 14:07:44,556 [Thread-86] INFO  org.apache.hadoop.mapreduce.v2.app.rm.RMContainerAllocator  - Setting job diagnostics to 
    2017-06-14 14:07:44,556 [Thread-86] INFO  org.apache.hadoop.mapreduce.v2.app.rm.RMContainerAllocator  - History url is http://master66:19888/jobhistory/job/job_1497340444423_0428
    2017-06-14 14:07:44,565 [Thread-86] INFO  org.apache.hadoop.mapreduce.v2.app.rm.RMContainerAllocator  - Waiting for application to be successfully unregistered.
    2017-06-14 14:07:45,567 [Thread-86] INFO  org.apache.hadoop.mapreduce.v2.app.MRAppMaster  - Deleting staging directory hdfs://master66:8020 /user/root/.staging/job_1497340444423_0428
    2017-06-14 14:07:45,583 [Thread-86] INFO  org.apache.hadoop.ipc.Server  - Stopping server on 35713
    2017-06-14 14:07:45,584 [IPC Server listener on 35713] INFO  org.apache.hadoop.ipc.Server  - Stopping IPC Server listener on 35713
    2017-06-14 14:07:45,584 [IPC Server Responder] INFO  org.apache.hadoop.ipc.Server  - Stopping IPC Server Responder
    2017-06-14 14:07:45,584 [TaskHeartbeatHandler PingChecker] INFO  org.apache.hadoop.mapreduce.v2.app.TaskHeartbeatHandler  - TaskHeartbeatHandler thread interrupted
    2017-06-14 14:07:45,584 [Ping Checker] INFO  org.apache.hadoop.yarn.util.AbstractLivelinessMonitor  - TaskAttemptFinishingMonitor thread interrupted
    ```
解决方法：

5. jar
    ``` console
    yarn logs -applicationId application_1497340444423_0439

    17/06/14 15:10:03 INFO ApplicationMaster: Registered signal handlers for [TERM, HUP, INT]
    Exception in thread "main" java.lang.NoSuchMethodError: scala.collection.immutable.$colon$colon.hd$1()Ljava/lang/Object;
        at org.apache.spark.deploy.yarn.ApplicationMasterArguments.parseArgs(ApplicationMasterArguments.scala:45)
        at org.apache.spark.deploy.yarn.ApplicationMasterArguments.<init>(ApplicationMasterArguments.scala:34)
        at org.apache.spark.deploy.yarn.ApplicationMaster$.main(ApplicationMaster.scala:572)
        at org.apache.spark.deploy.yarn.ApplicationMaster.main(ApplicationMaster.scala)
    ```
解决办法：
6. jar
    ``` console
    yarn logs -applicationId application_1497340444423_0484

    2017-06-14 15:51:40,019 ERROR [main] org.apache.hadoop.mapreduce.v2.app.MRAppMaster: Error starting MRAppMaster
    java.lang.NoSuchMethodError: org.apache.hadoop.yarn.webapp.util.WebAppUtils.getProxyHostsAndPortsForAmFilter(Lorg/apache/hadoop/conf/Configuration;)Ljava/util/List;
        at org.apache.hadoop.yarn.server.webproxy.amfilter.AmFilterInitializer.initFilter(AmFilterInitializer.java:40)
        at org.apache.hadoop.http.HttpServer.<init>(HttpServer.java:272)
        at org.apache.hadoop.yarn.webapp.WebApps$Builder$2.<init>(WebApps.java:222)
        at org.apache.hadoop.yarn.webapp.WebApps$Builder.start(WebApps.java:219)
        at org.apache.hadoop.mapreduce.v2.app.client.MRClientService.serviceStart(MRClientService.java:136)
        at org.apache.hadoop.service.AbstractService.start(AbstractService.java:193)
        at org.apache.hadoop.mapreduce.v2.app.MRAppMaster.serviceStart(MRAppMaster.java:1058)
        at org.apache.hadoop.service.AbstractService.start(AbstractService.java:193)
        at org.apache.hadoop.mapreduce.v2.app.MRAppMaster$1.run(MRAppMaster.java:1445)
        at java.security.AccessController.doPrivileged(Native Method)
        at javax.security.auth.Subject.doAs(Subject.java:415)
        at org.apache.hadoop.security.UserGroupInformation.doAs(UserGroupInformation.java:1491)
        at org.apache.hadoop.mapreduce.v2.app.MRAppMaster.initAndStartAppMaster(MRAppMaster.java:1441)
        at org.apache.hadoop.mapreduce.v2.app.MRAppMaster.main(MRAppMaster.java:1374)
    2017-06-14 15:51:40,023 INFO [Thread-1] org.apache.hadoop.mapreduce.v2.app.MRAppMaster: MRAppMaster received a signal. Signaling RMCommunicator and JobHistoryEventHandler.
    2017-06-14 15:51:40,024 WARN [Thread-1] org.apache.hadoop.util.ShutdownHookManager: ShutdownHook 'MRAppMasterShutdownHook' failed, java.lang.NullPointerException
    java.lang.NullPointerException
        at org.apache.hadoop.mapreduce.v2.app.MRAppMaster$ContainerAllocatorRouter.setSignalled(MRAppMaster.java:827)
        at org.apache.hadoop.mapreduce.v2.app.MRAppMaster$MRAppMasterShutdownHook.run(MRAppMaster.java:1395)
        at org.apache.hadoop.util.ShutdownHookManager$1.run(ShutdownHookManager.java:54)    
    ```
解决办法：
    1. master为yarn-client：${nameNode}/dev/oozieJob/cron 下的 lib 文件夹里不放 lib/uber.jar
    2. master为yarn-cluster：

7. JA009: Cannot initialize Cluster. Please check your configuration for mapreduce.framework.name and the correspond server addresses.
解决办法：缺少Jar包：Hadoop-mapreduce-client-common-2.2.0.jar

8. File /user/root/share/lib does not exist
解决方法：
``` shell
    <property>
        <name>oozie.action.mapreduce.uber.jar.enable</name>
        <value>true</value>
    </property>
    <property>
        <name>oozie.use.system.libpath</name>
        <value>true</value>
    </property>
```

9. 处理extjs问题
解决方法：下载ext-2.2.zip 放到：

10. $oozie validate ./workflow.xml 
- Error: Invalid app definition, org.xml.sax.SAXParseException; lineNumber: 2; columnNumber: 23; cvc-pattern-valid: Value '97_a' is not facet-valid with respect to pattern '([a-zA-Z_]([\-_a-zA-Z0-9])*){1,39}' for type 'IDENTIFIER'.
解决方法：必须以字母或者下划线开头

11. JA006: Call From master66/10.17.139.66 to master66:10020 failed on connection exception: java.net.ConnectException: Connection refused; For more details see:  http://wiki.apache.org/hadoop/ConnectionRefused
描述：oozie提交任务已运行成功，从spark job history页面可以获取成功信息；但oozie页面出现上面错误信息，并且任务在挂起状态
解释：当你提交作业时，我们可以打开Yarn的web界面18088，当作业运行完之后，会显示History的状态，表示改作业已经运行完毕，如果想查看作业历史运行信息就可以点击History查看。若未启动historyserver的话，是无法查看作业job的历史记录的。
解决方法：mr-jobhistory-daemon.sh start historyserver

12. JA017: Could not lookup launched hadoop Job ID [job_1498183093431_0069] which was associated with  action [0000007-170626092106720-oozie-root-W@one].  Failing this action!
解决方法：
``` xml oozie-site.xml
    <!--将原来的-->
    <property>
        <name>oozie.service.HadoopAccessorService.hadoop.configurations</name>
        <value>*=${OOZIE_CONF_HOME}/conf/hadoop/</value>
    </property>
    <!--修改为-->
    <property>
        <name>oozie.service.HadoopAccessorService.hadoop.configurations</name>
        <value>*=${HADOOP_CONF_HOME}</value>
    </property>
    <!--并添加如下-->
    <property>
        <name>oozie.service.HadoopAccessorService.action.configurations</name>
        <value>*=${HADOOP_CONF_HOME}</value>
    </property>
```
13. Failing Oozie Launcher, Main class [org.apache.oozie.action.hadoop.SparkMain], main() threw exception, org.apache.spark.sql.DataFrameReader.load()Lorg/apache/spark/sql/Dataset;
java.lang.NoSuchMethodError: org.apache.spark.sql.DataFrameReader.load()Lorg/apache/spark/sql/Dataset;
  at com.chaos.OracleLoad$.loadTable(OracleLoad.scala:85)
解决方法：安装sharelib

14. 耗费时间最长的问题
``` xml
Failing Oozie Launcher, Main class [org.apache.oozie.action.hadoop.SparkMain], main() threw exception, PermGen space
java.lang.OutOfMemoryError: PermGen space
  at java.lang.ClassLoader.defineClass1(Native Method)
  at java.lang.ClassLoader.defineClass(ClassLoader.java:800)
  at java.security.SecureClassLoader.defineClass(SecureClassLoader.java:142)
  at java.net.URLClassLoader.defineClass(URLClassLoader.java:449)
  at java.net.URLClassLoader.access$100(URLClassLoader.java:71)
  at java.net.URLClassLoader$1.run(URLClassLoader.java:361)
  at java.net.URLClassLoader$1.run(URLClassLoader.java:355)
  at java.security.AccessController.doPrivileged(Native Method)
  at java.net.URLClassLoader.findClass(URLClassLoader.java:354)
  at java.lang.ClassLoader.loadClass(ClassLoader.java:425)
  at java.lang.ClassLoader.loadClass(ClassLoader.java:358)
  at oracle.jdbc.driver.T4CDriverExtension.allocatePreparedStatement(T4CDriverExtension.java:69)
  at oracle.jdbc.driver.PhysicalConnection.prepareStatementInternal(PhysicalConnection.java:2013)
  at oracle.jdbc.driver.PhysicalConnection.prepareStatement(PhysicalConnection.java:1960)
  at oracle.jdbc.driver.PhysicalConnection.prepareStatement(PhysicalConnection.java:1866)
  at org.apache.spark.sql.execution.datasources.jdbc.JDBCRDD$.resolveTable(JDBCRDD.scala:60)
  at org.apache.spark.sql.execution.datasources.jdbc.JDBCRelation.<init>(JDBCRelation.scala:113)
  at org.apache.spark.sql.execution.datasources.jdbc.JdbcRelationProvider.createRelation(JdbcRelationProvider.scala:45)
  at org.apache.spark.sql.execution.datasources.DataSource.resolveRelation(DataSource.scala:330)
  at org.apache.spark.sql.DataFrameReader.load(DataFrameReader.scala:152)
  at org.apache.spark.sql.DataFrameReader.load(DataFrameReader.scala:125)
  at com.hikvision.sparta.etl.load.dataload.OracleLoad$.loadTable(OracleLoad.scala:85)
  at com.hikvision.sparta.etl.load.dataload.DataLoad$.run(DataLoad.scala:78)
  at com.hikvision.sparta.etl.load.dataload.DataLoad$.main(DataLoad.scala:17)
  at com.hikvision.sparta.etl.load.dataload.DataLoad.main(DataLoad.scala)
  at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
  at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:57)
  at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
  at java.lang.reflect.Method.invoke(Method.java:606)
  at org.apache.spark.deploy.SparkSubmit$.org$apache$spark$deploy$SparkSubmit$$runMain(SparkSubmit.scala:738)
  at org.apache.spark.deploy.SparkSubmit$.doRunMain$1(SparkSubmit.scala:187)
  at org.apache.spark.deploy.SparkSubmit$.submit(SparkSubmit.scala:212)
```
解决方法：
``` xml
<workflow-app name="simple-ONE-wf" xmlns="uri:oozie:workflow:0.1">
    <start to='ONE'/>
    <action name="ONE">
        <spark xmlns="uri:oozie:spark-action:0.1">
            <job-tracker>${jobTracker}</job-tracker>
            <name-node>${nameNode}</name-node>
            <configuration>
                <property>
                    <name>oozie.launcher.mapreduce.map.memory.mb</name>
                    <value>4096</value>
                </property>
                <property>
                    <name>oozie.launcher.mapreduce.map.java.opts</name>
                    <value>-Xmx3200m</value>
                </property>
                <property>
                    <name>oozie.launcher.mapreduce.map.java.opts</name>
                    <value>-XX:MaxPermSize=1g</value>
                </property>
                ...
            </configuration>
           ...
    </action>

    <kill name='kill'>
        <message>Something went wrong: ${wf:errorCode('firstdemo')}</message>
    </kill>
    <end name='end'/>
</workflow-app>
```
16. action 过多，导致oozie存记录信息到mysql时异常
``` console
2017-06-27 17:13:33,624  WARN CallableQueueService$CompositeCallable:523 - SERVER[SERVICE-OOZIE-e8aa07e3356c44228c02f610d58c8e53-OOZIE-0] USER[root] GROUP[-] TOKEN[] APP[demo-wf] JOB[0000021-170626164305337-oozie-root-W] ACTION[0000021-170626164305337-oozie-root-W@BS_PERSON_56_fork] exception callable [signal], E0603: SQL error in operation, <openjpa-2.2.2-r422266:1468616 fatal store error> org.apache.openjpa.persistence.RollbackException: The transaction has been rolled back.  See the nested exceptions for details on the errors that occurred.
FailedObject: org.apache.oozie.WorkflowActionBean@11cc06e
org.apache.oozie.command.CommandException: E0603: SQL error in operation, <openjpa-2.2.2-r422266:1468616 fatal store error> org.apache.openjpa.persistence.RollbackException: The transaction has been rolled back.  See the nested exceptions for details on the errors that occurred.
FailedObject: org.apache.oozie.WorkflowActionBean@11cc06e
  at org.apache.oozie.command.wf.SignalXCommand.execute(SignalXCommand.java:421)
  at org.apache.oozie.command.wf.SignalXCommand.execute(SignalXCommand.java:76)
  at org.apache.oozie.command.XCommand.call(XCommand.java:286)
  at org.apache.oozie.service.CallableQueueService$CompositeCallable.call(CallableQueueService.java:321)
  at org.apache.oozie.service.CallableQueueService$CompositeCallable.call(CallableQueueService.java:250)
  at org.apache.oozie.service.CallableQueueService$CallableWrapper.run(CallableQueueService.java:175)
  at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1145)
  at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:615)
  at java.lang.Thread.run(Thread.java:745)
Caused by: org.apache.oozie.executor.jpa.JPAExecutorException: E0603: SQL error in operation, <openjpa-2.2.2-r422266:1468616 fatal store error> org.apache.openjpa.persistence.RollbackException: The transaction has been rolled back.  See the nested exceptions for details on the errors that occurred.
FailedObject: org.apache.oozie.WorkflowActionBean@11cc06e
  at org.apache.oozie.service.JPAService.executeBatchInsertUpdateDelete(JPAService.java:425)
  at org.apache.oozie.executor.jpa.BatchQueryExecutor.executeBatchInsertUpdateDelete(BatchQueryExecutor.java:132)
  at org.apache.oozie.command.wf.SignalXCommand.execute(SignalXCommand.java:412)
  ... 8 more
Caused by: <openjpa-2.2.2-r422266:1468616 fatal store error> org.apache.openjpa.persistence.RollbackException: The transaction has been rolled back.  See the nested exceptions for details on the errors that occurred.
FailedObject: org.apache.oozie.WorkflowActionBean@11cc06e
  at org.apache.openjpa.persistence.EntityManagerImpl.commit(EntityManagerImpl.java:594)
  at org.apache.oozie.service.JPAService.executeBatchInsertUpdateDelete(JPAService.java:421)
  ... 10 more
Caused by: <openjpa-2.2.2-r422266:1468616 fatal general error> org.apache.openjpa.persistence.PersistenceException: The transaction has been rolled back.  See the nested exceptions for details on the errors that occurred.
FailedObject: org.apache.oozie.WorkflowActionBean@11cc06e
  at org.apache.openjpa.kernel.BrokerImpl.newFlushException(BrokerImpl.java:2347)
  at org.apache.openjpa.kernel.BrokerImpl.flush(BrokerImpl.java:2184)
  at org.apache.openjpa.kernel.BrokerImpl.flushSafe(BrokerImpl.java:2082)
  at org.apache.openjpa.kernel.BrokerImpl.beforeCompletion(BrokerImpl.java:2000)
  at org.apache.openjpa.kernel.LocalManagedRuntime.commit(LocalManagedRuntime.java:81)
  at org.apache.openjpa.kernel.BrokerImpl.commit(BrokerImpl.java:1524)
  at org.apache.openjpa.kernel.DelegatingBroker.commit(DelegatingBroker.java:933)
  at org.apache.openjpa.persistence.EntityManagerImpl.commit(EntityManagerImpl.java:570)
  ... 11 more
Caused by: <openjpa-2.2.2-r422266:1468616 fatal general error> org.apache.openjpa.persistence.PersistenceException: Data truncation: Data too long for column 'execution_path' at row 1 {prepstmnt 33903617 INSERT INTO WF_ACTIONS (id, conf, console_url, created_time, cred, data, end_time, error_code, error_message, execution_path, external_child_ids, external_id, external_status, last_check_time, log_token, name, pending, pending_age, retries, signal_value, sla_xml, start_time, stats, status, tracker_uri, transition, type, user_retry_count, user_retry_interval, user_retry_max, wf_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)} [code=0, state=22001]
FailedObject: org.apache.oozie.WorkflowActionBean@11cc06e
  at org.apache.openjpa.jdbc.sql.DBDictionary.narrow(DBDictionary.java:4962)
  at org.apache.openjpa.jdbc.sql.DBDictionary.newStoreException(DBDictionary.java:4922)
  at org.apache.openjpa.jdbc.sql.SQLExceptions.getStore(SQLExceptions.java:136)
  at org.apache.openjpa.jdbc.sql.SQLExceptions.getStore(SQLExceptions.java:78)
  at org.apache.openjpa.jdbc.kernel.PreparedStatementManagerImpl.flushAndUpdate(PreparedStatementManagerImpl.java:144)
  at org.apache.openjpa.jdbc.kernel.BatchingPreparedStatementManagerImpl.flushAndUpdate(BatchingPreparedStatementManagerImpl.java:79)
  at org.apache.openjpa.jdbc.kernel.PreparedStatementManagerImpl.flushInternal(PreparedStatementManagerImpl.java:100)
  at org.apache.openjpa.jdbc.kernel.PreparedStatementManagerImpl.flush(PreparedStatementManagerImpl.java:88)
  at org.apache.openjpa.jdbc.kernel.ConstraintUpdateManager.flush(ConstraintUpdateManager.java:550)
  at org.apache.openjpa.jdbc.kernel.ConstraintUpdateManager.flush(ConstraintUpdateManager.java:106)
  at org.apache.openjpa.jdbc.kernel.BatchingConstraintUpdateManager.flush(BatchingConstraintUpdateManager.java:59)
  at org.apache.openjpa.jdbc.kernel.AbstractUpdateManager.flush(AbstractUpdateManager.java:105)
  at org.apache.openjpa.jdbc.kernel.AbstractUpdateManager.flush(AbstractUpdateManager.java:78)
  at org.apache.openjpa.jdbc.kernel.JDBCStoreManager.flush(JDBCStoreManager.java:732)
  at org.apache.openjpa.kernel.DelegatingStoreManager.flush(DelegatingStoreManager.java:131)
  ... 18 more
Caused by: org.apache.openjpa.lib.jdbc.ReportingSQLException: Data truncation: Data too long for column 'execution_path' at row 1 {prepstmnt 33903617 INSERT INTO WF_ACTIONS (id, conf, console_url, created_time, cred, data, end_time, error_code, error_message, execution_path, external_child_ids, external_id, external_status, last_check_time, log_token, name, pending, pending_age, retries, signal_value, sla_xml, start_time, stats, status, tracker_uri, transition, type, user_retry_count, user_retry_interval, user_retry_max, wf_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)} [code=0, state=22001]
  at org.apache.openjpa.lib.jdbc.LoggingConnectionDecorator.wrap(LoggingConnectionDecorator.java:219)
  at org.apache.openjpa.lib.jdbc.LoggingConnectionDecorator.wrap(LoggingConnectionDecorator.java:195)
  at org.apache.openjpa.lib.jdbc.LoggingConnectionDecorator.access$1000(LoggingConnectionDecorator.java:59)
  at org.apache.openjpa.lib.jdbc.LoggingConnectionDecorator$LoggingConnection$LoggingPreparedStatement.executeUpdate(LoggingConnectionDecorator.java:1134)
  at org.apache.openjpa.lib.jdbc.DelegatingPreparedStatement.executeUpdate(DelegatingPreparedStatement.java:275)
  at org.apache.openjpa.jdbc.kernel.JDBCStoreManager$CancelPreparedStatement.executeUpdate(JDBCStoreManager.java:1792)
  at org.apache.openjpa.jdbc.kernel.PreparedStatementManagerImpl.executeUpdate(PreparedStatementManagerImpl.java:268)
  at org.apache.openjpa.jdbc.kernel.PreparedStatementManagerImpl.flushAndUpdate(PreparedStatementManagerImpl.java:119)
  ... 28 more
```
解决方法：
``` sql
ALTER TABLE `ooziedb`.`WF_ACTIONS` 
CHANGE COLUMN `execution_path` `execution_path` VARCHAR(65532) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ;
```
- VARCHAR(1024)变成MEDIUMTEXT

17. oozie yarn-cluster spark
``` console
 diagnostics: User class threw exception: org.springframework.beans.factory.BeanCreationException: Error creating bean with name 'ConfDictElemService': Injection of autowired dependencies failed; nested exception is org.springframework.beans.factory.BeanCreationException: Could not autowire field: private com.hikvision.sparta.etl.db.mappers.ConfDictElemMapper com.hikvision.sparta.etl.db.service.impl.ConfDictElemServiceImpl.confDictElemMapper; nested exception is org.springframework.beans.factory.UnsatisfiedDependencyException: Error creating bean with name 'confDictElemMapper' defined in URL [jar:file:/mnt/ssd1/data/LOCALCLUSTER/SERVICE-HADOOP-79dbed26cf7f49729e42a75f0f84c3e7/nm/local/usercache/root/filecache/339/sparta-vulcanus-load.jar!/com/hikvision/sparta/etl/db/mappers/ConfDictElemMapper.class]: Unsatisfied dependency expressed through bean property 'sqlSessionFactory': : Error creating bean with name 'sqlSessionFactory' defined in class path resource [applicationContext-etldb.xml]: Invocation of init method failed; nested exception is org.springframework.core.NestedIOException: Failed to parse mapping resource: 'URL [jar:file:/mnt/disk1/data/LOCALCLUSTER/SERVICE-HADOOP-79dbed26cf7f49729e42a75f0f84c3e7/nm/local/usercache/root/appcache/application_1498183093431_1151/container_1498183093431_1151_02_000001/__app__.jar!/mappers/ConfDictElemMapper.xml]'; nested exception is org.apache.ibatis.builder.BuilderException: Error parsing Mapper XML. Cause: java.lang.IllegalArgumentException: Result Maps collection already contains value for com.hikvision.sparta.etl.db.mappers.ConfDictElemMapper.BaseResultMap; nested exception is org.springframework.beans.factory.BeanCreationException: Error creating bean with name 'sqlSessionFactory' defined in class path resource [applicationContext-etldb.xml]: Invocation of init method failed; nested exception is org.springframework.core.NestedIOException: Failed to parse mapping resource: 'URL [jar:file:/mnt/disk1/data/LOCALCLUSTER/SERVICE-HADOOP-79dbed26cf7f49729e42a75f0f84c3e7/nm/local/usercache/root/appcache/application_1498183093431_1151/container_1498183093431_1151_02_000001/__app__.jar!/mappers/ConfDictElemMapper.xml]'; nested exception is org.apache.ibatis.builder.BuilderException: Error parsing Mapper XML. Cause: java.lang.IllegalArgumentException: Result Maps collection already contains value for com.hikvision.sparta.etl.db.mappers.ConfDictElemMapper.BaseResultMap
```

18. val builder = SparkSession.builder().appName(appname).enableHiveSupport() 作为sparkAction 执行失败
``` console
java.lang.IllegalArgumentException: Error while instantiating 'org.apache.spark.sql.hive.HiveSessionState':
	at org.apache.spark.sql.SparkSession$.org$apache$spark$sql$SparkSession$$reflect(SparkSession.scala:981)
	at org.apache.spark.sql.SparkSession.sessionState$lzycompute(SparkSession.scala:110)
	at org.apache.spark.sql.SparkSession.sessionState(SparkSession.scala:109)
	at org.apache.spark.sql.SparkSession$Builder$$anonfun$getOrCreate$5.apply(SparkSession.scala:878)
	at org.apache.spark.sql.SparkSession$Builder$$anonfun$getOrCreate$5.apply(SparkSession.scala:878)
	at scala.collection.mutable.HashMap$$anonfun$foreach$1.apply(HashMap.scala:99)
	at scala.collection.mutable.HashMap$$anonfun$foreach$1.apply(HashMap.scala:99)
	at scala.collection.mutable.HashTable$class.foreachEntry(HashTable.scala:230)
	at scala.collection.mutable.HashMap.foreachEntry(HashMap.scala:40)
	at scala.collection.mutable.HashMap.foreach(HashMap.scala:99)
	at org.apache.spark.sql.SparkSession$Builder.getOrCreate(SparkSession.scala:878)
	at com.hikvision.sparta.etl.load.dataload.DataLoad$.initSpark(DataLoad.scala:192)
	at com.hikvision.sparta.etl.load.dataload.DataLoad$.run(DataLoad.scala:24)
	at com.hikvision.sparta.etl.load.dataload.DataLoad$.main(DataLoad.scala:19)
	at com.hikvision.sparta.etl.load.dataload.DataLoad.main(DataLoad.scala)
	at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
	at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
	at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
	at java.lang.reflect.Method.invoke(Method.java:498)
	at org.apache.spark.deploy.SparkSubmit$.org$apache$spark$deploy$SparkSubmit$$runMain(SparkSubmit.scala:738)
	at org.apache.spark.deploy.SparkSubmit$.doRunMain$1(SparkSubmit.scala:187)
	at org.apache.spark.deploy.SparkSubmit$.submit(SparkSubmit.scala:212)
	at org.apache.spark.deploy.SparkSubmit$.main(SparkSubmit.scala:126)
	at org.apache.spark.deploy.SparkSubmit.main(SparkSubmit.scala)
	at org.apache.oozie.action.hadoop.SparkMain.runSpark(SparkMain.java:372)
	at org.apache.oozie.action.hadoop.SparkMain.run(SparkMain.java:282)
	at org.apache.oozie.action.hadoop.LauncherMain.run(LauncherMain.java:64)
	at org.apache.oozie.action.hadoop.SparkMain.main(SparkMain.java:82)
	at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
	at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
	at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
	at java.lang.reflect.Method.invoke(Method.java:498)
	at org.apache.oozie.action.hadoop.LauncherMapper.map(LauncherMapper.java:234)
	at org.apache.hadoop.mapred.MapRunner.run(MapRunner.java:54)
	at org.apache.hadoop.mapred.MapTask.runOldMapper(MapTask.java:453)
	at org.apache.hadoop.mapred.MapTask.run(MapTask.java:343)
	at org.apache.hadoop.mapred.LocalContainerLauncher$EventHandler.runSubtask(LocalContainerLauncher.java:388)
	at org.apache.hadoop.mapred.LocalContainerLauncher$EventHandler.runTask(LocalContainerLauncher.java:302)
	at org.apache.hadoop.mapred.LocalContainerLauncher$EventHandler.access$200(LocalContainerLauncher.java:187)
	at org.apache.hadoop.mapred.LocalContainerLauncher$EventHandler$1.run(LocalContainerLauncher.java:230)
	at java.util.concurrent.Executors$RunnableAdapter.call(Executors.java:511)
	at java.util.concurrent.FutureTask.run(FutureTask.java:266)
	at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1142)
	at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:617)
	at java.lang.Thread.run(Thread.java:748)
Caused by: java.lang.reflect.InvocationTargetException
	at sun.reflect.NativeConstructorAccessorImpl.newInstance0(Native Method)
	at sun.reflect.NativeConstructorAccessorImpl.newInstance(NativeConstructorAccessorImpl.java:62)
	at sun.reflect.DelegatingConstructorAccessorImpl.newInstance(DelegatingConstructorAccessorImpl.java:45)
	at java.lang.reflect.Constructor.newInstance(Constructor.java:423)
	at org.apache.spark.sql.SparkSession$.org$apache$spark$sql$SparkSession$$reflect(SparkSession.scala:978)
	... 44 more
Caused by: java.lang.IllegalArgumentException: Error while instantiating 'org.apache.spark.sql.hive.HiveExternalCatalog':
	at org.apache.spark.sql.internal.SharedState$.org$apache$spark$sql$internal$SharedState$$reflect(SharedState.scala:169)
	at org.apache.spark.sql.internal.SharedState.<init>(SharedState.scala:86)
	at org.apache.spark.sql.SparkSession$$anonfun$sharedState$1.apply(SparkSession.scala:101)
	at org.apache.spark.sql.SparkSession$$anonfun$sharedState$1.apply(SparkSession.scala:101)
	at scala.Option.getOrElse(Option.scala:121)
	at org.apache.spark.sql.SparkSession.sharedState$lzycompute(SparkSession.scala:101)
	at org.apache.spark.sql.SparkSession.sharedState(SparkSession.scala:100)
	at org.apache.spark.sql.internal.SessionState.<init>(SessionState.scala:157)
	at org.apache.spark.sql.hive.HiveSessionState.<init>(HiveSessionState.scala:32)
	... 49 more
Caused by: java.lang.reflect.InvocationTargetException
	at sun.reflect.NativeConstructorAccessorImpl.newInstance0(Native Method)
	at sun.reflect.NativeConstructorAccessorImpl.newInstance(NativeConstructorAccessorImpl.java:62)
	at sun.reflect.DelegatingConstructorAccessorImpl.newInstance(DelegatingConstructorAccessorImpl.java:45)
	at java.lang.reflect.Constructor.newInstance(Constructor.java:423)
	at org.apache.spark.sql.internal.SharedState$.org$apache$spark$sql$internal$SharedState$$reflect(SharedState.scala:166)
	... 57 more
Caused by: java.lang.NoClassDefFoundError: org/apache/hadoop/hive/conf/HiveConf$ConfVars
	at org.apache.spark.sql.hive.HiveUtils$.hiveClientConfigurations(HiveUtils.scala:192)
	at org.apache.spark.sql.hive.HiveUtils$.newClientForMetadata(HiveUtils.scala:269)
	at org.apache.spark.sql.hive.HiveExternalCatalog.<init>(HiveExternalCatalog.scala:65)
	... 62 more
Caused by: java.lang.ClassNotFoundException: org.apache.hadoop.hive.conf.HiveConf$ConfVars
	at java.net.URLClassLoader.findClass(URLClassLoader.java:381)
	at java.lang.ClassLoader.loadClass(ClassLoader.java:424)
	at sun.misc.Launcher$AppClassLoader.loadClass(Launcher.java:335)
	at java.lang.ClassLoader.loadClass(ClassLoader.java:357)
```
解决办法：
1. cd ${OOZIE_SRC_HOME}/sharelib ##最终版本
2. vim ${OOZIE_SRC_HOME}/sharelib/spark/pom.xml
``` xml
<dependency>
    <groupId>org.apache.spark</groupId>
    <artifactId>spark-hive_2.11</artifactId>
    <version>${spark.version}</version>
    <scope>compile</scope>
</dependency>
```
3. mvn -DskipTests clean package assembly:single

19. Caused by: org.datanucleus.exceptions.NucleusUserException: The connection pool plugin of type "BONECP" was not found in the CLASSPATH!
``` console
java.lang.IllegalArgumentException: Error while instantiating 'org.apache.spark.sql.hive.HiveSessionState':
	at org.apache.spark.sql.SparkSession$.org$apache$spark$sql$SparkSession$$reflect(SparkSession.scala:981)
	at org.apache.spark.sql.SparkSession.sessionState$lzycompute(SparkSession.scala:110)
	at org.apache.spark.sql.SparkSession.sessionState(SparkSession.scala:109)
	at org.apache.spark.sql.SparkSession$Builder$$anonfun$getOrCreate$5.apply(SparkSession.scala:878)
	at org.apache.spark.sql.SparkSession$Builder$$anonfun$getOrCreate$5.apply(SparkSession.scala:878)
	at scala.collection.mutable.HashMap$$anonfun$foreach$1.apply(HashMap.scala:99)
	at scala.collection.mutable.HashMap$$anonfun$foreach$1.apply(HashMap.scala:99)
	at scala.collection.mutable.HashTable$class.foreachEntry(HashTable.scala:230)
	at scala.collection.mutable.HashMap.foreachEntry(HashMap.scala:40)
	at scala.collection.mutable.HashMap.foreach(HashMap.scala:99)
	at org.apache.spark.sql.SparkSession$Builder.getOrCreate(SparkSession.scala:878)
	at com.hikvision.sparta.etl.load.dataload.DataLoad$.initSpark(DataLoad.scala:192)
	at com.hikvision.sparta.etl.load.dataload.DataLoad$.run(DataLoad.scala:24)
	at com.hikvision.sparta.etl.load.dataload.DataLoad$.main(DataLoad.scala:19)
	at com.hikvision.sparta.etl.load.dataload.DataLoad.main(DataLoad.scala)
	at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
	at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
	at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
	at java.lang.reflect.Method.invoke(Method.java:498)
	at org.apache.spark.deploy.SparkSubmit$.org$apache$spark$deploy$SparkSubmit$$runMain(SparkSubmit.scala:738)
	at org.apache.spark.deploy.SparkSubmit$.doRunMain$1(SparkSubmit.scala:187)
	at org.apache.spark.deploy.SparkSubmit$.submit(SparkSubmit.scala:212)
	at org.apache.spark.deploy.SparkSubmit$.main(SparkSubmit.scala:126)
	at org.apache.spark.deploy.SparkSubmit.main(SparkSubmit.scala)
	at org.apache.oozie.action.hadoop.SparkMain.runSpark(SparkMain.java:372)
	at org.apache.oozie.action.hadoop.SparkMain.run(SparkMain.java:282)
	at org.apache.oozie.action.hadoop.LauncherMain.run(LauncherMain.java:64)
	at org.apache.oozie.action.hadoop.SparkMain.main(SparkMain.java:82)
	at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
	at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
	at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
	at java.lang.reflect.Method.invoke(Method.java:498)
	at org.apache.oozie.action.hadoop.LauncherMapper.map(LauncherMapper.java:234)
	at org.apache.hadoop.mapred.MapRunner.run(MapRunner.java:54)
	at org.apache.hadoop.mapred.MapTask.runOldMapper(MapTask.java:453)
	at org.apache.hadoop.mapred.MapTask.run(MapTask.java:343)
	at org.apache.hadoop.mapred.LocalContainerLauncher$EventHandler.runSubtask(LocalContainerLauncher.java:388)
	at org.apache.hadoop.mapred.LocalContainerLauncher$EventHandler.runTask(LocalContainerLauncher.java:302)
	at org.apache.hadoop.mapred.LocalContainerLauncher$EventHandler.access$200(LocalContainerLauncher.java:187)
	at org.apache.hadoop.mapred.LocalContainerLauncher$EventHandler$1.run(LocalContainerLauncher.java:230)
	at java.util.concurrent.Executors$RunnableAdapter.call(Executors.java:511)
	at java.util.concurrent.FutureTask.run(FutureTask.java:266)
	at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1142)
	at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:617)
	at java.lang.Thread.run(Thread.java:748)
Caused by: java.lang.reflect.InvocationTargetException
	at sun.reflect.NativeConstructorAccessorImpl.newInstance0(Native Method)
	at sun.reflect.NativeConstructorAccessorImpl.newInstance(NativeConstructorAccessorImpl.java:62)
	at sun.reflect.DelegatingConstructorAccessorImpl.newInstance(DelegatingConstructorAccessorImpl.java:45)
	at java.lang.reflect.Constructor.newInstance(Constructor.java:423)
	at org.apache.spark.sql.SparkSession$.org$apache$spark$sql$SparkSession$$reflect(SparkSession.scala:978)
	... 44 more
Caused by: java.lang.IllegalArgumentException: Error while instantiating 'org.apache.spark.sql.hive.HiveExternalCatalog':
	at org.apache.spark.sql.internal.SharedState$.org$apache$spark$sql$internal$SharedState$$reflect(SharedState.scala:169)
	at org.apache.spark.sql.internal.SharedState.<init>(SharedState.scala:86)
	at org.apache.spark.sql.SparkSession$$anonfun$sharedState$1.apply(SparkSession.scala:101)
	at org.apache.spark.sql.SparkSession$$anonfun$sharedState$1.apply(SparkSession.scala:101)
	at scala.Option.getOrElse(Option.scala:121)
	at org.apache.spark.sql.SparkSession.sharedState$lzycompute(SparkSession.scala:101)
	at org.apache.spark.sql.SparkSession.sharedState(SparkSession.scala:100)
	at org.apache.spark.sql.internal.SessionState.<init>(SessionState.scala:157)
	at org.apache.spark.sql.hive.HiveSessionState.<init>(HiveSessionState.scala:32)
	... 49 more
Caused by: java.lang.reflect.InvocationTargetException
	at sun.reflect.NativeConstructorAccessorImpl.newInstance0(Native Method)
	at sun.reflect.NativeConstructorAccessorImpl.newInstance(NativeConstructorAccessorImpl.java:62)
	at sun.reflect.DelegatingConstructorAccessorImpl.newInstance(DelegatingConstructorAccessorImpl.java:45)
	at java.lang.reflect.Constructor.newInstance(Constructor.java:423)
	at org.apache.spark.sql.internal.SharedState$.org$apache$spark$sql$internal$SharedState$$reflect(SharedState.scala:166)
	... 57 more
Caused by: java.lang.reflect.InvocationTargetException
	at sun.reflect.NativeConstructorAccessorImpl.newInstance0(Native Method)
	at sun.reflect.NativeConstructorAccessorImpl.newInstance(NativeConstructorAccessorImpl.java:62)
	at sun.reflect.DelegatingConstructorAccessorImpl.newInstance(DelegatingConstructorAccessorImpl.java:45)
	at java.lang.reflect.Constructor.newInstance(Constructor.java:423)
	at org.apache.spark.sql.hive.client.IsolatedClientLoader.createClient(IsolatedClientLoader.scala:264)
	at org.apache.spark.sql.hive.HiveUtils$.newClientForMetadata(HiveUtils.scala:366)
	at org.apache.spark.sql.hive.HiveUtils$.newClientForMetadata(HiveUtils.scala:270)
	at org.apache.spark.sql.hive.HiveExternalCatalog.<init>(HiveExternalCatalog.scala:65)
	... 62 more
Caused by: java.lang.RuntimeException: java.lang.RuntimeException: Unable to instantiate org.apache.hadoop.hive.ql.metadata.SessionHiveMetaStoreClient
	at org.apache.hadoop.hive.ql.session.SessionState.start(SessionState.java:522)
	at org.apache.spark.sql.hive.client.HiveClientImpl.<init>(HiveClientImpl.scala:192)
	... 70 more
Caused by: java.lang.RuntimeException: Unable to instantiate org.apache.hadoop.hive.ql.metadata.SessionHiveMetaStoreClient
	at org.apache.hadoop.hive.metastore.MetaStoreUtils.newInstance(MetaStoreUtils.java:1523)
	at org.apache.hadoop.hive.metastore.RetryingMetaStoreClient.<init>(RetryingMetaStoreClient.java:86)
	at org.apache.hadoop.hive.metastore.RetryingMetaStoreClient.getProxy(RetryingMetaStoreClient.java:132)
	at org.apache.hadoop.hive.metastore.RetryingMetaStoreClient.getProxy(RetryingMetaStoreClient.java:104)
	at org.apache.hadoop.hive.ql.metadata.Hive.createMetaStoreClient(Hive.java:3005)
	at org.apache.hadoop.hive.ql.metadata.Hive.getMSC(Hive.java:3024)
	at org.apache.hadoop.hive.ql.session.SessionState.start(SessionState.java:503)
	... 71 more
Caused by: java.lang.reflect.InvocationTargetException
	at sun.reflect.NativeConstructorAccessorImpl.newInstance0(Native Method)
	at sun.reflect.NativeConstructorAccessorImpl.newInstance(NativeConstructorAccessorImpl.java:62)
	at sun.reflect.DelegatingConstructorAccessorImpl.newInstance(DelegatingConstructorAccessorImpl.java:45)
	at java.lang.reflect.Constructor.newInstance(Constructor.java:423)
	at org.apache.hadoop.hive.metastore.MetaStoreUtils.newInstance(MetaStoreUtils.java:1521)
	... 77 more
Caused by: javax.jdo.JDOFatalInternalException: Error creating transactional connection factory
NestedThrowables:
java.lang.reflect.InvocationTargetException
	at org.datanucleus.api.jdo.NucleusJDOHelper.getJDOExceptionForNucleusException(NucleusJDOHelper.java:587)
	at org.datanucleus.api.jdo.JDOPersistenceManagerFactory.freezeConfiguration(JDOPersistenceManagerFactory.java:788)
	at org.datanucleus.api.jdo.JDOPersistenceManagerFactory.createPersistenceManagerFactory(JDOPersistenceManagerFactory.java:333)
	at org.datanucleus.api.jdo.JDOPersistenceManagerFactory.getPersistenceManagerFactory(JDOPersistenceManagerFactory.java:202)
	at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
	at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
	at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
	at java.lang.reflect.Method.invoke(Method.java:498)
	at javax.jdo.JDOHelper$16.run(JDOHelper.java:1965)
	at java.security.AccessController.doPrivileged(Native Method)
	at javax.jdo.JDOHelper.invoke(JDOHelper.java:1960)
	at javax.jdo.JDOHelper.invokeGetPersistenceManagerFactoryOnImplementation(JDOHelper.java:1166)
	at javax.jdo.JDOHelper.getPersistenceManagerFactory(JDOHelper.java:808)
	at javax.jdo.JDOHelper.getPersistenceManagerFactory(JDOHelper.java:701)
	at org.apache.hadoop.hive.metastore.ObjectStore.getPMF(ObjectStore.java:365)
	at org.apache.hadoop.hive.metastore.ObjectStore.getPersistenceManager(ObjectStore.java:394)
	at org.apache.hadoop.hive.metastore.ObjectStore.initialize(ObjectStore.java:291)
	at org.apache.hadoop.hive.metastore.ObjectStore.setConf(ObjectStore.java:258)
	at org.apache.hadoop.util.ReflectionUtils.setConf(ReflectionUtils.java:73)
	at org.apache.hadoop.util.ReflectionUtils.newInstance(ReflectionUtils.java:133)
	at org.apache.hadoop.hive.metastore.RawStoreProxy.<init>(RawStoreProxy.java:57)
	at org.apache.hadoop.hive.metastore.RawStoreProxy.getProxy(RawStoreProxy.java:66)
	at org.apache.hadoop.hive.metastore.HiveMetaStore$HMSHandler.newRawStore(HiveMetaStore.java:593)
	at org.apache.hadoop.hive.metastore.HiveMetaStore$HMSHandler.getMS(HiveMetaStore.java:571)
	at org.apache.hadoop.hive.metastore.HiveMetaStore$HMSHandler.createDefaultDB(HiveMetaStore.java:624)
	at org.apache.hadoop.hive.metastore.HiveMetaStore$HMSHandler.init(HiveMetaStore.java:461)
	at org.apache.hadoop.hive.metastore.RetryingHMSHandler.<init>(RetryingHMSHandler.java:66)
	at org.apache.hadoop.hive.metastore.RetryingHMSHandler.getProxy(RetryingHMSHandler.java:72)
	at org.apache.hadoop.hive.metastore.HiveMetaStore.newRetryingHMSHandler(HiveMetaStore.java:5762)
	at org.apache.hadoop.hive.metastore.HiveMetaStoreClient.<init>(HiveMetaStoreClient.java:199)
	at org.apache.hadoop.hive.ql.metadata.SessionHiveMetaStoreClient.<init>(SessionHiveMetaStoreClient.java:74)
	... 82 more
Caused by: java.lang.reflect.InvocationTargetException
	at sun.reflect.NativeConstructorAccessorImpl.newInstance0(Native Method)
	at sun.reflect.NativeConstructorAccessorImpl.newInstance(NativeConstructorAccessorImpl.java:62)
	at sun.reflect.DelegatingConstructorAccessorImpl.newInstance(DelegatingConstructorAccessorImpl.java:45)
	at java.lang.reflect.Constructor.newInstance(Constructor.java:423)
	at org.datanucleus.plugin.NonManagedPluginRegistry.createExecutableExtension(NonManagedPluginRegistry.java:631)
	at org.datanucleus.plugin.PluginManager.createExecutableExtension(PluginManager.java:325)
	at org.datanucleus.store.AbstractStoreManager.registerConnectionFactory(AbstractStoreManager.java:282)
	at org.datanucleus.store.AbstractStoreManager.<init>(AbstractStoreManager.java:240)
	at org.datanucleus.store.rdbms.RDBMSStoreManager.<init>(RDBMSStoreManager.java:286)
	at sun.reflect.NativeConstructorAccessorImpl.newInstance0(Native Method)
	at sun.reflect.NativeConstructorAccessorImpl.newInstance(NativeConstructorAccessorImpl.java:62)
	at sun.reflect.DelegatingConstructorAccessorImpl.newInstance(DelegatingConstructorAccessorImpl.java:45)
	at java.lang.reflect.Constructor.newInstance(Constructor.java:423)
	at org.datanucleus.plugin.NonManagedPluginRegistry.createExecutableExtension(NonManagedPluginRegistry.java:631)
	at org.datanucleus.plugin.PluginManager.createExecutableExtension(PluginManager.java:301)
	at org.datanucleus.NucleusContext.createStoreManagerForProperties(NucleusContext.java:1187)
	at org.datanucleus.NucleusContext.initialise(NucleusContext.java:356)
	at org.datanucleus.api.jdo.JDOPersistenceManagerFactory.freezeConfiguration(JDOPersistenceManagerFactory.java:775)
	... 111 more
Caused by: org.datanucleus.exceptions.NucleusException: Attempt to invoke the "BONECP" plugin to create a ConnectionPool gave an error : The connection pool plugin of type "BONECP" was not found in the CLASSPATH!
	at org.datanucleus.store.rdbms.ConnectionFactoryImpl.generateDataSources(ConnectionFactoryImpl.java:259)
	at org.datanucleus.store.rdbms.ConnectionFactoryImpl.initialiseDataSources(ConnectionFactoryImpl.java:131)
	at org.datanucleus.store.rdbms.ConnectionFactoryImpl.<init>(ConnectionFactoryImpl.java:85)
	... 129 more
Caused by: org.datanucleus.exceptions.NucleusUserException: The connection pool plugin of type "BONECP" was not found in the CLASSPATH!
	at org.datanucleus.store.rdbms.ConnectionFactoryImpl.generateDataSources(ConnectionFactoryImpl.java:234)
	... 131 more
```
解决方法：
1. Create a spark2 ShareLib directory under the Oozie ShareLib directory associated with the oozie service user:
    a. hdfs dfs -mkdir /user/oozie/share/lib/lib_<ts>/spark2
2. Copy local ${SPARK_HOME}/jars files the Oozie spark2 ShareLib:
    a. hdfs dfs -put ${SPARK_HOME}/jars/* /user/oozie/share/lib/lib_<ts>/spark2/
3. Copy the self build oozie-sharelib-spark jar file from the spark ShareLib directory to the spark2 ShareLib directory:
    a. hdfs dfs -cp /user/oozie/share/lib/lib_<ts>/spark/oozie-sharelib-spark-<version>.jar /user/oozie/share/lib/lib_<ts>/spark2/
4. Copy local ${SPARK_CONF_HOME}/hive-site.xml file to the spark2 ShareLib:
    a. hdfs dfs -put ${SPARK_CONF_HOME}/hive-site.xml /user/oozie/share/lib/lib_<ts>/spark2/
5. Copy Python libraries to the spark2 ShareLib:
    a. hdfs dfs -put ${SPARK_HOME}/python/lib/py* /user/oozie/share/lib/lib_<ts>/spark2/
6. Run the Oozie sharelibupdate command:
    a. oozie admin –sharelibupdate

20. 
``` console
Failing Oozie Launcher, Main class [org.apache.oozie.action.hadoop.SparkMain], main() threw exception, Library directory '/mnt/disk1/data/LOCALCLUSTER/SERVICE-HADOOP-79dbed26cf7f49729e42a75f0f84c3e7/nm/local/usercache/root/appcache/application_1507728269197_0432/container_1507728269197_0432_01_000001/assembly/target/scala-2.11/jars' does not exist; make sure Spark is built.
java.lang.IllegalStateException: Library directory '/mnt/disk1/data/LOCALCLUSTER/SERVICE-HADOOP-79dbed26cf7f49729e42a75f0f84c3e7/nm/local/usercache/root/appcache/application_1507728269197_0432/container_1507728269197_0432_01_000001/assembly/target/scala-2.11/jars' does not exist; make sure Spark is built.
    at org.apache.spark.launcher.CommandBuilderUtils.checkState(CommandBuilderUtils.java:248)
    at org.apache.spark.launcher.CommandBuilderUtils.findJarsDir(CommandBuilderUtils.java:368)
    at org.apache.spark.launcher.YarnCommandBuilderUtils$.findJarsDir(YarnCommandBuilderUtils.scala:38)
    at org.apache.spark.deploy.yarn.Client.prepareLocalResources(Client.scala:547)
    at org.apache.spark.deploy.yarn.Client.createContainerLaunchContext(Client.scala:868)
    at org.apache.spark.deploy.yarn.Client.submitApplication(Client.scala:170)
    at org.apache.spark.scheduler.cluster.YarnClientSchedulerBackend.start(YarnClientSchedulerBackend.scala:56)
    at org.apache.spark.scheduler.TaskSchedulerImpl.start(TaskSchedulerImpl.scala:156)
    at org.apache.spark.SparkContext.<init>(SparkContext.scala:509)
    at org.apache.spark.SparkContext$.getOrCreate(SparkContext.scala:2313)
    at org.apache.spark.sql.SparkSession$Builder$$anonfun$6.apply(SparkSession.scala:868)
    at org.apache.spark.sql.SparkSession$Builder$$anonfun$6.apply(SparkSession.scala:860)
    at scala.Option.getOrElse(Option.scala:121)
    at org.apache.spark.sql.SparkSession$Builder.getOrCreate(SparkSession.scala:860)
    at com.hikvision.sparta.etl.load.dataload.DataLoad$.initSpark(DataLoad.scala:192)
    at com.hikvision.sparta.etl.load.dataload.DataLoad$.run(DataLoad.scala:24)
    at com.hikvision.sparta.etl.load.dataload.DataLoad$.main(DataLoad.scala:19)
    at com.hikvision.sparta.etl.load.dataload.DataLoad.main(DataLoad.scala)
    at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
    at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
    at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
    at java.lang.reflect.Method.invoke(Method.java:498)
    at org.apache.spark.deploy.SparkSubmit$.org$apache$spark$deploy$SparkSubmit$$runMain(SparkSubmit.scala:738)
    at org.apache.spark.deploy.SparkSubmit$.doRunMain$1(SparkSubmit.scala:187)
    at org.apache.spark.deploy.SparkSubmit$.submit(SparkSubmit.scala:212)
    at org.apache.spark.deploy.SparkSubmit$.main(SparkSubmit.scala:126)
    at org.apache.spark.deploy.SparkSubmit.main(SparkSubmit.scala)
    at org.apache.oozie.action.hadoop.SparkMain.runSpark(SparkMain.java:372)
    at org.apache.oozie.action.hadoop.SparkMain.run(SparkMain.java:282)
    at org.apache.oozie.action.hadoop.LauncherMain.run(LauncherMain.java:64)
    at org.apache.oozie.action.hadoop.SparkMain.main(SparkMain.java:82)
    at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
    at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
    at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
    at java.lang.reflect.Method.invoke(Method.java:498)
    at org.apache.oozie.action.hadoop.LauncherMapper.map(LauncherMapper.java:234)
    at org.apache.hadoop.mapred.MapRunner.run(MapRunner.java:54)
    at org.apache.hadoop.mapred.MapTask.runOldMapper(MapTask.java:453)
    at org.apache.hadoop.mapred.MapTask.run(MapTask.java:343)
    at org.apache.hadoop.mapred.LocalContainerLauncher$EventHandler.runSubtask(LocalContainerLauncher.java:388)
    at org.apache.hadoop.mapred.LocalContainerLauncher$EventHandler.runTask(LocalContainerLauncher.java:302)
    at org.apache.hadoop.mapred.LocalContainerLauncher$EventHandler.access$200(LocalContainerLauncher.java:187)
    at org.apache.hadoop.mapred.LocalContainerLauncher$EventHandler$1.run(LocalContainerLauncher.java:230)
    at java.util.concurrent.Executors$RunnableAdapter.call(Executors.java:511)
    at java.util.concurrent.FutureTask.run(FutureTask.java:266)
    at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1142)
    at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:617)
    at java.lang.Thread.run(Thread.java:748)
```
解决方法：
``` xml
<workflow-app name="increment-load-wf" xmlns="uri:oozie:workflow:0.5">
    <global>
            <configuration>
                <property>
                    <name>mapred.compress.map.output</name>
                    <value>true</value>
                </property>
                <property>
                    <name>oozie.launcher.mapreduce.map.memory.mb</name>
                    <value>${map_memory_mb}</value>
                </property>
                <property>
                    <name>oozie.launcher.mapreduce.map.java.opts</name>
                    <value>${map_java_opts}</value>
                </property>
                <property>
                    <name>oozie.launcher.yarn.app.mapreduce.am.resource.mb</name>
                    <value>${am_resource_mb}</value>
                </property>
                <property>
                    <name>oozie.launcher.yarn.app.mapreduce.am.command-opts</name>
                    <value>${am_command_opts}</value>
                </property>
                <property>
                    <name>oozie.launcher.mapred.job.queue.name</name>
                    <value>default</value>
                </property>
                <property>
                        <name>oozie.launcher.yarn.app.mapreduce.am.env</name>
                        <value>SPARK_HOME=${spark_home}</value>
                </property>
            </configuration>
    </global>
    <start to='L_1'/>
    <action name="L_1">
        <spark xmlns="uri:oozie:spark-action:0.1">
            <job-tracker>${jobTracker}</job-tracker>
            <name-node>${nameNode}</name-node>
            <master>${master}</master>
            <mode>${deploy_mode}</mode>
            <name>L_1</name>
            <class>${load_class_name}</class>
            <jar>${load_jar_path}</jar>
            <spark-opts>${spark_opts}</spark-opts>
            <arg>--originTableId</arg>
            <arg>1</arg>
            <arg>--dataLoadVersion</arg>
            <arg>1</arg>
        </spark>

        <ok to="end"/>
        <error to="kill"/>
    </action>
    <kill name='kill'>
        <message>Something went wrong: ${wf:errorCode('firstdemo')}</message>
    </kill>
    <end name='end'/>
</workflow-app>
```

``` shell
oozie.action.sharelib.for.spark=spark2
nameNode=hdfs://master66:8020
jobTracker=master66:18040
queueName=default
spark_home=/usr/lib/LOCALCLUSTER/SERVICE-SPARK-2428609d66a34df2984159ba2e2f0d35
historyServer=http://master66:18088

# 定义如何运行
#oozie.coord.application.path=${nameNode}/dev/oozieJob/cron/incre
oozie.wf.application.path=${nameNode}/dev/oozieJob/cron/incre
map_memory_mb=2048
map_java_opts=-XX:MaxPermSize=1g
am_resource_mb=1536
am_command_opts=-Xmx1024m

start=2017-09-29T08:45+0800
end=2017-09-29T18:00+0800
workflowAppUri=${nameNode}/dev/oozieJob/cron/incre
oozie.use.system.libpath=true

frequency=0/30 * * * *
master=yarn
deploy_mode=client
load_jar_path=/usr/local/envTch/oozieJob/increload/sparta-vulcanus-load-assembly.jar
load_class_name=com.hikvision.sparta.etl.load.dataload.DataLoad
spark_opts=--num-executors 3 --executor-cores 1 --executor-memory 1G --driver-memory 512m --conf spark.yarn.historyServer.address=${historyServer} --conf spark.eventLog.dir=${nameNode}/var/log/spark_hislog --conf spark.eventLog.enabled=true
```

# oozie实践文档

### 通过cm安装oozie
1. 下载编译好的oozie-bin.tar.gz lark包，eg:[下载链接](http://maven.hikvision.com.cn/nexus/content/repositories/public/com/hikvision/bigdata/archives/v1/lark-packages/oozie/)
2. 将上步骤的tar文件解压放入该路径下：/usr/lib/cloudmanager/components/lark/packages
3. 打开cm web页面 eg：[master66 cluster manager](http://10.17.139.66:8877/cm/)
4. 依次点击 主机管理-->服务管理-->添加服务-->oozie-->服务名称前面勾选-->实例个数填1-->下一步-->部署


### 配置oozie环境变量
1. vim /etc/profile

``` shell
OOZIE_HOME=/usr/lib/LOCALCLUSTER/SERVICE-OOZIE-288ed77a9280405bae56627fb52ea305
export OOZIE_HOME PATH=$PATH:$OOZIE_HOME/bin
export OOZIE_URL=http://localhost:11000/oozie
```

### 配置oozie使用mysql数据库
1. 创建mysql的oozie数据库

``` sql
    create database ooziedb;
    grant all privileges on *.* to oozie@'localhost' identified by 'Hik12345+' with grant option;
    grant all privileges on *.* to oozie@'%' identified by 'Hik12345+' with grant option;
    flush privileges;
```

2. 编辑oozie配置文件
vim /etc/LOCALCLUSTER/SERVICE-OOZIE-288ed77a9280405bae56627fb52ea305/oozie-site.xml

``` xml
        <property>
            <name>oozie.db.schema.id</name>
            <value>ooziedb</value>
        </property>
        <property>
            <name>oozie.service.JPAService.create.db.schema</name>
            <value>true</value>
        </property>
        <property>
            <name>oozie.service.StoreService.jdbc.driver</name>
            <value>com.mysql.jdbc.Driver</value>
        </property>
        <property>
            <name>oozie.service.StoreService.jdbc.url</name>
            <value>jdbc:mysql://localhost:3306/ooziedb</value>
        </property>
        <property>
            <name>oozie.service.StoreService.jdbc.username</name>
            <value>oozie</value>
        </property>
        <property>
            <name>oozie.service.StoreService.jdbc.password</name>
            <value>Hik12345+</value>
        </property>
```

3. 拷贝mysql-connector-java-x.y.z.jar到/usr/lib/LOCALCLUSTER/SERVICE-OOZIE-288ed77a9280405bae56627fb52ea305/libtools/
4. 重启
5. 改变ooziedb的表结构

``` sql
ALTER TABLE `ooziedb`.`WF_ACTIONS` 
CHANGE COLUMN `execution_path` `execution_path` MEDIUMTEXT CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL ;
```

### oozie sharelib部署
1. 创建目录：
    a. mkdir /usr/local/envTch/oozieJob
    b. mkdir /usr/local/envTch/oozieJob/test #用于运行wordcount
    c. mkdir /usr/local/envTch/oozieJob/loadJob #用于运行实际数据资产层任务
    d. mkdir /usr/local/envTch/oozieJob/sharelib #用于存放sharelib tar包
2. 拷贝已编译好的oozie-sharelib-4.1.0-cdh5.11.0-sharelib.tar.gz到/usr/local/envTch/oozieJob/sharelib
3. 安装部署sharelib
    a. /usr/lib/LOCALCLUSTER/SERVICE-OOZIE-288ed77a9280405bae56627fb52ea305/bin/oozie-setup.sh sharelib create -fs hdfs://hdh94:8020 -locallib ./oozie-sharelib-4.1.0-cdh5.11.0-sharelib.tar.gz


### word任务准备及测试
1. 创建hdfs目录

    a. hadoop dfs -mkdir /dev/oozieJob/cron
    b. hadoop dfs -mkdir /dev/oozieJob/cron/test
2. 上传job workflow相关文件

    a. hadoop dfs -put ./workflow.xml /dev/oozieJob/cron/test
3. 适当更改job配置信息: vim ./job.properties 
4. 启动相关服务

    a. mr-jobhistory-daemon.sh start historyserver #启动yarn historyserver
5. 运行wordcount test job任务

    a. 准备测试数据
        1. 创建目录:/dev/datacenter/input/env/
        2. 上传文件:hadoop dfs -put ./input.txt /dev/datacenter/input/env/
    b. 运行提交任务:oozie job -oozie http://localhost:11000/oozie -config ./job.properties -run
    c. 查看是否成功
        1. oozie web:http://10.33.36.94:11000/oozie/
        2. 
    d. kill任务:oozie job -oozie http://localhost:11000/oozie -kill w_id | c_id

### 实例
- job.properties
``` shell
nameNode=hdfs://master:8020
jobTracker=master:18040
queueName=default

#oozie.coord.application.path=${nameNode}/dev/oozieJob/cron/incre #定时任务
oozie.wf.application.path=${nameNode}/dev/oozieJob/cron/incre #workflow任务
start=2017-06-07T02:00+0800
end=2017-06-07T03:00+0800
workflowAppUri=${nameNode}/dev/oozieJob/cron/incre
oozie.use.system.libpath=true

frequency=*/15 * * * *
master=yarn
deploy_mode=client
load_jar_path=/usr/local/envTch/oozieJob/increload/load-assembly.jar
load_class_name=com.chaosdata.etl.load.dataload.DataLoad
spark_opts=--num-executors 3 --executor-cores 1 --executor-memory 1G --driver-memory 512m --conf spark.yarn.historyServer.address=http://master:18088 --conf spark.eventLog.dir=hdfs://master:8020/var/log/spark_hislog --conf spark.eventLog.enabled=true

map_memory_mb=2048
map_java_opts=-XX:MaxPermSize=1g
am_resource_mb=1536
am_command_opts=-Xmx1024m
```

- workflow.xml
``` xml
<workflow-app name="increment-load-wf" xmlns="uri:oozie:workflow:0.5">
    <global>
            <configuration>
                <property>
                    <name>mapred.compress.map.output</name>
                    <value>true</value>
                </property>
                <property>
                    <name>oozie.launcher.mapreduce.map.memory.mb</name>
                    <value>${map_memory_mb}</value>
                </property>
                <property>
                    <name>oozie.launcher.mapreduce.map.java.opts</name>
                    <value>${map_java_opts}</value>
                </property>
                <property>
                    <name>oozie.launcher.yarn.app.mapreduce.am.resource.mb</name>
                    <value>${am_resource_mb}</value>
                </property>
                <property>
                    <name>oozie.launcher.yarn.app.mapreduce.am.command-opts</name>
                    <value>${am_command_opts}</value>
                </property>
                <property>
                    <name>oozie.launcher.mapred.job.queue.name</name>
                    <value>default</value>
                </property>
            </configuration>
    </global>

    <start to='L_1'/>
    <action name="L_1">
        <spark xmlns="uri:oozie:spark-action:0.1">
            <job-tracker>${jobTracker}</job-tracker>
            <name-node>${nameNode}</name-node>
            <master>${master}</master>
            <mode>${deploy_mode}</mode>
            <name>L_1</name>
            <class>${load_class_name}</class>
            <jar>${load_jar_path}</jar>
            <spark-opts>${spark_opts}</spark-opts>
            <arg>--originTableId</arg>
            <arg>1</arg>
        </spark>
        <ok to="L_22"/>
        <error to="kill"/>
    </action>

    <action name="L_22">
        <spark xmlns="uri:oozie:spark-action:0.1">
            <job-tracker>${jobTracker}</job-tracker>
            <name-node>${nameNode}</name-node>
            <master>${master}</master>
            <mode>${deploy_mode}</mode>
            <name>L_22</name>
            <class>${load_class_name}</class>
            <jar>${load_jar_path}</jar>
            <spark-opts>${spark_opts}</spark-opts>
            <arg>--originTableId</arg>
            <arg>22</arg>
        </spark>
        <ok to="end"/>
        <error to="kill"/>
    </action>

    <kill name='kill'>
        <message>Something went wrong: ${wf:errorCode('firstdemo')}</message>
    </kill>
    <end name='end'/>

</workflow-app>
```

- coordinator.xml
``` xml
<coordinator-app name="cron-wc-coord" frequency="${frequency}" start="${start}" end="${end}" timezone="Asia/Shanghai"
                 xmlns="uri:oozie:coordinator:0.2">
        <action>
        <workflow>
            <app-path>${workflowAppUri}</app-path>
            <configuration>
                <property>
                    <name>jobTracker</name>
                    <value>${jobTracker}</value>
                </property>
                <property>
                    <name>nameNode</name>
                    <value>${nameNode}</value>
                </property>
                <property>
                    <name>queueName</name>
                    <value>${queueName}</value>
                </property>
            </configuration>
        </workflow>
    </action>
</coordinator-app>
```