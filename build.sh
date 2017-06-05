#!/bin/sh
echo Removing existing packages
rm -rf bin/ar71xx
echo Cleaning kernel
make target/linux/clean

echo Building
make -j4
