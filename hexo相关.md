---
title: hexo相关
date: 2017-06-09 09:11:24
tags:
---


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
