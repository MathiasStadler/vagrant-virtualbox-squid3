# ccache

## homepage

```txt

```

## quick tutorial

```txt
https://wiki.archlinux.org/index.php/Ccache
```

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
sudo make install

# Create symbols link for ccache

sudo cp ccache /usr/local/bin/
sudo cd /usr/local/bin/
sudo ln -s ccache /usr/local/bin/gcc
sudo ln -s ccache /usr/local/bin/g++
sudo ln -s ccache /usr/local/bin/cc
sudo ln -s ccache /usr/local/bin/c++
```

## show Cache statistics

```bash
ccache -s/--show-stats
```
