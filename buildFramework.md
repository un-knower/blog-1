---
title: buildFramework
date: 2017-06-07 09:31:38
tags:
    - spark
    - build
categories: 编译构建
---

### task
	``` shell
		mvn -Pyarn -Phive -Phive-thriftserver -Psparkr -Pbigtop-dist -Phadoop-2.6 -Dhadoop.version=2.6.0 -DskipTests clean package -X -e
	```

### question
1. 
	``` shell
	[INFO] BUILD FAILURE
	[INFO] ------------------------------------------------------------------------
	[INFO] Total time: 02:18 min
	[INFO] Finished at: 2017-06-08T16:45:12+08:00
	[INFO] Final Memory: 59M/3484M
	[INFO] ------------------------------------------------------------------------
	[ERROR] PermGen space -> [Help 1]
	java.lang.OutOfMemoryError: PermGen space
		at java.lang.ClassLoader.defineClass1(Native Method)
		at java.lang.ClassLoader.defineClass(ClassLoader.java:800)

	```
	解决方法：
	``` shell
		export MAVEN_OPTS="-Xmx4g -XX:ReservedCodeCacheSize=512m  -XX:MaxPermSize=1024m"
	```

### spark
1. mvn -Pyarn -Phadoop-2.6 -Dhadoop.version=2.6.0 -DskipTests clean package
2. mvn -Pyarn -Pbigtop-dist -Phadoop-2.6 -Dhadoop.version=2.6.0 -DskipTests clean package
3. mvn -Pyarn -Phadoop-2.4 -Dhadoop.version=2.4.0 -Phive -Phive-thriftserver -DskipTests clean package
4. mvn -Pyarn -Phadoop-2.4 -Dscala-2.10 -DskipTests clean package
