#!/bin/sh
echo "Syncing packages..."
rm -rf /mnt/hall/rainmachine-ar71xx/packages
cp -a bin/ar71xx/packages /mnt/hall/rainmachine-ar71xx/
echo "Syncing rc images..."
rm -rf /mnt/hall/sprinkler2/os/openwrt-ar71xx-generic-rainmachine-jffs2-*
cp -a bin/ar71xx/openwrt-ar71xx-generic-rainmachine-jffs2-* /mnt/hall/sprinkler2/os/
echo "Adding changelog"
d=$(date +%Y-%m-%d)
dt=$(date)
f="/mnt/hall/sprinkler2/os/Changelog-Daily-Build.txt"
l_openwrt=$(git  log --since="1 day ago" --format=-%s)
l_openwrtfeed=$(git --git-dir ../rainmachine-openwrt-feed/.git log --since="1 day ago" --format=-%s)
l_rainmachine=$(git --git-dir ../rainmachine/.git log --since="1 day ago" --format=-%s )

echo "Build: $dt" > $f
echo "OpenWRT OS Changes:" >> $f
echo "$l_openwrt" >> $f
echo >> $f 
echo "OpenWRT RainMachine Feed Changes:" >> $f
echo "$l_openwrtfeed" >> $f
echo >> $f
echo "Rainmachine App Changes:" >> $f
echo "$l_rainmachine" >> $f
