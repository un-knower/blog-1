---
title: hexo相关
date: 2017-06-09 09:11:24
tags:
    - hexo
    - markdown
toc: false
---

[TOC]

## markdown

#### 流程图
- 理论：
```flow
st => start:Start
e => end:End

op1 => operation: 流程操作A
sub1 => subroutine: 流程路由X

cond => condition: Yes or No?
io => inputoutput: catch something...

st -> op1 -> e
cond(yes) -> io -> e
cond(no) -> sub1(right) -> op1
```

#### 表格

##### markdown
``` md
| 水果        | 价格    |  数量  |
| --------    | -----:  | :----: |
| 香蕉        | $1      |   5    |
| 苹果        | $1      |   6    |
| 草莓        | $1      |   7    |
```

##### html
``` html
<table>
    <tr>
        <th>设备</th>
        <th>设备文件名</th>
        <th>文件描述符</th>
        <th>类型</th>
    </tr>
    <tr>
        <th>键盘</th>
        <th>/dev/stdin</th>
        <th>0</th>
        <th>标准输入</th>
    </tr>
    <tr>
        <th>显示器</th>
        <th>/dev/stdout</th>
        <th>1</th>
        <th>标准输出</th>
    </tr>
    <tr>
        <th>显示器</th>
        <th>/dev/stderr</th>
        <th>2</th>
        <th>标准错误输出</th>
    </tr>
</table>
```


##### other
###### excel表格
1. 知乎用户幻灰龙写的东西，亲测有效[下载链接](http://fanfeilong.github.io/exceltk0.0.4.7z),解压下来就能把excel变成md表格了
2. 在解压目录下，使用以下命令行，把xx的部分换成表格名称就行了（注意路径问题），windows就行了，不需要linux
``` console
exceltk用例
整个表格：    exceltk.exe -t md -xls xxx.xls  
              exceltk.exe -t md -xls xxx.xlsx
指定sheet：  
              exceltk.exe -t md -xls xx.xls -sheet sheetname   
              exceltk.exe -t md -xls xx.xlsx -sheet sheetnameexceltk
特性：
     转换Excel表格到MarkDown表格
     支持Excel单元格带超链接
     如果Excel里有合并的跨行单元格，在转换后的MarkDown里是分开的单元格，这是因为MarkDown本身不支持跨行单元格
     如果Excel表格右侧有大量的空列，则会被自动裁剪，算法是根据前100行来检测并计算
```


## Sublime

### 积累
- 在浏览器中进行预览的步骤如下：
    + preference--> key binding user 中输入：
``` console
    [
        {"keys": ["alt+m"], "command": "markdown_preview", "args": { "target": "browser"}}
    ]
```
    + Preferences --> Package Settings --> MarkdownLivePreview --> user Setting
``` console
    {
        "browser": "C:/Program Files (x86)/Google/Chrome/Application/chrome.exe",
        "enable_uml": true,
        "enable_highlight": true,
        "markdown_live_preview_on_open": true
    }
```

### 快捷键
#### Sublime Text 3 快捷键精华版
- Ctrl+Shift+P：打开命令面板
- Ctrl+P：搜索项目中的文件
- Ctrl+G：跳转到第几行
- Ctrl+W：关闭当前打开文件
- Ctrl+Shift+W：关闭所有打开文件
- Ctrl+Shift+V：粘贴并格式化
- Ctrl+D：选择单词，重复可增加选择下一个相同的单词
- Ctrl+L：选择行，重复可依次增加选择下一行
- Ctrl+Shift+L：选择多行
- Ctrl+Shift+Enter：在当前行前插入新行
- Ctrl+X：删除当前行
- Ctrl+M：跳转到对应括号
- Ctrl+U：软撤销，撤销光标位置
- Ctrl+J：选择标签内容
- Ctrl+F：查找内容
- Ctrl+Shift+F：查找并替换
- Ctrl+H：替换
- Ctrl+R：前往 method
- Ctrl+N：新建窗口
- Ctrl+K+B：开关侧栏
- Ctrl+Shift+M：选中当前括号内容，重复可选着括号本身
- Ctrl+F2：设置/删除标记
- Ctrl+/：注释当前行
- Ctrl+Shift+/：当前位置插入注释
- Ctrl+Alt+/：块注释，并Focus到首行，写注释说明用的
- Ctrl+Shift+A：选择当前标签前后，修改标签用的
- F11：全屏
- Shift+F11：全屏免打扰模式，只编辑当前文件
- Alt+F3：选择所有相同的词
- Alt+.：闭合标签
- Alt+Shift+数字：分屏显示
- Alt+数字：切换打开第N个文件
- Shift+右键拖动：光标多不，用来更改或插入列内容
- 鼠标的前进后退键可切换Tab文件
- 按Ctrl，依次点击或选取，可需要编辑的多个位置
- 按Ctrl+Shift+上下键，可替换行

#### 选择类
- Ctrl+D 选中光标所占的文本，继续操作则会选中下一个相同的文本。
- Alt+F3 选中文本按下快捷键，即可一次性选择全部的相同文本进行同时编辑。举个栗子：快速选中并更改所有相同的变量名、函数名等。
- Ctrl+L 选中整行，继续操作则继续选择下一行，效果和 Shift+↓ 效果一样。
- Ctrl+Shift+L 先选中多行，再按下快捷键，会在每行行尾插入光标，即可同时编辑这些行。
- Ctrl+Shift+M 选择括号内的内容（继续选择父括号）。举个栗子：快速选中删除函数中的代码，重写函数体代码或重写括号内里的内容。
- Ctrl+M 光标移动至括号内结束或开始的位置。
- Ctrl+Enter 在下一行插入新行。举个栗子：即使光标不在行尾，也能快速向下插入一行。
- Ctrl+Shift+Enter 在上一行插入新行。举个栗子：即使光标不在行首，也能快速向上插入一行。
- Ctrl+Shift+[ 选中代码，按下快捷键，折叠代码。
- Ctrl+Shift+] 选中代码，按下快捷键，展开代码。
- Ctrl+K+0 展开所有折叠代码。
- Ctrl+← 向左单位性地移动光标，快速移动光标。
- Ctrl+→ 向右单位性地移动光标，快速移动光标。
- shift+↑ 向上选中多行。
- shift+↓ 向下选中多行。
- Shift+← 向左选中文本。
- Shift+→ 向右选中文本。
- Ctrl+Shift+← 向左单位性地选中文本。
- Ctrl+Shift+→ 向右单位性地选中文本。
- Ctrl+Shift+↑ 将光标所在行和上一行代码互换（将光标所在行插入到上一行之前）。
- Ctrl+Shift+↓ 将光标所在行和下一行代码互换（将光标所在行插入到下一行之后）。
- Ctrl+Alt+↑ 向上添加多行光标，可同时编辑多行。
- Ctrl+Alt+↓ 向下添加多行光标，可同时编辑多行。

#### 编辑类
- Ctrl+J 合并选中的多行代码为一行。举个栗子：将多行格式的CSS属性合并为一行。
- Ctrl+Shift+D 复制光标所在整行，插入到下一行。
- Tab 向右缩进。
- Shift+Tab 向左缩进。
- Ctrl+K+K 从光标处开始删除代码至行尾。
- Ctrl+Shift+K 删除整行。
- Ctrl+/ 注释单行。
- Ctrl+Shift+/ 注释多行。
- Ctrl+K+U 转换大写。
- Ctrl+K+L 转换小写。
- Ctrl+Z 撤销。
- Ctrl+Y 恢复撤销。
- Ctrl+U 软撤销，感觉和 Gtrl+Z 一样。
- Ctrl+F2 设置书签
- Ctrl+T 左右字母互换。
- F6 单词检测拼写

#### 搜索类
- Ctrl+F 打开底部搜索框，查找关键字。
- Ctrl+shift+F 在文件夹内查找，与普通编辑器不同的地方是sublime允许添加多个文件夹进行查找，略高端，未研究。
- Ctrl+P 打开搜索框。举个栗子：1、输入当前项目中的文件名，快速搜索文件，2、输入@和关键字，查找文件中函数名，3、输入：和数字，跳转到文件中该行代码，4、输入#和关键字，查找变量名。
- Ctrl+G 打开搜索框，自动带：，输入数字跳转到该行代码。举个栗子：在页面代码比较长的文件中快速定位。
- Ctrl+R 打开搜索框，自动带@，输入关键字，查找文件中的函数名。举个栗子：在函数较多的页面快速查找某个函数。
- Ctrl+： 打开搜索框，自动带#，输入关键字，查找文件中的变量名、属性名等。
- Ctrl+Shift+P 打开命令框。场景栗子：打开命名框，输入关键字，调用sublime text或插件的功能，例如使用package安装插件。
- Esc 退出光标多行选择，退出搜索框，命令框等。

#### 显示类
- Ctrl+Tab 按文件浏览过的顺序，切换当前窗口的标签页。
- Ctrl+PageDown 向左切换当前窗口的标签页。
- Ctrl+PageUp 向右切换当前窗口的标签页。
- Alt+Shift+1 窗口分屏，恢复默认1屏（非小键盘的数字）
- Alt+Shift+2 左右分屏-2列
- Alt+Shift+3 左右分屏-3列
- Alt+Shift+4 左右分屏-4列
- Alt+Shift+5 等分4屏
- Alt+Shift+8 垂直分屏-2屏
- Alt+Shift+9 垂直分屏-3屏
- Ctrl+K+B 开启/关闭侧边栏。
- F11 全屏模式
- Shift+F11 免打扰模式

### 破解
http://ltcy.mqego.com/sublimetext.zip

### 插件



## hexo

### config.yml
``` yml
    # Hexo Configuration
    ## Docs: https://hexo.io/docs/configuration.html
    ## Source: https://github.com/hexojs/hexo/

    # Site
    title: kaidata
    subtitle: kai data analysis
    description: 李凯的大数据处理杂记
    author: KaiLee
    language: zh-CN
    timezone: Asia/Shanghai

    # URL
    ## If your site is put in a subdirectory, set url as 'http://yoursite.com/child' and root as '/child/'
    url: http://kaidata.github.io/
    root: /
    permalink: :year/:month/:day/:title/
    permalink_defaults:

    # Directory
    source_dir: source
    public_dir: public
    tag_dir: tags
    archive_dir: archives
    category_dir: categories
    code_dir: downloads/code
    i18n_dir: :lang
    skip_render:

    # Writing
    new_post_name: :title.md # File name of new posts
    default_layout: post
    titlecase: false # Transform title into titlecase
    external_link: true # Open external links in new tab
    filename_case: 0
    render_drafts: false
    post_asset_folder: false
    relative_link: false
    future: true
    highlight:
      enable: true
      line_number: true
      auto_detect: false
      tab_replace:

    # Category & Tag
    default_category: uncategorized
    category_map:
    		大数据: bigdata
    		语言: lang
    		框架: framework
    		编译构建: build
    		其他: other
    tag_map:

    # Date / Time format
    ## Hexo uses Moment.js to parse and display date
    ## You can customize the date format as defined in
    ## http://momentjs.com/docs/#/displaying/format/
    date_format: YYYY-MM-DD
    time_format: HH:mm:ss

    # Pagination
    ## Set per_page to 0 to disable pagination
    per_page: 10
    pagination_dir: page

    # Extensions
    ## Plugins: https://hexo.io/plugins/
    ## Themes: https://hexo.io/themes/
    #plugins:
      #- hexo-generator-feed
      #- hexo-generator-sitemap


    theme: landscape



    # Deployment
    ## Docs: https://hexo.io/docs/deployment.html
    deploy:
      type: git
      repo: https://github.com/kaidata/kaidata.github.com.git
      branch: master

```

### 命令相关
    1. 主题
        1. maupassant
        ``` shell
            git clone https://github.com/tufu9441/maupassant-hexo.git themes/maupassant
            npm install hexo-renderer-jade@0.3.0 --save
            npm install hexo-renderer-sass --save
        ```
    2. 插件
        1. hexo-admin
        ``` shell
            npm install --save hexo-admin
        ```
        2.
        ``` shell
            npm install --save hexo-tag-aplayer
        ```
        3.
        ``` shell
            npm install hexo-migrator-wordpress --save
        ```
        4.
        ``` shell
            npm install hexo-generator-feed --save
            npm install hexo-generator-baidu-sitemap --save

        ```
        5.
        ``` shell
            npm install -g cnpm --registry=https://registry.npm.taobao.org
        ```
