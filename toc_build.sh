#!/bin/bash 
> README.md
for i in $(ls |grep -v "README.md"|grep -v ".assets"|grep -v toc_build.sh)
do
title=$(echo $i|awk -F"." '{print$1}')
echo "###### [$title](./$i)" >> README.md
done
echo 'gaa && gcam "TOC" && gp'
