---
title: solr实践
date: 2017-07-20 19:40:21
tags:
---

``` shell
    ${SOLR_HOME}/server/scripts/cloud-scripts/zkcli.bat -zkhost localhost:9983 -cmd upconfig -confdir ${SOLR_HOME}/server/solr/configsets/map/conf -confname map

```

``` xml
 <delete><query>*:*</query></delete><commit/> 
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


### create collection
问题：Cannot create collection mapzs. Value of maxShardsPerNode is 1,
http://localhost:8983/solr/admin/collections?action=CREATE&name=mapzs&numShards=2&replicationFactor=1&maxShardsPerNode=2&collection.configName=map

### IK分词
#### 配置IK分词
- $SOLR_INSTALL_HOME=E:\developPlat\solr-6.6.0
- ik-analyzer-solr6-6.0.jar 放入${SOLR_INSTALL_HOME}\server\solr-webapp\webapp\WEB-INF\lib
    + 编辑该jar文件可修改里面的文件：IKAnalyzer.cfg.xml、ext.dic、stopword.dic
    + 
- 重启solr
