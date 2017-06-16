---
title: git实践
date: 2017-06-16 08:55:11
tags:
    - git
---

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
