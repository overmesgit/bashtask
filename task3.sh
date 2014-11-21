#!/bin/bash
egrep -ilR --include="*.log" "error" | tee res.txt | xargs ls -l | awk '{split($0,array," ")} {print array[7] "   " array[9]}'