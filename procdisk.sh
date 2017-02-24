#!/bin/bash


# This plugin must have iotop installed, and this entry in the sudoers file
# "nobody" is the user that munin-dode uses (on my system)

# nobody ALL = NOPASSWD: /usr/sbin/iotop

# What is the lowest percentege that should be repotred

LIMIT="0.0"
TMP_DIR="/tmp"

if [ "$1" == "config" ]; then
  echo "graph_title Disk by process (irb)"
  echo "graph_vlabel disk (+- %)"
     
  if [ -f "$TMP_DIR/munin-procdisk.lst" ]; then   
    while read -r line; do
       echo "$line.label $line"
       #echo "$line.draw STACK"
    done < "$TMP_DIR/munin-procdisk.lst"
  fi
  exit 0;
fi

OUT=$(sudo iotop -a -b -n 3 -P -qqq | awk '{print $12" "$10}' | sort | awk -v limit="$LIMIT" '{arr[$1]+=$2} END {for (i in arr) { if (arr[i]>=limit) print i,arr[i]/2.7 }}' | sort)

while read -r line; do
   COM=$(echo "$line" | awk '{print $1}' | sed -e 's/[^[:alnum:]]\+/_/g')
   VAL=$(echo "$line" | awk '{print $2}')
   if [ "$COM" == "" ]; then
     continue;
   fi
   echo -n "$COM.value "
   printf "%0.2f\n" $VAL

   # Write to file, for the label list
   echo "$COM" >> "$TMP_DIR/munin-procdisk.tmp"
done <<< "$OUT"


# Sort and uniq contents of the file that is used for labels

touch "$TMP_DIR/munin-procdisk.tmp"
 
if [ -f "$TMP_DIR/munin-procdisk.lst" ]; then
   cat "$TMP_DIR/munin-procdisk.lst" >> "$TMP_DIR/munin-procdisk.tmp"
fi

sort "$TMP_DIR/munin-procdisk.tmp" | uniq > "$TMP_DIR/munin-procdisk.lst"
rm -f "$TMP_DIR/munin-procdisk.tmp"

chmod ugo+rw "$TMP_DIR/munin-procdisk.lst"
