#!/bin/bash

#sets up the environment to begin the parsecrunner.pl

alias sudo='sudo env PATH=$PATH'
cd "/home/ssllab/parsec/parsec-3.0"
source env.sh
/home/ssllab/testrunner.pl
