#!/bin/bash

# Install basic packages
apk add sudo curl wget vim bash git

# Install and configure bash
SHELL="/bin/bash"
PYTHONPATH="/usr/local/lib/python3-*/site-packages"
PS1="\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\] \w\[\033[00m\]\\n$ \[\]"

# Install sudo and configure user coder
adduser -D coder
echo "coder:Docker!" | chpasswd
echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
chown -R coder: /home/coder/

# Functions
findhere() { find . -name "*$1*"; }
opensslcert() { openssl s_client -showcerts -connect $1:443; }
curlcert() { curl $1 -vI --stderr -; }
