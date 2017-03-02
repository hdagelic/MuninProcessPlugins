#!/bin/bash


# What is the lowest percentege that should be repotred

LIMIT="0.0"
TMP_DIR="/tmp"

if [ "$1" == "config" ]; then
  echo "graph_title CPU by process (irb)"
  echo "graph_vlabel CPU (%)"
     
  if [ -f "$TMP_DIR/munin-procpu.lst" ]; then   
    while read -r line; do
       echo "$line.label $line"
       #echo "$line.draw STACK"
    done < "$TMP_DIR/munin-procpu.lst"
  fi
  exit 0;
fi

OUT=$(ps -e -o comm,%cpu | grep -v "COMMA" | sort | awk -v limit="$LIMIT" '{arr[$1]+=$2} END {for (i in arr) { if (arr[i]>=limit) print i,arr[i] }}' | sort)

while read -r line; do
   COM=$(echo "$line" | awk '{print $1}' | sed -e 's/[^[:alnum:]]\+/_/g')
   VAL=$(echo "$line" | awk '{print $2}')
   if [ "$COM" == "" ]; then
     continue;
   fi
 
   echo "$COM.value $VAL"

   # Write to file, for the label list
   echo "$COM" >> "$TMP_DIR/munin-procpu.tmp"
done <<< "$OUT"


# Sort and uniq contents of the file that is used for labels

umask 000

touch "$TMP_DIR/munin-procpu.tmp"
 
if [ -f "$TMP_DIR/munin-procpu.lst" ]; then
   cat "$TMP_DIR/munin-procpu.lst" >> "$TMP_DIR/munin-procpu.tmp"
fi

sort "$TMP_DIR/munin-procpu.tmp" | uniq > "$TMP_DIR/munin-procpu.lst"
rm -f "$TMP_DIR/munin-procpu.tmp"

