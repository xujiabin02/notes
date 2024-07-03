#!/bin/bash 
> ../README.md
for i in $(ls |grep -v "README.md"|grep -v ".assets"|grep -v toc_build.sh)
do
title=$(echo $i|awk -F"." '{print$1}')
#title=$(grep -v '^$'  $i|head -n 1|sed 's/\#//g')
echo "- [$title](NOTES/$i)" >> ../README.md
done
cd ..
git add .
git commit -m "$*"
git push -u github
git push -u gitee
#echo 'gaa && gcam "TOC" && gp'
