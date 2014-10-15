#!/bin/bash



alias sudo='sudo env PATH=$PATH'
cd "/home/ssllab/parsec/parsec-3.0"
source env.sh
export PARSECDIR="/home/ssllab/parsec/parsec-3.0"
export PARSECPLAT="amd64-linux.gcc"
/home/ssllab/testrunner.pl
