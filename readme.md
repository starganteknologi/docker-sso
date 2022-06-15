# Docker Stargan Single Sign On Project

# add submodule 

reference : [how to add submodule](https://www.git-scm.com/book/en/v2/Git-Tools-Submodules)

``` shell
cd volumes\sites\
git submodule add git@github.com:starganteknologi/sso.git
git status
git diff --cached --submodule
git add .
git commit -am 'Add sso module'
```