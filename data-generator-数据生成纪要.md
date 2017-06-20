---
title: data-generator-数据生成纪要
date: 2017-06-09 11:33:28
tags: data
categories: 研发
toc: true
---

[TOC]

### 格式化数据生成

#### pom.xml
    ``` xml
        <properties>
            <scala.version>2.11.8</scala.version>
            <scala.binary.version>2.11</scala.binary.version>
            <spark.version>2.1.0</spark.version>
            <repo.url>https://chaosdata.com</repo.url>
        </properties>

        <dependencies>
            <dependency>
                <groupId>org.apache.spark</groupId>
                <artifactId>spark-core_${scala.binary.version}</artifactId>
                <version>${spark.version}</version>
            </dependency>
            <dependency>
                <groupId>org.apache.spark</groupId>
                <artifactId>spark-sql_${scala.binary.version}</artifactId>
                <version>${spark.version}</version>
            </dependency>
            <dependency>
                <groupId>com.github.binarywang</groupId>
                <artifactId>java-generator</artifactId>
                <version>1.0.0</version>
                <exclusions>
                    <exclusion>
                        <artifactId>guava</artifactId>
                        <groupId>com.google.guava</groupId>
                    </exclusion>
                </exclusions>
            </dependency>
            <dependency>
                <groupId>org.testng</groupId>
                <artifactId>testng</artifactId>
                <version>6.9.10</version>
                <scope>test</scope>
            </dependency>
            <dependency>
                <groupId>joda-time</groupId>
                <artifactId>joda-time</artifactId>
                <version>2.7</version>
            </dependency>
            <dependency>
                <groupId>org.apache.hbase</groupId>
                <artifactId>hbase-client</artifactId>
                <version>1.2.0-cdh5.7.0</version>
            </dependency>
            <dependency>
                <groupId>org.apache.hbase</groupId>
                <artifactId>hbase-spark</artifactId>
                <version>1.2.0-cdh5.7.0</version>
                <exclusions>
                    <exclusion>
                        <artifactId>guava</artifactId>
                        <groupId>com.google.guava</groupId>
                        </exclusion>
                </exclusions>
            </dependency>
            <dependency>
                <groupId>org.apache.parquet</groupId>
                <artifactId>parquet-avro</artifactId>
                <version>1.9.0</version>
            </dependency>
            <dependency>
                <groupId>org.apache.avro</groupId>
                <artifactId>avro</artifactId>
                <version>1.7.7</version>
            </dependency>
            <dependency>
                <groupId>org.apache.avro</groupId>
                <artifactId>avro-tools</artifactId>
                <version>1.7.7</version>
            </dependency>
            <dependency>
                <groupId>com.databricks</groupId>
                <artifactId>spark-avro_${scala.binary.version}</artifactId>
                <version>3.2.0</version>
            </dependency>
        </dependencies>

        <build>
            <finalName>env-test</finalName>
            <plugins>
                <plugin>
                    <groupId>org.apache.maven.plugins</groupId>
                    <artifactId>maven-shade-plugin</artifactId>
                    <version>2.4.3</version>
                    <executions>
                        <execution>
                            <phase>package</phase>
                            <goals>
                                <goal>shade</goal>
                            </goals>
                            <configuration>
                                <filters>
                                    <filter>
                                        <artifact>*:*</artifact>
                                        <!--过滤掉一下类型的文件,避免在服务器端运行出现签名问题-->
                                        <excludes>
                                            <exclude>META-INF/*.SF</exclude>
                                            <exclude>META-INF/*.DSA</exclude>
                                            <exclude>META-INF/*.RSA</exclude>
                                        </excludes>
                                    </filter>
                                </filters>
                                <transformers>
                                    <transformer
                                            implementation="org.apache.maven.plugins.shade.resource.AppendingTransformer">
                                        <resource>META-INF/spring.handlers</resource>
                                    </transformer>
                                    <transformer
                                            implementation="org.apache.maven.plugins.shade.resource.AppendingTransformer">
                                        <resource>META-INF/spring.schemas</resource>
                                    </transformer>
                                </transformers>
                            </configuration>
                        </execution>
                    </executions>
                </plugin>
                <plugin>
                    <groupId>org.apache.maven.plugins</groupId>
                    <artifactId>maven-compiler-plugin</artifactId>
                    <configuration>
                        <source>1.7</source>
                        <target>1.7</target>
                    </configuration>
                </plugin>
            </plugins>
        </build>

        <repositories>
             <repository>
                 <id>public</id>
                 <url>${repo.url}/nexus/content/groups/public/</url>
                 <name>chaosdata Repository</name>
                 <snapshots>
                     <enabled>true</enabled>
                 </snapshots>
             </repository>
             <repository>
                 <id>local-central</id>
                 <url>${repo.url}/nexus/content/groups/public</url>
                 <releases>
                     <enabled>true</enabled>
                 </releases>
                 <snapshots>
                     <enabled>true</enabled>
                 </snapshots>
             </repository>
             <repository>
                 <id>chaos-coms-3rd</id>
                 <url>${repo.url}/nexus/content/groups/public</url>
             </repository>
             <repository>
                 <id>chaos-coms-snapshots</id>
                 <url>${repo.url}/nexus/content/groups/public</url>
             </repository>
             <repository>
                 <id>chaos-coms-release</id>
                 <url>${repo.url}/nexus/content/groups/public/</url>
             </repository>
         </repositories>

        <pluginRepositories>
             <pluginRepository>
                 <id>central</id>
                 <url>${repo.url}/nexus/content/groups/public/</url>
                 <releases>
                     <enabled>true</enabled>
                 </releases>
                 <snapshots>
                     <enabled>false</enabled>
                 </snapshots>
             </pluginRepository>
         </pluginRepositories>
    ```

### 代码
#### RandomValue
``` java
import java.util.HashMap;
import java.util.Map;

public class RandomValue {
    public static String base = "abcdefghijklmnopqrstuvwxyz0123456789";
    private static String firstName = "赵钱孙李周吴郑王冯陈褚卫蒋沈韩杨朱秦尤许何吕施张孔曹严华金魏陶姜戚谢邹喻柏水窦章云苏潘葛奚范彭郎鲁韦昌马苗凤花方俞任袁柳酆鲍史唐费廉岑薛雷贺倪汤滕殷罗毕郝邬安常乐于时傅皮卞齐康伍余元卜顾孟平黄和穆萧尹姚邵湛汪祁毛禹狄米贝明臧计伏成戴谈宋茅庞熊纪舒屈项祝董梁杜阮蓝闵席季麻强贾路娄危江童颜郭梅盛林刁钟徐邱骆高夏蔡田樊胡凌霍虞万支柯咎管卢莫经房裘缪干解应宗宣丁贲邓郁单杭洪包诸左石崔吉钮龚程嵇邢滑裴陆荣翁荀羊於惠甄魏加封芮羿储靳汲邴糜松井段富巫乌焦巴弓牧隗山谷车侯宓蓬全郗班仰秋仲伊宫宁仇栾暴甘钭厉戎祖武符刘姜詹束龙叶幸司韶郜黎蓟薄印宿白怀蒲台从鄂索咸籍赖卓蔺屠蒙池乔阴郁胥能苍双闻莘党翟谭贡劳逄姬申扶堵冉宰郦雍却璩桑桂濮牛寿通边扈燕冀郏浦尚农温别庄晏柴瞿阎充慕连茹习宦艾鱼容向古易慎戈廖庚终暨居衡步都耿满弘匡国文寇广禄阙东殴殳沃利蔚越夔隆师巩厍聂晁勾敖融冷訾辛阚那简饶空曾毋沙乜养鞠须丰巢关蒯相查后江红游竺权逯盖益桓公万俟司马上官欧阳夏侯诸葛闻人东方赫连皇甫尉迟公羊澹台公冶宗政濮阳淳于仲孙太叔申屠公孙乐正轩辕令狐钟离闾丘长孙慕容鲜于宇文司徒司空亓官司寇仉督子车颛孙端木巫马公西漆雕乐正壤驷公良拓拔夹谷宰父谷粱晋楚阎法汝鄢涂钦段干百里东郭南门呼延归海羊舌微生岳帅缑亢况后有琴梁丘左丘东门西门商牟佘佴伯赏南宫墨哈谯笪年爱阳佟第五言福百家姓续";
    private static String girl = "秀娟英华慧巧美娜静淑惠珠翠雅芝玉萍红娥玲芬芳燕彩春菊兰凤洁梅琳素云莲真环雪荣爱妹霞香月莺媛艳瑞凡佳嘉琼勤珍贞莉桂娣叶璧璐娅琦晶妍茜秋珊莎锦黛青倩婷姣婉娴瑾颖露瑶怡婵雁蓓纨仪荷丹蓉眉君琴蕊薇菁梦岚苑婕馨瑗琰韵融园艺咏卿聪澜纯毓悦昭冰爽琬茗羽希宁欣飘育滢馥筠柔竹霭凝晓欢霄枫芸菲寒伊亚宜可姬舒影荔枝思丽 ";
    private static String boy = "伟刚勇毅俊峰强军平保东文辉力明永健世广志义兴良海山仁波宁贵福生龙元全国胜学祥才发武新利清飞彬富顺信子杰涛昌成康星光天达安岩中茂进林有坚和彪博诚先敬震振壮会思群豪心邦承乐绍功松善厚庆磊民友裕河哲江超浩亮政谦亨奇固之轮翰朗伯宏言若鸣朋斌梁栋维启克伦翔旭鹏泽晨辰士以建家致树炎德行时泰盛雄琛钧冠策腾楠榕风航弘";
    private static String[] road = "重庆大厦,黑龙江路,十梅庵街,遵义路,湘潭街,瑞金广场,仙山街,仙山东路,仙山西大厦,白沙河路,赵红广场,机场路,民航街,长城南路,流亭立交桥,虹桥广场,长城大厦,礼阳路,风岗街,中川路,白塔广场,兴阳路,文阳街,绣城路,河城大厦,锦城广场,崇阳街,华城路,康城街,正阳路,和阳广场,中城路,江城大厦,顺城路,安城街,山城广场,春城街,国城路,泰城街,德阳路,明阳大厦,春阳路,艳阳街,秋阳路,硕阳街,青威高速,瑞阳街,丰海路,双元大厦,惜福镇街道,夏庄街道,古庙工业园,中山街,太平路,广西街,潍县广场,博山大厦,湖南路,济宁街,芝罘路,易州广场,荷泽四路,荷泽二街,荷泽一路,荷泽三大厦,观海二广场,广西支街,观海一路,济宁支街,莒县路,平度广场,明水路,蒙阴大厦,青岛路,湖北街,江宁广场,郯城街,天津路,保定街,安徽路,河北大厦,黄岛路,北京街,莘县路,济南街,宁阳广场,日照街,德县路,新泰大厦,荷泽路,山西广场,沂水路,肥城街,兰山路,四方街,平原广场,泗水大厦,浙江路,曲阜街,寿康路,河南广场,泰安路,大沽街,红山峡支路,西陵峡一大厦,台西纬一广场,台西纬四街,台西纬二路,西陵峡二街,西陵峡三路,台西纬三广场,台西纬五路,明月峡大厦,青铜峡路,台西二街,观音峡广场,瞿塘峡街,团岛二路,团岛一街,台西三路,台西一大厦,郓城南路,团岛三街,刘家峡路,西藏二街,西藏一广场,台西四街,三门峡路,城武支大厦,红山峡路,郓城北广场,龙羊峡路,西陵峡街,台西五路,团岛四街,石村广场,巫峡大厦,四川路,寿张街,嘉祥路,南村广场,范县路,西康街,云南路,巨野大厦,西江广场,鱼台街,单县路,定陶街,滕县路,钜野广场,观城路,汶上大厦,朝城路,滋阳街,邹县广场,濮县街,磁山路,汶水街,西藏路,城武大厦,团岛路,南阳街,广州路,东平街,枣庄广场,贵州街,费县路,南海大厦,登州路,文登广场,信号山支路,延安一街,信号山路,兴安支街,福山支广场,红岛支大厦,莱芜二路,吴县一街,金口三路,金口一广场,伏龙山路,鱼山支街,观象二路,吴县二大厦,莱芜一广场,金口二街,海阳路,龙口街,恒山路,鱼山广场,掖县路,福山大厦,红岛路,常州街,大学广场,龙华街,齐河路,莱阳街,黄县路,张店大厦,祚山路,苏州街,华山路,伏龙街,江苏广场,龙江街,王村路,琴屿大厦,齐东路,京山广场,龙山路,牟平街,延安三路,延吉街,南京广场,东海东大厦,银川西路,海口街,山东路,绍兴广场,芝泉路,东海中街,宁夏路,香港西大厦,隆德广场,扬州街,郧阳路,太平角一街,宁国二支路,太平角二广场,天台东一路,太平角三大厦,漳州路一路,漳州街二街,宁国一支广场,太平角六街,太平角四路,天台东二街,太平角五路,宁国三大厦,澳门三路,江西支街,澳门二路,宁国四街,大尧一广场,咸阳支街,洪泽湖路,吴兴二大厦,澄海三路,天台一广场,新湛二路,三明北街,新湛支路,湛山五街,泰州三广场,湛山四大厦,闽江三路,澳门四街,南海支路,吴兴三广场,三明南路,湛山二街,二轻新村镇,江南大厦,吴兴一广场,珠海二街,嘉峪关路,高邮湖街,湛山三路,澳门六广场,泰州二路,东海一大厦,天台二路,微山湖街,洞庭湖广场,珠海支街,福州南路,澄海二街,泰州四路,香港中大厦,澳门五路,新湛三街,澳门一路,正阳关街,宁武关广场,闽江四街,新湛一路,宁国一大厦,王家麦岛,澳门七广场,泰州一路,泰州六街,大尧二路,青大一街,闽江二广场,闽江一大厦,屏东支路,湛山一街,东海西路,徐家麦岛函谷关广场,大尧三路,晓望支街,秀湛二路,逍遥三大厦,澳门九广场,泰州五街,澄海一路,澳门八街,福州北路,珠海一广场,宁国二路,临淮关大厦,燕儿岛路,紫荆关街,武胜关广场,逍遥一街,秀湛四路,居庸关街,山海关路,鄱阳湖大厦,新湛路,漳州街,仙游路,花莲街,乐清广场,巢湖街,台南路,吴兴大厦,新田路,福清广场,澄海路,莆田街,海游路,镇江街,石岛广场,宜兴大厦,三明路,仰口街,沛县路,漳浦广场,大麦岛,台湾街,天台路,金湖大厦,高雄广场,海江街,岳阳路,善化街,荣成路,澳门广场,武昌路,闽江大厦,台北路,龙岩街,咸阳广场,宁德街,龙泉路,丽水街,海川路,彰化大厦,金田路,泰州街,太湖路,江西街,泰兴广场,青大街,金门路,南通大厦,旌德路,汇泉广场,宁国路,泉州街,如东路,奉化街,鹊山广场,莲岛大厦,华严路,嘉义街,古田路,南平广场,秀湛路,长汀街,湛山路,徐州大厦,丰县广场,汕头街,新竹路,黄海街,安庆路,基隆广场,韶关路,云霄大厦,新安路,仙居街,屏东广场,晓望街,海门路,珠海街,上杭路,永嘉大厦,漳平路,盐城街,新浦路,新昌街,高田广场,市场三街,金乡东路,市场二大厦,上海支路,李村支广场,惠民南路,市场纬街,长安南路,陵县支街,冠县支广场,小港一大厦,市场一路,小港二街,清平路,广东广场,新疆路,博平街,港通路,小港沿,福建广场,高唐街,茌平路,港青街,高密路,阳谷广场,平阴路,夏津大厦,邱县路,渤海街,恩县广场,旅顺街,堂邑路,李村街,即墨路,港华大厦,港环路,馆陶街,普集路,朝阳街,甘肃广场,港夏街,港联路,陵县大厦,上海路,宝山广场,武定路,长清街,长安路,惠民街,武城广场,聊城大厦,海泊路,沧口街,宁波路,胶州广场,莱州路,招远街,冠县路,六码头,金乡广场,禹城街,临清路,东阿街,吴淞路,大港沿,辽宁路,棣纬二大厦,大港纬一路,贮水山支街,无棣纬一广场,大港纬三街,大港纬五路,大港纬四街,大港纬二路,无棣二大厦,吉林支路,大港四街,普集支路,无棣三街,黄台支广场,大港三街,无棣一路,贮水山大厦,泰山支路,大港一广场,无棣四路,大连支街,大港二路,锦州支街,德平广场,高苑大厦,长山路,乐陵街,临邑路,嫩江广场,合江路,大连街,博兴路,蒲台大厦,黄台广场,城阳街,临淄路,安邱街,临朐路,青城广场,商河路,热河大厦,济阳路,承德街,淄川广场,辽北街,阳信路,益都街,松江路,流亭大厦,吉林路,恒台街,包头路,无棣街,铁山广场,锦州街,桓台路,兴安大厦,邹平路,胶东广场,章丘路,丹东街,华阳路,青海街,泰山广场,周村大厦,四平路,台东西七街,台东东二路,台东东七广场,台东西二路,东五街,云门二路,芙蓉山村,延安二广场,云门一街,台东四路,台东一街,台东二路,杭州支广场,内蒙古路,台东七大厦,台东六路,广饶支街,台东八广场,台东三街,四平支路,郭口东街,青海支路,沈阳支大厦,菜市二路,菜市一街,北仲三路,瑞云街,滨县广场,庆祥街,万寿路,大成大厦,芙蓉路,历城广场,大名路,昌平街,平定路,长兴街,浦口广场,诸城大厦,和兴路,德盛街,宁海路,威海广场,东山路,清和街,姜沟路,雒口大厦,松山广场,长春街,昆明路,顺兴街,利津路,阳明广场,人和路,郭口大厦,营口路,昌邑街,孟庄广场,丰盛街,埕口路,丹阳街,汉口路,洮南大厦,桑梓路,沾化街,山口路,沈阳街,南口广场,振兴街,通化路,福寺大厦,峄县路,寿光广场,曹县路,昌乐街,道口路,南九水街,台湛广场,东光大厦,驼峰路,太平山,标山路,云溪广场,太清路".split(",");
    private static final String[] email_suffix = "@gmail.com,@yahoo.com,@msn.com,@hotmail.com,@aol.com,@ask.com,@live.com,@qq.com,@0355.net,@163.com,@163.net,@263.net,@3721.net,@yeah.net,@googlemail.com,@126.com,@sina.com,@sohu.com,@yahoo.com.cn".split(",");

    public static int getNum(int start, int end) {
        return (int) (Math.random() * (end - start + 1) + start);
    }

    /**
     * 返回Email
     *
     * @param lMin 最小长度
     * @param lMax 最大长度
     * @return
     */
    public static String getEmail(int lMin, int lMax) {
        int length = getNum(lMin, lMax);
        StringBuffer sb = new StringBuffer();
        for (int i = 0; i < length; i++) {
            int number = (int) (Math.random() * base.length());
            sb.append(base.charAt(number));
        }
        sb.append(email_suffix[(int) (Math.random() * email_suffix.length)]);
        return sb.toString();
    }

    /**
     * 返回手机号码
     */
    private static String[] telFirst = "134,135,136,137,138,139,150,151,152,157,158,159,130,131,132,155,156,133,153".split(",");

    private static String getTel() {
        int index = getNum(0, telFirst.length - 1);
        String first = telFirst[index];
        String second = String.valueOf(getNum(1, 888) + 10000).substring(1);
        String third = String.valueOf(getNum(1, 9100) + 10000).substring(1);
        return first + second + third;
    }

    /**
     * 返回中文姓名
     */
    public static String name_sex = "";

    public static String getChineseName() {
        int index = getNum(0, firstName.length() - 1);
        String first = firstName.substring(index, index + 1);
        int sex = getNum(0, 1);
        String str = boy;
        int length = boy.length();
        if (sex == 0) {
            str = girl;
            length = girl.length();
            name_sex = "女";
        } else {
            name_sex = "男";
        }
        index = getNum(0, length - 1);
        String second = str.substring(index, index + 1);
        int hasThird = getNum(0, 1);
        String third = "";
        if (hasThird == 1) {
            index = getNum(0, length - 1);
            third = str.substring(index, index + 1);
        }
        return first + second + third;
    }

    /**
     * 返回地址
     *
     * @return
     */
    private static String getRoad() {
        int index = getNum(0, road.length - 1);
        String first = road[index];
        String second = String.valueOf(getNum(11, 150)) + "号";
        String third = "-" + getNum(1, 20) + "-" + getNum(1, 10);
        return first + second + third;
    }

    /**
     * 数据封装
     *
     * @return
     */
    public static Map getAddress() {
        Map map = new HashMap();
        map.put("name", getChineseName());
        map.put("sex", name_sex);
        map.put("road", getRoad());
        map.put("tel", getTel());
        map.put("email", getEmail(6, 9));
        return map;
    }

    public static void main(String[] args) {
        for (int i = 0; i < 100; i++) {
            System.out.println(getAddress());
//          System.out.println(getEmailName(6,9));
        }
    }
}
```

#### AvroWriter
``` scala
import java.io.File

import cn.binarywang.tools.generator.{ChineseAddressGenerator, ChineseIDCardNumberGenerator, ChineseMobileNumberGenerator}
import com.chaosdata.Person
import org.apache.avro.Schema
import org.apache.avro.mapred.AvroKey
import org.apache.avro.mapreduce.AvroKeyOutputFormat
import org.apache.hadoop.conf.Configuration
import org.apache.hadoop.io.NullWritable
import org.apache.spark.sql.types.{StringType, StructField, StructType}
import org.apache.spark.sql.{Row, SQLContext}
import org.apache.spark.{SparkConf, SparkContext}

import scala.collection.mutable.ArrayBuffer

object AvroWriter {

  def genInfos(): (String, String, String, String, String) = {
    (ChineseIDCardNumberGenerator.getInstance.generate, RandomValue.getChineseName, RandomValue.name_sex, ChineseAddressGenerator.getInstance.generate, ChineseMobileNumberGenerator.getInstance.generate)
  }

  def genPerson(id: String, name: String, sex: String, addr: String, phone: String): Person = {
    val person = new Person()

    person.setId(id)
    person.setName(name)
    person.setSex(sex)
    person.setAddr(addr)
    person.setPhone(phone)

    person
  }

  def main(args: Array[String]): Unit = {
    val conf = new SparkConf().setAppName(this.getClass.getSimpleName).setMaster("local")
    val sc = new SparkContext(conf)
    val ssc = new SQLContext(sc)

    //    text(sc, ssc)
    //    avro(sc, ssc)
    parquet(sc, ssc)

    sc.stop()
  }

  def text(sc: SparkContext, ssc: SQLContext): Unit = {
    for (j <- 1 to 1) {
      val bufer = new ArrayBuffer[(String, String, String, String, String)]()

      for (i <- (1 to 1000000)) {
        bufer.+=(genInfos)
      }

      import ssc.implicits._
      val df = sc.parallelize(bufer).map(infos => Array(infos).mkString("\t\t")).toDF
      df.write.text("file:///F:\\datacenter\\output\\env\\text\\" + System.currentTimeMillis())
    }

    ssc.clearCache()
  }

  def avro(sc: SparkContext, ssc: SQLContext): Unit = {
    for (j <- 1 to 1) {
      val bufer = new ArrayBuffer[(String, String, String, String, String)]()

      for (i <- (1 to 1000000)) {
        bufer.+=(genInfos)
      }

      val schema = new Schema.Parser().parse(new File("F:\\datacenter\\struct\\avro\\schema\\person.avsc"))
      val conf = new Configuration()
      conf.set("avro.schema.output.key", schema.toString)
      val rdd = sc.parallelize(bufer).map(infos => (new AvroKey(genPerson(infos._1, infos._2, infos._3, infos._4, infos._5)), null))
        .saveAsNewAPIHadoopFile("file:///F:\\datacenter\\output\\env\\avro\\" + System.currentTimeMillis(), classOf[Person], classOf[NullWritable], classOf[AvroKeyOutputFormat[Person]], conf)
    }

    ssc.clearCache()
  }

  def parquet(sc: SparkContext, ssc: SQLContext): Unit = {
    val df = ssc.read
      .format("com.databricks.spark.avro")
      .load("file:///F:\\datacenter\\output\\env\\avro\\*")

    val struct = StructType(Array(
      StructField("row", StructType(Array(
        StructField("id", StringType, true),
        StructField("name", StringType, true),
        StructField("sex", StringType, true),
        StructField("addr", StringType, true),
        StructField("phone", StringType, true))), true),
      StructField("id", StringType, true),
      StructField("name", StringType, true)
    ))

    val df1 = ssc.createDataFrame(df.rdd.map(row => Row(row, row.getAs("id"), row.getAs("name"))), struct)
    df1.printSchema()

    df1.write
      .parquet("file:///F:\\datacenter\\output\\env\\parquet\\" + System.currentTimeMillis())
  }
}
```


#### AvroUtils
``` scala
import org.apache.avro.Protocol;
import org.apache.avro.Schema;
import java.io.File;
import java.io.IOException;

public class AvroUtils {
    public static void main(String[] args) {
        try {
            protocol2class("F:\\datacenter\\struct\\avro\\schema\\example.avdl");
        } catch (IOException e) {
            e.printStackTrace();
        }
        try {
            schema2class("F:\\datacenter\\struct\\avro\\schema\\person.avsc");
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public static void schema2class(String path) throws IOException {
        Schema.Parser parser = new Schema.Parser();
        File src = new File(path);
        Schema schema = parser.parse(src);
        SpecificCompiler compiler = new SpecificCompiler(schema);
        compiler.compileToDestination(src, new File("F:\\datacenter\\struct\\avro"));
    }

    public static void protocol2class(String path) throws IOException {
        Schema.Parser parser = new Schema.Parser();
        File src = new File(path);
        Protocol protocol = Protocol.parse(src);
        SpecificCompiler compiler = new SpecificCompiler(protocol);
        compiler.compileToDestination(src, new File("F:\\datacenter\\struct\\avro"));
    }
}
```

#### scahme
##### avro schema
``` shell
{"namespace": "com.chaosdata",
 "type": "record",
 "name": "Person",
 "fields": [
    {"name": "id", "type": "string"},
    {"name": "name",  "type": "string"},
    {"name": "sex",  "type": "string"},
    {"name": "addr",  "type": "string"},
    {"name": "phone",  "type": "string"}
 ]
}
```

## Motivation

We created Parquet to make the advantages of compressed, efficient columnar data representation available to any project in the Hadoop ecosystem.

Parquet is built from the ground up with complex nested data structures in mind, and uses the [record shredding and assembly algorithm](https://github.com/Parquet/parquet-mr/wiki/The-striping-and-assembly-algorithms-from-the-Dremel-paper) described in the Dremel paper. We believe this approach is superior to simple flattening of nested name spaces.

Parquet is built to support very efficient compression and encoding schemes. Multiple projects have demonstrated the performance impact of applying the right compression and encoding scheme to the data. Parquet allows compression schemes to be specified on a per-column level, and is future-proofed to allow adding more encodings as they are invented and implemented.

Parquet is built to be used by anyone. The Hadoop ecosystem is rich with data processing frameworks, and we are not interested in playing favorites. We believe that an efficient, well-implemented columnar storage substrate should be useful to all frameworks without the cost of extensive and difficult to set up dependencies.

## Modules

The `parquet-format` project contains format specifications and Thrift definitions of metadata required to properly read Parquet files.

The `parquet-mr` project contains multiple sub-modules, which implement the core components of reading and writing a nested, column-oriented data stream, map this core onto the parquet format, and provide Hadoop Input/Output Formats, Pig loaders, and other java-based utilities for interacting with Parquet.

The `parquet-compatibility` project contains compatibility tests that can be used to verify that implementations in different languages can read and write each other's files.

## Building

Java resources can be build using `mvn package`. The current stable version should always be available from Maven Central.

C++ thrift resources can be generated via make.

Thrift can be also code-genned into any other thrift-supported language.

## Glossary
  - Block (HDFS block): This means a block in HDFS and the meaning is
    unchanged for describing this file format.  The file format is
    designed to work well on top of HDFS.

  - File: A HDFS file that must include the metadata for the file.
    It does not need to actually contain the data.

  - Row group: A logical horizontal partitioning of the data into rows.
    There is no physical structure that is guaranteed for a row group.
    A row group consists of a column chunk for each column in the dataset.

  - Column chunk: A chunk of the data for a particular column.  They live
    in a particular row group and are guaranteed to be contiguous in the file.

  - Page: Column chunks are divided up into pages.  A page is conceptually
    an indivisible unit (in terms of compression and encoding).  There can
    be multiple page types which are interleaved in a column chunk.

Hierarchically, a file consists of one or more row groups.  A row group
contains exactly one column chunk per column.  Column chunks contain one or
more pages.

## Unit of parallelization
  - MapReduce - File/Row Group
  - IO - Column chunk
  - Encoding/Compression - Page

## File format
This file and the [thrift definition](#parquet.thrift) should be read together to understand the format.

    4-byte magic number "PAR1"
    <Column 1 Chunk 1 + Column Metadata>
    <Column 2 Chunk 1 + Column Metadata>
    ...
    <Column N Chunk 1 + Column Metadata>
    <Column 1 Chunk 2 + Column Metadata>
    <Column 2 Chunk 2 + Column Metadata>
    ...
    <Column N Chunk 2 + Column Metadata>
    ...
    <Column 1 Chunk M + Column Metadata>
    <Column 2 Chunk M + Column Metadata>
    ...
    <Column N Chunk M + Column Metadata>
    File Metadata
    4-byte length in bytes of file metadata (little endian)
    4-byte magic number "PAR1"

In the above example, there are N columns in this table, split into M row
groups.  The file metadata contains the locations of all the column metadata
start locations.  More details on what is contained in the metadata can be found
in the thrift definition.

Metadata is written after the data to allow for single pass writing.

Readers are expected to first read the file metadata to find all the column
chunks they are interested in.  The columns chunks should then be read sequentially.

 ![File Layout](https://raw.github.com/Parquet/parquet-format/master/doc/images/FileLayout.gif)

## Metadata
There are three types of metadata: file metadata, column (chunk) metadata and page
header metadata.  All thrift structures are serialized using the TCompactProtocol.

 ![Metadata diagram](https://github.com/Parquet/parquet-format/raw/master/doc/images/FileFormat.gif)

## Types
The types supported by the file format are intended to be as minimal as possible,
with a focus on how the types effect on disk storage.  For example, 16-bit ints
are not explicitly supported in the storage format since they are covered by
32-bit ints with an efficient encoding.  This reduces the complexity of implementing
readers and writers for the format.  The types are:
  - BOOLEAN: 1 bit boolean
  - INT32: 32 bit signed ints
  - INT64: 64 bit signed ints
  - INT96: 96 bit signed ints
  - FLOAT: IEEE 32-bit floating point values
  - DOUBLE: IEEE 64-bit floating point values
  - BYTE_ARRAY: arbitrarily long byte arrays.

### Logical Types
Logical types are used to extend the types that parquet can be used to store,
by specifying how the primitive types should be interpreted. This keeps the set
of primitive types to a minimum and reuses parquet's efficient encodings. For
example, strings are stored as byte arrays (binary) with a UTF8 annotation.
These annotations define how to further decode and interpret the data.
Annotations are stored as `ConvertedType` fields in the file metadata and are
documented in
[LogicalTypes.md](#logic.type)

## Nested Encoding
To encode nested columns, Parquet uses the Dremel encoding with definition and
repetition levels.  Definition levels specify how many optional fields in the
path for the column are defined.  Repetition levels specify at what repeated field
in the path has the value repeated.  The max definition and repetition levels can
be computed from the schema (i.e. how much nesting there is).  This defines the
maximum number of bits required to store the levels (levels are defined for all
values in the column).

Two encodings for the levels are supported BIT_PACKED and RLE. Only RLE is now used as it supersedes BIT_PACKED.

## Nulls
Nullity is encoded in the definition levels (which is run-length encoded).  NULL values
are not encoded in the data.  For example, in a non-nested schema, a column with 1000 NULLs
would be encoded with run-length encoding (0, 1000 times) for the definition levels and
nothing else.

## Data Pages
For data pages, the 3 pieces of information are encoded back to back, after the page
header.  We have the
 - repetition levels data,
 - definition levels data,
 - encoded values.

The value of `uncompressed_page_size` specified in the header is for all 3 pieces combined.

The data for the data page is always required.  The definition and repetition levels
are optional, based on the schema definition.  If the column is not nested (i.e.
the path to the column has length 1), we do not encode the repetition levels (it would
always have the value 1).  For data that is required, the definition levels are
skipped (if encoded, it will always have the value of the max definition level).

For example, in the case where the column is non-nested and required, the data in the
page is only the encoded values.

The supported encodings are described in [Encodings.md](https://github.com/Parquet/parquet-format/blob/master/Encodings.md)

## Column chunks
Column chunks are composed of pages written back to back.  The pages share a common
header and readers can skip over pages they are not interested in.  The data for the
page follows the header and can be compressed and/or encoded.  The compression and
encoding is specified in the page metadata.

## Checksumming
Data pages can be individually checksummed.  This allows disabling of checksums at the
HDFS file level, to better support single row lookups.

## Error recovery
If the file metadata is corrupt, the file is lost.  If the column metadata is corrupt,
that column chunk is lost (but column chunks for this column in other row groups are
okay).  If a page header is corrupt, the remaining pages in that chunk are lost.  If
the data within a page is corrupt, that page is lost.  The file will be more
resilient to corruption with smaller row groups.

Potential extension: With smaller row groups, the biggest issue is placing the file
metadata at the end.  If an error happens while writing the file metadata, all the
data written will be unreadable.  This can be fixed by writing the file metadata
every Nth row group.
Each file metadata would be cumulative and include all the row groups written so
far.  Combining this with the strategy used for rc or avro files using sync markers,
a reader could recover partially written files.

## Separating metadata and column data.
The format is explicitly designed to separate the metadata from the data.  This
allows splitting columns into multiple files, as well as having a single metadata
file reference multiple parquet files.

## Configurations
- Row group size: Larger row groups allow for larger column chunks which makes it
possible to do larger sequential IO.  Larger groups also require more buffering in
the write path (or a two pass write).  We recommend large row groups (512MB - 1GB).
Since an entire row group might need to be read, we want it to completely fit on
one HDFS block.  Therefore, HDFS block sizes should also be set to be larger.  An
optimized read setup would be: 1GB row groups, 1GB HDFS block size, 1 HDFS block
per HDFS file.
- Data page size: Data pages should be considered indivisible so smaller data pages
allow for more fine grained reading (e.g. single row lookup).  Larger page sizes
incur less space overhead (less page headers) and potentially less parsing overhead
(processing headers).  Note: for sequential scans, it is not expected to read a page
at a time; this is not the IO chunk.  We recommend 8KB for page sizes.

## Extensibility
There are many places in the format for compatible extensions:
- File Version: The file metadata contains a version.
- Encodings: Encodings are specified by enum and more can be added in the future.
- Page types: Additional page types can be added and safely skipped.

<span id = "parquet.thrift">parquet.thrift：</span>
``` thrift
/**
 * File format description for the parquet file format
 */
namespace cpp parquet
namespace java org.apache.parquet.format

/**
 * Types supported by Parquet.  These types are intended to be used in combination
 * with the encodings to control the on disk storage format.
 * For example INT16 is not included as a type since a good encoding of INT32
 * would handle this.
 *
 * When a logical type is not present, the type-defined sort order of these
 * physical types are:
 * * BOOLEAN - false, true
 * * INT32 - signed comparison
 * * INT64 - signed comparison
 * * INT96 - signed comparison
 * * FLOAT - signed comparison
 * * DOUBLE - signed comparison
 * * BYTE_ARRAY - unsigned byte-wise comparison
 * * FIXED_LEN_BYTE_ARRAY - unsigned byte-wise comparison
 */
enum Type {
  BOOLEAN = 0;
  INT32 = 1;
  INT64 = 2;
  INT96 = 3;
  FLOAT = 4;
  DOUBLE = 5;
  BYTE_ARRAY = 6;
  FIXED_LEN_BYTE_ARRAY = 7;
}

/**
 * Common types used by frameworks(e.g. hive, pig) using parquet.  This helps map
 * between types in those frameworks to the base types in parquet.  This is only
 * metadata and not needed to read or write the data.
 */
enum ConvertedType {
  /** a BYTE_ARRAY actually contains UTF8 encoded chars */
  UTF8 = 0;

  /** a map is converted as an optional field containing a repeated key/value pair */
  MAP = 1;

  /** a key/value pair is converted into a group of two fields */
  MAP_KEY_VALUE = 2;

  /** a list is converted into an optional field containing a repeated field for its
   * values */
  LIST = 3;

  /** an enum is converted into a binary field */
  ENUM = 4;

  /**
   * A decimal value.
   *
   * This may be used to annotate binary or fixed primitive types. The
   * underlying byte array stores the unscaled value encoded as two's
   * complement using big-endian byte order (the most significant byte is the
   * zeroth element). The value of the decimal is the value * 10^{-scale}.
   *
   * This must be accompanied by a (maximum) precision and a scale in the
   * SchemaElement. The precision specifies the number of digits in the decimal
   * and the scale stores the location of the decimal point. For example 1.23
   * would have precision 3 (3 total digits) and scale 2 (the decimal point is
   * 2 digits over).
   */
  DECIMAL = 5;

  /**
   * A Date
   *
   * Stored as days since Unix epoch, encoded as the INT32 physical type.
   *
   */
  DATE = 6;

  /**
   * A time
   *
   * The total number of milliseconds since midnight.  The value is stored
   * as an INT32 physical type.
   */
  TIME_MILLIS = 7;

  /**
   * A time.
   *
   * The total number of microseconds since midnight.  The value is stored as
   * an INT64 physical type.
   */
  TIME_MICROS = 8;

  /**
   * A date/time combination
   *
   * Date and time recorded as milliseconds since the Unix epoch.  Recorded as
   * a physical type of INT64.
   */
  TIMESTAMP_MILLIS = 9;

  /**
   * A date/time combination
   *
   * Date and time recorded as microseconds since the Unix epoch.  The value is
   * stored as an INT64 physical type.
   */
  TIMESTAMP_MICROS = 10;


  /**
   * An unsigned integer value.
   *
   * The number describes the maximum number of meainful data bits in
   * the stored value. 8, 16 and 32 bit values are stored using the
   * INT32 physical type.  64 bit values are stored using the INT64
   * physical type.
   *
   */
  UINT_8 = 11;
  UINT_16 = 12;
  UINT_32 = 13;
  UINT_64 = 14;

  /**
   * A signed integer value.
   *
   * The number describes the maximum number of meainful data bits in
   * the stored value. 8, 16 and 32 bit values are stored using the
   * INT32 physical type.  64 bit values are stored using the INT64
   * physical type.
   *
   */
  INT_8 = 15;
  INT_16 = 16;
  INT_32 = 17;
  INT_64 = 18;

  /**
   * An embedded JSON document
   *
   * A JSON document embedded within a single UTF8 column.
   */
  JSON = 19;

  /**
   * An embedded BSON document
   *
   * A BSON document embedded within a single BINARY column.
   */
  BSON = 20;

  /**
   * An interval of time
   *
   * This type annotates data stored as a FIXED_LEN_BYTE_ARRAY of length 12
   * This data is composed of three separate little endian unsigned
   * integers.  Each stores a component of a duration of time.  The first
   * integer identifies the number of months associated with the duration,
   * the second identifies the number of days associated with the duration
   * and the third identifies the number of milliseconds associated with
   * the provided duration.  This duration of time is independent of any
   * particular timezone or date.
   */
  INTERVAL = 21;

  /**
   * Annotates a column that is always null
   * Sometimes when discovering the schema of existing data
   * values are always null
   */
  NULL = 25;
}

/**
 * Representation of Schemas
 */
enum FieldRepetitionType {
  /** This field is required (can not be null) and each record has exactly 1 value. */
  REQUIRED = 0;

  /** The field is optional (can be null) and each record has 0 or 1 values. */
  OPTIONAL = 1;

  /** The field is repeated and can contain 0 or more values */
  REPEATED = 2;
}

/**
 * Statistics per row group and per page
 * All fields are optional.
 */
struct Statistics {
   /**
    * DEPRECATED: min and max value of the column. Use min_value and max_value.
    *
    * Values are encoded using PLAIN encoding, except that variable-length byte
    * arrays do not include a length prefix.
    *
    * These fields encode min and max values determined by SIGNED comparison
    * only. New files should use the correct order for a column's logical type
    * and store the values in the min_value and max_value fields.
    *
    * To support older readers, these may be set when the column order is
    * SIGNED.
    */
   1: optional binary max;
   2: optional binary min;
   /** count of null value in the column */
   3: optional i64 null_count;
   /** count of distinct values occurring */
   4: optional i64 distinct_count;
   /**
    * Min and max values for the column, determined by its ColumnOrder.
    *
    * Values are encoded using PLAIN encoding, except that variable-length byte
    * arrays do not include a length prefix.
    */
   5: optional binary max_value;
   6: optional binary min_value;
}

/**
 * Represents a element inside a schema definition.
 *  - if it is a group (inner node) then type is undefined and num_children is defined
 *  - if it is a primitive type (leaf) then type is defined and num_children is undefined
 * the nodes are listed in depth first traversal order.
 */
struct SchemaElement {
  /** Data type for this field. Not set if the current element is a non-leaf node */
  1: optional Type type;

  /** If type is FIXED_LEN_BYTE_ARRAY, this is the byte length of the vales.
   * Otherwise, if specified, this is the maximum bit length to store any of the values.
   * (e.g. a low cardinality INT col could have this set to 3).  Note that this is
   * in the schema, and therefore fixed for the entire file.
   */
  2: optional i32 type_length;

  /** repetition of the field. The root of the schema does not have a repetition_type.
   * All other nodes must have one */
  3: optional FieldRepetitionType repetition_type;

  /** Name of the field in the schema */
  4: required string name;

  /** Nested fields.  Since thrift does not support nested fields,
   * the nesting is flattened to a single list by a depth-first traversal.
   * The children count is used to construct the nested relationship.
   * This field is not set when the element is a primitive type
   */
  5: optional i32 num_children;

  /** When the schema is the result of a conversion from another model
   * Used to record the original type to help with cross conversion.
   */
  6: optional ConvertedType converted_type;

  /** Used when this column contains decimal data.
   * See the DECIMAL converted type for more details.
   */
  7: optional i32 scale
  8: optional i32 precision

  /** When the original schema supports field ids, this will save the
   * original field id in the parquet schema
   */
  9: optional i32 field_id;

}

/**
 * Encodings supported by Parquet.  Not all encodings are valid for all types.  These
 * enums are also used to specify the encoding of definition and repetition levels.
 * See the accompanying doc for the details of the more complicated encodings.
 */
enum Encoding {
  /** Default encoding.
   * BOOLEAN - 1 bit per value. 0 is false; 1 is true.
   * INT32 - 4 bytes per value.  Stored as little-endian.
   * INT64 - 8 bytes per value.  Stored as little-endian.
   * FLOAT - 4 bytes per value.  IEEE. Stored as little-endian.
   * DOUBLE - 8 bytes per value.  IEEE. Stored as little-endian.
   * BYTE_ARRAY - 4 byte length stored as little endian, followed by bytes.
   * FIXED_LEN_BYTE_ARRAY - Just the bytes.
   */
  PLAIN = 0;

  /** Group VarInt encoding for INT32/INT64.
   * This encoding is deprecated. It was never used
   */
  //  GROUP_VAR_INT = 1;

  /**
   * Deprecated: Dictionary encoding. The values in the dictionary are encoded in the
   * plain type.
   * in a data page use RLE_DICTIONARY instead.
   * in a Dictionary page use PLAIN instead
   */
  PLAIN_DICTIONARY = 2;

  /** Group packed run length encoding. Usable for definition/reptition levels
   * encoding and Booleans (on one bit: 0 is false; 1 is true.)
   */
  RLE = 3;

  /** Bit packed encoding.  This can only be used if the data has a known max
   * width.  Usable for definition/repetition levels encoding.
   */
  BIT_PACKED = 4;

  /** Delta encoding for integers. This can be used for int columns and works best
   * on sorted data
   */
  DELTA_BINARY_PACKED = 5;

  /** Encoding for byte arrays to separate the length values and the data. The lengths
   * are encoded using DELTA_BINARY_PACKED
   */
  DELTA_LENGTH_BYTE_ARRAY = 6;

  /** Incremental-encoded byte array. Prefix lengths are encoded using DELTA_BINARY_PACKED.
   * Suffixes are stored as delta length byte arrays.
   */
  DELTA_BYTE_ARRAY = 7;

  /** Dictionary encoding: the ids are encoded using the RLE encoding
   */
  RLE_DICTIONARY = 8;
}

/**
 * Supported compression algorithms.
 */
enum CompressionCodec {
  UNCOMPRESSED = 0;
  SNAPPY = 1;
  GZIP = 2;
  LZO = 3;
  BROTLI = 4;
}

enum PageType {
  DATA_PAGE = 0;
  INDEX_PAGE = 1;
  DICTIONARY_PAGE = 2;
  DATA_PAGE_V2 = 3;
}

/** Data page header */
struct DataPageHeader {
  /** Number of values, including NULLs, in this data page. **/
  1: required i32 num_values

  /** Encoding used for this data page **/
  2: required Encoding encoding

  /** Encoding used for definition levels **/
  3: required Encoding definition_level_encoding;

  /** Encoding used for repetition levels **/
  4: required Encoding repetition_level_encoding;

  /** Optional statistics for the data in this page**/
  5: optional Statistics statistics;
}

struct IndexPageHeader {
  /** TODO: **/
}

struct DictionaryPageHeader {
  /** Number of values in the dictionary **/
  1: required i32 num_values;

  /** Encoding using this dictionary page **/
  2: required Encoding encoding

  /** If true, the entries in the dictionary are sorted in ascending order **/
  3: optional bool is_sorted;
}

/**
 * New page format alowing reading levels without decompressing the data
 * Repetition and definition levels are uncompressed
 * The remaining section containing the data is compressed if is_compressed is true
 **/
struct DataPageHeaderV2 {
  /** Number of values, including NULLs, in this data page. **/
  1: required i32 num_values
  /** Number of NULL values, in this data page.
      Number of non-null = num_values - num_nulls which is also the number of values in the data section **/
  2: required i32 num_nulls
  /** Number of rows in this data page. which means pages change on record boundaries (r = 0) **/
  3: required i32 num_rows
  /** Encoding used for data in this page **/
  4: required Encoding encoding

  // repetition levels and definition levels are always using RLE (without size in it)

  /** length of the repetition levels */
  5: required i32 definition_levels_byte_length;
  /** length of the definition levels */
  6: required i32 repetition_levels_byte_length;

  /**  whether the values are compressed.
  Which means the section of the page between
  definition_levels_byte_length + repetition_levels_byte_length + 1 and compressed_page_size (included)
  is compressed with the compression_codec.
  If missing it is considered compressed */
  7: optional bool is_compressed = 1;

  /** optional statistics for this column chunk */
  8: optional Statistics statistics;
}

struct PageHeader {
  /** the type of the page: indicates which of the *_header fields is set **/
  1: required PageType type

  /** Uncompressed page size in bytes (not including this header) **/
  2: required i32 uncompressed_page_size

  /** Compressed page size in bytes (not including this header) **/
  3: required i32 compressed_page_size

  /** 32bit crc for the data below. This allows for disabling checksumming in HDFS
   *  if only a few pages needs to be read
   **/
  4: optional i32 crc

  // Headers for page specific data.  One only will be set.
  5: optional DataPageHeader data_page_header;
  6: optional IndexPageHeader index_page_header;
  7: optional DictionaryPageHeader dictionary_page_header;
  8: optional DataPageHeaderV2 data_page_header_v2;
}

/**
 * Wrapper struct to store key values
 */
 struct KeyValue {
  1: required string key
  2: optional string value
}

/**
 * Wrapper struct to specify sort order
 */
struct SortingColumn {
  /** The column index (in this row group) **/
  1: required i32 column_idx

  /** If true, indicates this column is sorted in descending order. **/
  2: required bool descending

  /** If true, nulls will come before non-null values, otherwise,
   * nulls go at the end. */
  3: required bool nulls_first
}

/**
 * statistics of a given page type and encoding
 */
struct PageEncodingStats {

  /** the page type (data/dic/...) **/
  1: required PageType page_type;

  /** encoding of the page **/
  2: required Encoding encoding;

  /** number of pages of this type with this encoding **/
  3: required i32 count;

}

/**
 * Description for column metadata
 */
struct ColumnMetaData {
  /** Type of this column **/
  1: required Type type

  /** Set of all encodings used for this column. The purpose is to validate
   * whether we can decode those pages. **/
  2: required list<Encoding> encodings

  /** Path in schema **/
  3: required list<string> path_in_schema

  /** Compression codec **/
  4: required CompressionCodec codec

  /** Number of values in this column **/
  5: required i64 num_values

  /** total byte size of all uncompressed pages in this column chunk (including the headers) **/
  6: required i64 total_uncompressed_size

  /** total byte size of all compressed pages in this column chunk (including the headers) **/
  7: required i64 total_compressed_size

  /** Optional key/value metadata **/
  8: optional list<KeyValue> key_value_metadata

  /** Byte offset from beginning of file to first data page **/
  9: required i64 data_page_offset

  /** Byte offset from beginning of file to root index page **/
  10: optional i64 index_page_offset

  /** Byte offset from the beginning of file to first (only) dictionary page **/
  11: optional i64 dictionary_page_offset

  /** optional statistics for this column chunk */
  12: optional Statistics statistics;

  /** Set of all encodings used for pages in this column chunk.
   * This information can be used to determine if all data pages are
   * dictionary encoded for example **/
  13: optional list<PageEncodingStats> encoding_stats;
}

struct ColumnChunk {
  /** File where column data is stored.  If not set, assumed to be same file as
    * metadata.  This path is relative to the current file.
    **/
  1: optional string file_path

  /** Byte offset in file_path to the ColumnMetaData **/
  2: required i64 file_offset

  /** Column metadata for this chunk. This is the same content as what is at
   * file_path/file_offset.  Having it here has it replicated in the file
   * metadata.
   **/
  3: optional ColumnMetaData meta_data
}

struct RowGroup {
  /** Metadata for each column chunk in this row group.
   * This list must have the same order as the SchemaElement list in FileMetaData.
   **/
  1: required list<ColumnChunk> columns

  /** Total byte size of all the uncompressed column data in this row group **/
  2: required i64 total_byte_size

  /** Number of rows in this row group **/
  3: required i64 num_rows

  /** If set, specifies a sort ordering of the rows in this RowGroup.
   * The sorting columns can be a subset of all the columns.
   */
  4: optional list<SortingColumn> sorting_columns
}

/** Empty struct to signal the order defined by the physical or logical type */
struct TypeDefinedOrder {}

/**
 * Union to specify the order used for min, max, and sorting values in a column.
 *
 * Possible values are:
 * * TypeDefinedOrder - the column uses the order defined by its logical or
 *                      physical type (if there is no logical type).
 *
 * If the reader does not support the value of this union, min and max stats
 * for this column should be ignored.
 */
union ColumnOrder {
  1: TypeDefinedOrder TYPE_ORDER;
}

/**
 * Description for file metadata
 */
struct FileMetaData {
  /** Version of this file **/
  1: required i32 version

  /** Parquet schema for this file.  This schema contains metadata for all the columns.
   * The schema is represented as a tree with a single root.  The nodes of the tree
   * are flattened to a list by doing a depth-first traversal.
   * The column metadata contains the path in the schema for that column which can be
   * used to map columns to nodes in the schema.
   * The first element is the root **/
  2: required list<SchemaElement> schema;

  /** Number of rows in this file **/
  3: required i64 num_rows

  /** Row groups in this file **/
  4: required list<RowGroup> row_groups

  /** Optional key/value metadata **/
  5: optional list<KeyValue> key_value_metadata

  /** String for application that wrote this file.  This should be in the format
   * <Application> version <App Version> (build <App Build Hash>).
   * e.g. impala version 1.0 (build 6cf94d29b2b7115df4de2c06e2ab4326d721eb55)
   **/
  6: optional string created_by

  /**
   * Sort order used for each column in this file.
   *
   * If this list is not present, then the order for each column is assumed to
   * be Signed. In addition, min and max values for INTERVAL or DECIMAL stored
   * as fixed or bytes should be ignored.
   */
  7: optional list<ColumnOrder> column_orders;
}
```

<span id = "logic.type"></span>
Parquet Logical Type Definitions
====

Logical types are used to extend the types that parquet can be used to store,
by specifying how the primitive types should be interpreted. This keeps the set
of primitive types to a minimum and reuses parquet's efficient encodings. For
example, strings are stored as byte arrays (binary) with a UTF8 annotation.

This file contains the specification for all logical types.

### Metadata

The parquet format's `ConvertedType` stores the type annotation. The annotation
may require additional metadata fields, as well as rules for those fields.

### UTF8 (Strings)

`UTF8` may only be used to annotate the binary primitive type and indicates
that the byte array should be interpreted as a UTF-8 encoded character string.

The sort order used for `UTF8` strings is `UNSIGNED` byte-wise comparison.

## Numeric Types

### Signed Integers

`INT_8`, `INT_16`, `INT_32`, and `INT_64` annotations can be used to specify
the maximum number of bits in the stored value.  Implementations may use these
annotations to produce smaller in-memory representations when reading data.

If a stored value is larger than the maximum allowed by the annotation, the
behavior is not defined and can be determined by the implementation.
Implementations must not write values that are larger than the annotation
allows.

`INT_8`, `INT_16`, and `INT_32` must annotate an `int32` primitive type and
`INT_64` must annotate an `int64` primitive type. `INT_32` and `INT_64` are
implied by the `int32` and `int64` primitive types if no other annotation is
present and should be considered optional.

The sort order used for signed integer types is `SIGNED`.

### Unsigned Integers

`UINT_8`, `UINT_16`, `UINT_32`, and `UINT_64` annotations can be used to
specify unsigned integer types, along with a maximum number of bits in the
stored value. Implementations may use these annotations to produce smaller
in-memory representations when reading data.

If a stored value is larger than the maximum allowed by the annotation, the
behavior is not defined and can be determined by the implementation.
Implementations must not write values that are larger than the annotation
allows.

`UINT_8`, `UINT_16`, and `UINT_32` must annotate an `int32` primitive type and
`UINT_64` must annotate an `int64` primitive type.

The sort order used for unsigned integer types is `UNSIGNED`.

### DECIMAL

`DECIMAL` annotation represents arbitrary-precision signed decimal numbers of
the form `unscaledValue * 10^(-scale)`.

The primitive type stores an unscaled integer value. For byte arrays, binary
and fixed, the unscaled number must be encoded as two's complement using
big-endian byte order (the most significant byte is the zeroth element). The
scale stores the number of digits of that value that are to the right of the
decimal point, and the precision stores the maximum number of digits supported
in the unscaled value.

If not specified, the scale is 0. Scale must be zero or a positive integer less
than the precision. Precision is required and must be a non-zero positive
integer. A precision too large for the underlying type (see below) is an error.

`DECIMAL` can be used to annotate the following types:
* `int32`: for 1 &lt;= precision &lt;= 9
* `int64`: for 1 &lt;= precision &lt;= 18; precision &lt; 10 will produce a
  warning
* `fixed_len_byte_array`: precision is limited by the array size. Length `n`
  can store &lt;= `floor(log_10(2^(8*n - 1) - 1))` base-10 digits
* `binary`: `precision` is not limited, but is required. The minimum number of
  bytes to store the unscaled value should be used.

A `SchemaElement` with the `DECIMAL` `ConvertedType` must also have both
`scale` and `precision` fields set, even if scale is 0 by default.

The sort order used for `DECIMAL` values is `SIGNED`. The order is equivalent
to signed comparison of decimal values.

If the column uses `int32` or `int64` physical types, then signed comparison of
the integer values produces the correct ordering. If the physical type is
fixed, then the correct ordering can be produced by flipping the
most-significant bit in the first byte and then using unsigned byte-wise
comparison.

## Date/Time Types

### DATE

`DATE` is used to for a logical date type, without a time of day. It must
annotate an `int32` that stores the number of days from the Unix epoch, 1
January 1970.

The sort order used for `DATE` is `SIGNED`.

### TIME\_MILLIS

`TIME_MILLIS` is used for a logical time type with millisecond precision,
without a date. It must annotate an `int32` that stores the number of
milliseconds after midnight.

The sort order used for `TIME\_MILLIS` is `SIGNED`.

### TIME\_MICROS

`TIME_MICROS` is used for a logical time type with microsecond precision,
without a date. It must annotate an `int64` that stores the number of
microseconds after midnight.

The sort order used for `TIME\_MICROS` is `SIGNED`.

### TIMESTAMP\_MILLIS

`TIMESTAMP_MILLIS` is used for a combined logical date and time type, with
millisecond precision. It must annotate an `int64` that stores the number of
milliseconds from the Unix epoch, 00:00:00.000 on 1 January 1970, UTC.

The sort order used for `TIMESTAMP\_MILLIS` is `SIGNED`.

### TIMESTAMP\_MICROS

`TIMESTAMP_MICROS` is used for a combined logical date and time type with
microsecond precision. It must annotate an `int64` that stores the number of
microseconds from the Unix epoch, 00:00:00.000000 on 1 January 1970, UTC.

The sort order used for `TIMESTAMP\_MICROS` is `SIGNED`.

### INTERVAL

`INTERVAL` is used for an interval of time. It must annotate a
`fixed_len_byte_array` of length 12. This array stores three little-endian
unsigned integers that represent durations at different granularities of time.
The first stores a number in months, the second stores a number in days, and
the third stores a number in milliseconds. This representation is independent
of any particular timezone or date.

Each component in this representation is independent of the others. For
example, there is no requirement that a large number of days should be
expressed as a mix of months and days because there is not a constant
conversion from days to months.

The sort order used for `INTERVAL` is `UNSIGNED`, produced by sorting by
the value of months, then days, then milliseconds with unsigned comparison.

## Embedded Types

Embedded types do not have type-specific orderings.

### JSON

`JSON` is used for an embedded JSON document. It must annotate a `binary`
primitive type. The `binary` data is interpreted as a UTF-8 encoded character
string of valid JSON as defined by the [JSON specification][json-spec]

[json-spec]: http://json.org/

### BSON

`BSON` is used for an embedded BSON document. It must annotate a `binary`
primitive type. The `binary` data is interpreted as an encoded BSON document as
defined by the [BSON specification][bson-spec].

[bson-spec]: http://bsonspec.org/spec.html

## Nested Types

This section specifies how `LIST` and `MAP` can be used to encode nested types
by adding group levels around repeated fields that are not present in the data.

This does not affect repeated fields that are not annotated: A repeated field
that is neither contained by a `LIST`- or `MAP`-annotated group nor annotated
by `LIST` or `MAP` should be interpreted as a required list of required
elements where the element type is the type of the field.

Implementations should use either `LIST` and `MAP` annotations _or_ unannotated
repeated fields, but not both. When using the annotations, no unannotated
repeated types are allowed.

### Lists

`LIST` is used to annotate types that should be interpreted as lists.

`LIST` must always annotate a 3-level structure:

```
<list-repetition> group <name> (LIST) {
  repeated group list {
    <element-repetition> <element-type> element;
  }
}
```

* The outer-most level must be a group annotated with `LIST` that contains a
  single field named `list`. The repetition of this level must be either
  `optional` or `required` and determines whether the list is nullable.
* The middle level, named `list`, must be a repeated group with a single
  field named `element`.
* The `element` field encodes the list's element type and repetition. Element
  repetition must be `required` or `optional`.

The following examples demonstrate two of the possible lists of string values.

```
// List<String> (list non-null, elements nullable)
required group my_list (LIST) {
  repeated group list {
    optional binary element (UTF8);
  }
}

// List<String> (list nullable, elements non-null)
optional group my_list (LIST) {
  repeated group list {
    required binary element (UTF8);
  }
}
```

Element types can be nested structures. For example, a list of lists:

```
// List<List<Integer>>
optional group array_of_arrays (LIST) {
  repeated group list {
    required group element (LIST) {
      repeated group list {
        required int32 element;
      }
    }
  }
}
```

#### Backward-compatibility rules

It is required that the repeated group of elements is named `list` and that
its element field is named `element`. However, these names may not be used in
existing data and should not be enforced as errors when reading. For example,
the following field schema should produce a nullable list of non-null strings,
even though the repeated group is named `element`.

```
optional group my_list (LIST) {
  repeated group element {
    required binary str (UTF8);
  };
}
```

Some existing data does not include the inner element layer. For
backward-compatibility, the type of elements in `LIST`-annotated structures
should always be determined by the following rules:

1. If the repeated field is not a group, then its type is the element type and
   elements are required.
2. If the repeated field is a group with multiple fields, then its type is the
   element type and elements are required.
3. If the repeated field is a group with one field and is named either `array`
   or uses the `LIST`-annotated group's name with `_tuple` appended then the
   repeated type is the element type and elements are required.
4. Otherwise, the repeated field's type is the element type with the repeated
   field's repetition.

Examples that can be interpreted using these rules:

```
// List<Integer> (nullable list, non-null elements)
optional group my_list (LIST) {
  repeated int32 element;
}

// List<Tuple<String, Integer>> (nullable list, non-null elements)
optional group my_list (LIST) {
  repeated group element {
    required binary str (UTF8);
    required int32 num;
  };
}

// List<OneTuple<String>> (nullable list, non-null elements)
optional group my_list (LIST) {
  repeated group array {
    required binary str (UTF8);
  };
}

// List<OneTuple<String>> (nullable list, non-null elements)
optional group my_list (LIST) {
  repeated group my_list_tuple {
    required binary str (UTF8);
  };
}
```

### Maps

`MAP` is used to annotate types that should be interpreted as a map from keys
to values. `MAP` must annotate a 3-level structure:

```
<map-repetition> group <name> (MAP) {
  repeated group key_value {
    required <key-type> key;
    <value-repetition> <value-type> value;
  }
}
```

* The outer-most level must be a group annotated with `MAP` that contains a
  single field named `key_value`. The repetition of this level must be either
  `optional` or `required` and determines whether the list is nullable.
* The middle level, named `key_value`, must be a repeated group with a `key`
  field for map keys and, optionally, a `value` field for map values.
* The `key` field encodes the map's key type. This field must have
  repetition `required` and must always be present.
* The `value` field encodes the map's value type and repetition. This field can
  be `required`, `optional`, or omitted.

The following example demonstrates the type for a non-null map from strings to
nullable integers:

```
// Map<String, Integer>
required group my_map (MAP) {
  repeated group key_value {
    required binary key (UTF8);
    optional int32 value;
  }
}
```

If there are multiple key-value pairs for the same key, then the final value
for that key must be the last value. Other values may be ignored or may be
added with replacement to the map container in the order that they are encoded.
The `MAP` annotation should not be used to encode multi-maps using duplicate
keys.

#### Backward-compatibility rules

It is required that the repeated group of key-value pairs is named `key_value`
and that its fields are named `key` and `value`. However, these names may not
be used in existing data and should not be enforced as errors when reading.

Some existing data incorrectly used `MAP_KEY_VALUE` in place of `MAP`. For
backward-compatibility, a group annotated with `MAP_KEY_VALUE` that is not
contained by a `MAP`-annotated group should be handled as a `MAP`-annotated
group.

Examples that can be interpreted using these rules:

```
// Map<String, Integer> (nullable map, non-null values)
optional group my_map (MAP) {
  repeated group map {
    required binary str (UTF8);
    required int32 num;
  }
}

// Map<String, Integer> (nullable map, nullable values)
optional group my_map (MAP_KEY_VALUE) {
  repeated group map {
    required binary key (UTF8);
    optional int32 value;
  }
}
```

## Null
Sometimes when discovering the schema of existing data values are always null and there's no type information.
The `NULL` type can be used to annotates a column that is always null.
(Similar to Null type in Avro)

