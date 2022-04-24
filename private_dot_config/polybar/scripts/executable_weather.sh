#!/bin/bash

output=$(curl -sf "wttr.in?m&format=%c%t+%w+%h")
echo $output | grep -iv unknown >/dev/null 2>&1
if [[ $? -eq 0 ]]
    then echo "$output";
    else echo " ";
fi
