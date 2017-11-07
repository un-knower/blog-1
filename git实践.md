---
title: git实践
date: 2017-06-16 08:55:11
tags:
    - git
toc: true
---

[TOC]

## git命令行
### configure tooling
Configure user information for all local repositories
1. git config --global user.name "name"     Sets the name you want atached to your commit transactions
2. git config --global user.email "email"       Sets the email you want atached to your commit transactions
3. git config --global color.ui auto            Enables helpful colorization of command line output

### create repositories
Start a new repository or obtain one from an existing URL
1. git init [project-name]          creates new local repository with the specified name
2. git clone [url]                  download a project and its entire version history

### make changes
Review edits and craf a commit transaction
1. git status               lists all new or modified files to be committed
2. git diff                 shows file differences not yet staged
3. git add [file]           snapshots the file in preparation for versioning
4. git diff --staged        shows file differences between staging and the last file version
5. git reset [file]                     unstages the file, but preserve its contents
6. git commit -m ["desc message"]       records file snapshots permanently in version history

### group changes
Name a series of commits and combine completed efforts
1. git branch       lists all local branches in the current repository
2. git branch [branch-name]     creates new branch
3. git checkout [branch-name]   switches to the specified branch and updates the working directory
4. git merge [branch] -d [branch-name]      deletes the specified branch

### refactor filenames
Relocate and remove versioned files
1. git rm [file]                            Deletes the file from the working directory and stages the deletion
2. git rm --cached [file]                   Removes the file from version control but preserves the file locally
3. git mv [file-original] [file-renamed]    Changes the file name and prepares it for commit

### suppress tracking
Exclude temporary files and paths
1. git ls-files --other --ingored --exclude-standard   Lists all ignored files in this project 

### save fragments
Shelve and restore incomplete changes
1. git stash            Temporarily stores all modified tracked files
2. git stash pop        Restores the most recently stashed files
3. git stash lists      Lists all stashed changesets
4. git stash drop       Discards the most recently stashed changeset      

### review history
Browse and inspect the evolution of project files
1. git log                                      Lists version history for the current branch
2. git log --follow [file]                      Lists version history for a file, including renames  
3. git diff [first-branch]...[second-branch]    Shows content differences between two branches
4. git show [commit]                            Outputs metadata and content changes of the specified commit

### redo commits
Erase mistakes and craf replacement history
1. git reset [commit]               Undoes all commits afer [commit], preserving changes locally
2. git reset --hard [commit]        Discards all history and changes back to the specified commit 

### synchronize changes
Register a repository bookmark and exchange version history
1. git fetch [bookmark]             Downloads all history from the repository bookmark
2. git merge [bookmark]/[branch]    Combines bookmark’s branch into current local branch
3. git push [alias] [branch]        Uploads all local branch commits to GitHub
4. git pull                         Downloads bookmark history and incorporates changes



##### error: RPC failed; result=56, HTTP code = 200
1. git config http.postBuffer 524288000
2. git config --global http.postBuffer 524288000

#### git status -s 中文乱码
- 通过将Git配置变量 core.quotepath 设置为false，就可以解决中文文件名称在这些Git命令输出中的显示问题，
	+ 解决方法：git config --global core.quotepath false
    + 乱码场景："\346\225\260\346\215\256\350\265\204\344\272\247\347\256\241\347\220\206.vsdx"
    + 解释：core.quotepath设为false的话，就不会对0x80以上的字符进行quote

##### Git如何永久删除文件(包括历史记录)
- 从你的资料库中清除文件
    + git filter-branch --force --index-filter 'git rm --cached --ignore-unmatch diagram/helloword.vsdx' --prune-empty --tag-name-filter cat -- --all
- 推送我们修改后的repo
    + git push origin master --force
- 清理和回收空间
    + rm -rf .git/refs/original/
    + git reflog expire --expire=now --all
    + git gc --prune=now
    + git gc --aggressive --prune=now

##### Git中如何直接拉取代码直接覆盖不做合并
- git fetch origin && git reset --hard origin/master





## 教程验证实践

GitHub操作流程 :

第一次提交 :  
方案一 : 本地创建项目根目录, 然后与远程GitHub关联, 之后的操作一样;
-- 初始化Git仓库 :Git init ;
-- 提交改变到缓存 :git commit -m 'description' ;
-- 本地git仓库关联GitHub仓库 : git remote add origin git@github.com:han1202012/TabHost_Test.git ;
-- 提交到GitHub中 : git push -u origin master ;
方案二 : 方案二就是不用关联GitHub仓库, 直接从GitHub冲克隆源码到本地, 项目根目录也不用创建;
-- 从GitHub上克隆项目到本地 :git clone git@github.com:han1202012/NDKHelloworld.git , 注意克隆的时候直接在仓库根目录即可, 不用再创建项目根目录 ;
-- 添加文件 :git add ./* , 将目录中所有文件添加;
-- 提交缓存 :git commit -m '提交';
-- 提交到远程GitHub仓库 : git push -u origin master ;
之后修改提交 : 
-- 与GitHub远程仓库同步 :git pull ;
-- 查看文件变更 : git status ;
-- 提交代码到本地缓存 : git commit -m 'description';
--提交代码到远程GitHub仓库 :git push ;

.gitignore用法 : 开放模式 注明忽略的文件 直接列出文件名, 保守模式 注明保留的文件 !文件名 ;

Git标签操作 : 轻量级标签, 带注释标签;
--查看标签 :git tag ;
--添加标签 : 轻量级标签git tag tagName , 带注释标签git tag -a tagName -m 'description' ;
--删除标签 :git tag -d tagName ;
--提交标签到GitHub中 : git push origin --tags ;

Git分支操作: 创建分支后, 分支操作不会影响master分支, 但是master分支改变会影其它分支;
--列出分支 :git branch ;
--切换分支 :git checkout master ;
--提交分支 : git push origin branchName ;
--删除分支 : git branch -d branchName , 强制删除分支 git branch -D branchName ;
--合并分支 : git merge branchName ;

.
一. Git介绍

分布式 : Git版本控制系统是一个分布式的系统, 是用来保存工程源代码历史状态的命令行工具;

保存点 : Git的保存点可以追踪源码中的文件, 并能得到某一个时间点上的整个工程项目额状态; 可以在该保存点将多人提交的源码合并, 也可以会退到某一个保存点上;

Git离线操作性 :Git可以离线进行代码提交, 因此它称得上是完全的分布式处理, Git所有的操作不需要在线进行; 这意味着Git的速度要比SVN等工具快得多,  因为SVN等工具需要在线时才能操作, 如果网络环境不好, 提交代码会变得非常缓慢; 

Git基于快照 : SVN等老式版本控制工具是将提交点保存成补丁文件, Git提交是将提交点指向提交时的项目快照, 提交的东西包含一些元数据(作者, 日期, GPG等);

Git的分支和合并 : 分支模型是Git最显著的特点, 因为这改变了开发者的开发模式, SVN等版本控制工具将每个分支都要放在不同的目录中, Git可以在同一个目录中切换不同的分支;
分支即时性 : 创建和切换分支几乎是同时进行的, 用户可以上传一部分分支, 另外一部分分支可以隐藏在本地, 不必将所有的分支都上传到GitHub中去;
分支灵活性 : 用户可以随时 创建 合并 删除分支, 多人实现不同的功能, 可以创建多个分支进行开发, 之后进行分支合并, 这种方式使开发变得快速, 简单, 安全;

