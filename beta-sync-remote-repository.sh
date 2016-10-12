#!/bin/sh
echo "Syncing beta packages..."
rm -rf /mnt/hall/rainmachine-ar71xx-beta/packages
cp -a bin/ar71xx/packages /mnt/hall/rainmachine-ar71xx-beta/
echo "Syncing beta images..."
rm -rf /mnt/hall/sprinkler2/os/beta-releases/openwrt-ar71xx-generic-rainmachine-jffs2-*
cp -a bin/ar71xx/openwrt-ar71xx-generic-rainmachine-jffs2-* /mnt/hall/sprinkler2/os/beta-releases/

echo "Adding beta changelog"
d=$(date +%Y-%m-%d)
dt=$(date)
f="/mnt/hall/rainmachine-ar71xx-beta/packages/Changelog.txt"
l_openwrt=$(git  log rainmachine.. --format=-%s)
l_openwrtfeed=$(git --git-dir ../rainmachine-openwrt-feed/.git log master..next --format=-%s)
l_rainmachine=$(git --git-dir ../rainmachine/.git log master.. --format=-%s )
l_rainmachine_webui=$(git --git-dir ../../rainmachine-ui/.git log master..next --format=-%s | grep -v "Merge pull request" )

echo "Build: $dt" > $f
echo "OpenWRT OS Changes:" >> $f
echo "$l_openwrt" >> $f
echo >> $f 
echo "OpenWRT RainMachine Feed Changes:" >> $f
echo "$l_openwrtfeed" >> $f
echo >> $f
echo "Rainmachine App Changes:" >> $f
echo "$l_rainmachine" >> $f

echo "Rainmachine Web UI Changes:" >> $f
echo "$l_rainmachine_webui" >> $f

