# use case aufs

## TL;DR

```bash
# install virtualbox
# install vagrant
# install git
# clone these repository
# change into use-case directory
# run use case with:
make -f ..Makefile clean init up
```

## stress cache

```bash
make -f ../Makefile cc rcc
```

## look at cache

- login in vagrant box

```bash
make -f ../Makefile ssh
```

- show content of both cache directory

```bash
sudo find /cache0 -type f -exec cat  {} \;
sudo find /cache1 -type f -exec cat  {} \;
```

- count cache item and compare with squidclient mgr:info

```bash
sudo find /cache0 -type f -exec ls -l {} \; |wc -l
sudo find /cache1 -type f -exec ls -l {} \; |wc -l
squidclient mgr:info
```
