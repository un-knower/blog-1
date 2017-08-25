---
title: solr实践
date: 2017-07-20 19:40:21
tags: solr
---

``` shell
    ${SOLR_HOME}/server/scripts/cloud-scripts/zkcli.bat -zkhost localhost:9983 -cmd upconfig -confdir ${SOLR_HOME}/server/solr/configsets/map/conf -confname map

```

``` xml
 <delete><query>*:*</query></delete><commit/> 
```

- spark DataFrame直接写入solr
``` xml
    <dependency>
        <groupId>com.lucidworks.spark</groupId>
        <artifactId>spark-solr</artifactId>
        <version>3.0.0-alpha</version>
    </dependency>
```
``` scala
    val builder = SparkSession
      .builder()
      .appName(AppArgs.appName)

    if (AppArgs.debug) {
      builder.master("local")
    }

    val spark = builder.getOrCreate()
    val df = run(spark).select("Address", "LATB", "LNGB").filter(caseFilter(_))
    df.printSchema()
    printf(s"数据量为：${df.count()}")
    df.show(10)

    val options = Map(
      "zkhost" -> "10.17.139.66:2181/solr",
      "collection" -> "zsmap",
      "gen_uniq_key" -> "true" // Generate unique key if the 'id' field does not exist
    )

    // Write to Solr
    df.write.format("solr").options(options).mode(org.apache.spark.sql.SaveMode.Overwrite).save

    spark.stop()
```



``` scala
  /**
    * 查询入口
    *
    * @param addresss 地址数组
    * @return
    */
  def run(addresss: Array[String]): Array[SolrDocument] = {
    val solr = new CloudSolrClient.Builder().withZkHost(PropertyConstant.ZK_HOST).build
    solr.setDefaultCollection(PropertyConstant.DEFAULT_COLLECTION)

    val buffer = new ArrayBuffer[SolrDocument]()

    for (addr <- addresss) {
      val docs = query(solr, s"HIKMAP:$addr")

      buffer.append(if (docs == null || docs.isEmpty) null else docs.iterator().next())
    }

    solr.close()

    buffer.toArray
  }

  /**
    * 具体单次查询
    *
    * @param solr
    * @param queryStr
    * @return
    */
  private def query(solr: CloudSolrClient, queryStr: String): SolrDocumentList = {
    val query = new SolrQuery
    // query.setQuery(queryStr)
    // import org.apache.solr.client.solrj.util.ClientUtils
    // 转义查询str，避免特殊字符异常
    query.setQuery(ClientUtils.escapeQueryChars(queryStr))

    val response = solr.query(query)
    response.getResults
  }
```

## 安装
- tar xzf solr-6.6.0.tgz solr-6.6.0/bin/install_solr_service.sh --strip-components=2
- sudo bash ./install_solr_service.sh solr-6.6.0.tgz -i /opt -d /var/solr -u solr -s solr -p 8983
    + -i ：表solr安装目录
    + -d ：solr数据目录
    + -u ：solr使用用户
    + -p ：solr服务端口
- 指定jdk8 JAVA_HOME:
  + vim /etc/default/solr.in.sh 
  + 修改添加：SOLR_JAVA_HOME="/usr/local/envTech/mapengine/jdk1.8.0_121"
- 指定zkhost：
  + vim /etc/default/solr.in.sh 
  + 修改添加：ZK_HOST="localhost:2181/solr"
- 验证：sudo service solr status
- 问题记录：
  + root用户安装之后，启动solr service solr restart，报错：
    * 解决方案：vim ${SOLR_HOME}/bin/solr        -- line 1350 FORCE=false 改为 FORCE=true
- copyfiled stored=false

### create collection
问题：Cannot create collection mapzs. Value of maxShardsPerNode is 1,
http://localhost:8983/solr/admin/collections?action=CREATE&name=mapzs&numShards=2&replicationFactor=1&maxShardsPerNode=2&collection.configName=map

### IK分词
#### 配置IK分词
- $SOLR_INSTALL_HOME=E:\developPlat\solr-6.6.0
- ik-analyzer-solr6-6.0.jar 放入${SOLR_INSTALL_HOME}\server\solr-webapp\webapp\WEB-INF\lib
    + 编辑该jar文件可修改里面的文件：IKAnalyzer.cfg.xml、ext.dic、stopword.dic
- 添加自定义词库：编辑该jar文件可修改里面的文件 -> ext.dic
- 重启solr: service solr restart
