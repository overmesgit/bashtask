#!/bin/bash
ps ax | egrep "^([0-9]{5,}) .*127.0.0.1.*$" | sort -r