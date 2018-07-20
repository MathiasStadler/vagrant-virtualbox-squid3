# ccache

## sources

```txt
https://askubuntu.com/questions/466059/how-do-i-enable-ccache
```

## sample

```bash
wget https://www.samba.org/ftp/ccache/ccache-3.4.2.tar.gz

# un compress:

tar -zxvf ccache-3.3.3.tar.gz

# Enter folder:

cd ccache-3.3.3

# To compile and install ccache, run these commands:

./configure
make
make install

# Create symbols link for ccache

cp ccache /usr/local/bin/
cd /usr/local/bin/
ln -s ccache /usr/local/bin/gcc
ln -s ccache /usr/local/bin/g++
ln -s ccache /usr/local/bin/cc
ln -s ccache /usr/local/bin/c++
```

## show Cache statistics

```bash
ccache -s/--show-stats
```
