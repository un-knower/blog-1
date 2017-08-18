---
title: java实战
date: 2017-06-15 20:22:55
tags:
    - java
toc: true
---

[TOC]

### PACKAGE
#### shade

#### assembly

### CLASSPATH

#### Specification Order
The order in which you specify multiple class path entries is important. The Java interpreter will look for classes in the directories in the order they appear in the class path variable. In the previous example, the Java interpreter will first look for a needed class in the directory /java/MyClasses. Only when it does not find a class with the proper name in that directory will the interpreter look in the /java/OtherClasses directory.
jvm查找类，不仅仅是按名字找，还有包，如果包不同，也视为为同的class，如果package+class都相同，则根据classpath的设置顺序，前面的优先加载，一旦前面的被加载，后面的就再也不会被加载了,也就是说其实还是有一定的加载规则加载顺序的,你不能寄希望与系统，让它智能的加载你想要的。
如果系统出现了重名class，危险性是非常高的。
JVM会优先加载系统lib或者用户自己配置的classpath下的jar包，然后再加载项目中的jar包。作为项目开发人员，千万不要外部包放到系统目录和classpath路径下，这是在为以后埋坑。

##### java.ext.dirs
- java.ext.dirs has a very specific use: it's used to specify where the extension mechanism loads classes from. Its used to add functionality to the JRE or to other libraries (such as JAI). It's not meant as a general-purpose class-loading mechanism.
- Use the wildcard character * instead. It was introduced in Java 6, so many people still don't know it's possible.



### JUnit
``` java
  import org.hamcrest.core.CombinableMatcher;
  import org.junit.Test;

  import java.util.Arrays;

  import static org.hamcrest.CoreMatchers.*;
  import static org.junit.Assert.*;

  /**
   * Created by likai14 on 2017/8/18.
   */
  public class AssetTests {
      @Test
      public void testAssertArrayEquals() {
          byte[] expected = "trial".getBytes();
          byte[] actual = "trial".getBytes();
          assertArrayEquals("failure - byte arrays not same", expected, actual);
      }

      @Test
      public void testAssertEquals() {
          assertEquals("failure - strings are not equal", "text", "text");
      }

      @Test
      public void testAssertFalse() {
          assertFalse("failure - should be false", false);
      }

      @Test
      public void testAssertNotNull() {
          assertNotNull("should not be null", new Object());
      }

      @Test
      public void testAssertNotSame() {
          assertNotSame("should not be same Object", new Object(), new Object());
      }

      @Test
      public void testAssertNull() {
          assertNull("should be null", null);
      }

      @Test
      public void testAssertSame() {
          Integer aNumber = Integer.valueOf(768);
          assertSame("should be same", aNumber, aNumber);
      }

      // JUnit Matchers assertThat
      @Test
      public void testAssertThatBothContainsString() {
          assertThat("albumen", both(containsString("a")).and(containsString("b")));
      }

      @Test
      public void testAssertThatHasItems() {
          assertThat(Arrays.asList("one", "two", "three"), hasItems("one", "three"));
      }

      @Test
      public void testAssertThatEveryItemContainsString() {
          assertThat(Arrays.asList(new String[]{"fun", "ban", "net"}), everyItem(containsString("n")));
      }

      // Core Hamcrest Matchers with assertThat
      @Test
      public void testAssertThatHamcrestCoreMatchers() {
          assertThat("good", allOf(equalTo("good"), startsWith("good")));
          assertThat("good", not(allOf(equalTo("bad"), equalTo("good"))));
          assertThat("good", anyOf(equalTo("bad"), equalTo("good")));
          assertThat(7, not(CombinableMatcher.<Integer>either(equalTo(3)).or(equalTo(4))));
          assertThat(new Object(), not(sameInstance(new Object())));
      }

      @Test
      public void testAssertTrue() {
          assertTrue("failure - should be true", true);
      }
  }
```

### hamcrest
#### A tour of common matchers
Hamcrest comes with a library of useful matchers. Here are some of the most important ones.

- Core
    * anything - always matches, useful if you don't care what the object under test is
    * describedAs - decorator to adding custom failure description
    * is - decorator to improve readability - see "Sugar", below
- Logical
    * allOf - matches if all matchers match, short circuits (like Java &&)
    * anyOf - matches if any matchers match, short circuits (like Java ||)
    * not - matches if the wrapped matcher doesn't match and vice versa
- Object
    * equalTo - test object equality using Object.equals
    * hasToString - test Object.toString
    * instanceOf, isCompatibleType - test type
    * notNullValue, nullValue - test for null
    * sameInstance - test object identity
- Beans
    * hasProperty - test JavaBeans properties
- Collections
    * array - test an array's elements against an array of matchers
    * hasEntry, hasKey, hasValue - test a map contains an entry, key or value
    * hasItem, hasItems - test a collection contains elements
    * hasItemInArray - test an array contains an element
- Number
    * closeTo - test floating point values are close to a given value
    * greaterThan, greaterThanOrEqualTo, lessThan, lessThanOrEqualTo - test ordering
- Text
    * equalToIgnoringCase - test string equality ignoring case
    * equalToIgnoringWhiteSpace - test string equality ignoring differences in runs of whitespace
    * containsString, endsWith, startsWith - test string matching






### 执行器参数输入封装
#### JCommander
###### Overview
JCommander is a very small Java framework that makes it trivial to parse command line parameters.

###### Types of options
The fields representing your parameters can be of any type. Basic types (Integer, Boolean, etc…​) are supported by default and you can write type converters to support any other type (File, etc…​).
1. Boolean
2. Lists
3. Password
4. Echo Input

###### Custom types (converters and splitters)
1. Custom types - Single value
Use either the converter= attribute of the @Parameter or implement IStringConverterFactory.
    1. By annotation
    By default, JCommander parses the command line into basic types only (strings, booleans, integers and longs). Very often, your application actually needs more complex types (such as files, host names, lists, etc.). To achieve this, you can write a type converter by implementing the following interface:
    ``` java
    public interface IStringConverter<T> {
      T convert(String value);
    }

    public class FileConverter implements IStringConverter<File> {
      @Override
      public File convert(String value) {
        return new File(value);
      }
    }

    @Parameter(names = "-file", converter = FileConverter.class)
    File file;

    // If a converter is used for a List field:
    @Parameter(names = "-files", converter = FileConverter.class)
    List<File> files;
    // $ java App -files file1,file2,file3
    ```
    2. By factory
    If the custom types you use appear multiple times in your application, having to specify the converter in each annotation can become tedious. To address this, you can use an IStringConverterFactory:
    ``` java
    public interface IStringConverterFactory {
      <T> Class<? extends IStringConverter<T>> getConverter(Class<T> forType);
    }

    //$ java App -target example.com:8080
    public class HostPort {
      public HostPort(String host, String port) {
         this.host = host;
         this.port = port;
      }

      final String host;
      final Integer port;
    }

    class HostPortConverter implements IStringConverter<HostPort> {
      @Override
      public HostPort convert(String value) {
        String[] s = value.split(":");
        return new HostPort(s[0], Integer.parseInt(s[1]));
      }
    }

    public class Factory implements IStringConverterFactory {
      public Class<? extends IStringConverter<?>> getConverter(Class forType) {
        if (forType.equals(HostPort.class)) return HostPortConverter.class;
        else return null;
      }
    }

    public class ArgsConverterFactory {
      @Parameter(names = "-hostport")
      private HostPort hostPort;
    }

    ArgsConverterFactory a = new ArgsConverterFactory();
    JCommander jc = JCommander.newBuilder()
        .addObject(a)
        .addConverterFactory(new Factory())
        .build()
        .parse("-hostport", "example.com:8080");

    Assert.assertEquals(a.hostPort.host, "example.com");
    Assert.assertEquals(a.hostPort.port.intValue(), 8080);
    ```

    Another advantage of using string converter factories is that your factories can come from a dependency injection framework.
2. Custom types - List value
Use the listConverter= attribute of the @Parameter annotation and assign a custom IStringConverter implementation to convert a String into a List of values.
    1. By annotation
3. Splitting
Use the splitter= attribute of the @Parameter annotation and assign a custom IParameterSplitter implementation to handle how parameters are split in sub-parts.
    1. By annotation

###### Parameter validation
1. Individual parameter validation
2. Global parameter validation

###### Main parameter

###### Private parameters

###### Parameter separators
``` java
@Parameters(separators = "=")
public class SeparatorEqual {
  @Parameter(names = "-level")
  private Integer level = 2;
}
```

###### Multiple descriptions

###### @ syntax
JCommander supports the @ syntax, which allows you to put all your options into a file and pass this file as parameter:
``` shell 
    java Main @/tmp/parameters
```

###### Arities (multiple values for parameters)
1. Fixed arities
``` java
@Parameter(names = "-pairs", arity = 2, description = "Pairs")
private List<String> pairs;
```
2. Variable arities
You can specify that a parameter can receive an indefinite number of parameters, up to the next option
    1. With a list
    If the number of following parameters is unknown, your parameter must be of type List<String> and you need to set the boolean variableArity to true:
    ``` java
    @Parameter(names = "-foo", variableArity = true)
    public List<String> foo = new ArrayList<>();    
    ```
    2. With a class
    Alternatively, you can define a class in which the following parameters will be stored, based on their order of appearance:
    ``` java
    static class MvParameters {
      @SubParameter(order = 0)
      String from;

      @SubParameter(order = 1)
      String to;
    }

    @Test
    public void arity() {
      class Parameters {
        @Parameter(names = {"--mv"}, arity = 2)
        private MvParameters mvParameters;
      }

      Parameters args = new Parameters();
      JCommander.newBuilder()
              .addObject(args)
              .args(new String[]{"--mv", "from", "to"})
              .build();

      Assert.assertNotNull(args.mvParameters);
      Assert.assertEquals(args.mvParameters.from, "from");
      Assert.assertEquals(args.mvParameters.to, "to");
    }
    ```

###### Multiple option names    
``` java
@Parameter(names = { "-d", "--outputDirectory" }, description = "Directory")
private String outputDirectory;
```
``` scala
@Parameter(names = Array("-d", "--outputDirectory"), description = "Directory")
var outputDirectory: Integer = null
```

###### Required and optional parameters
If some of your parameters are mandatory, you can use the required attribute (which default to false):
If this parameter is not specified, JCommander will throw an exception telling you which options are missing.
``` java
@Parameter(names = "-host", required = true)
private String host;
```

###### Default values

###### Help parameter
If one of your parameters is used to display some help or usage, you need use the help attribute:
``` java
@Parameter(names = "--help", help = true)
private boolean help;
```
If you omit this boolean, JCommander will instead issue an error message when it tries to validate your command and it finds that you didn’t specify some of the required parameters.

###### Usage
You can invoke usage() on the JCommander instance that you used to parse your command line in order to generate a summary of all the options that your program understands:
``` shell
Usage: <main class> [options]
  Options:
    -debug          Debug mode (default: false)
    -groups         Comma-separated list of group names to be run
  * -log, -verbose  Level of verbosity (default: 1)
    -long           A long number (default: 0)
```


### JSON
``` xml
    <dependency>
        <groupId>com.google.code.gson</groupId>
        <artifactId>gson</artifactId>
        <version>2.8.0</version>
    </dependency>
```

``` java
    Gson gson = new GsonBuilder().setPrettyPrinting().create();
```

### YAML
``` xml
    <dependency>
        <groupId>org.yaml</groupId>
        <artifactId>snakeyaml</artifactId>
        <version>1.18</version>
    </dependency>
```
``` java
    InputStream is = Thread.currentThread().getContextClassLoader().getResourceAsStream("snap-image-info-collector.yml");
    Yaml yaml = new Yaml();
    Map<String, Object> object = (Map<String, Object>) yaml.load(is);
```
