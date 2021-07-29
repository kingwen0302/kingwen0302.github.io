#!/bin/bash

yum -y remove tmux
yum -y install gcc kernel-devel make ncurses-devel

curl -OL https://github.com/libevent/libevent/releases/download/release-2.0.22-stable/libevent-2.0.22-stable.tar.gz
tar -xvzf libevent-2.0.22-stable.tar.gz
cd libevent-2.0.22-stable
./configure --prefix=/usr/local
make && make install

curl -OL https://github.com/tmux/tmux/releases/download/2.1/tmux-2.1.tar.gz
tar -xvzf tmux-2.1.tar.gz
cd tmux-2.1
LDFLAGS="-L/usr/local/lib -Wl,-rpath=/usr/local/lib" ./configure --prefix=/usr/local
make && make install
