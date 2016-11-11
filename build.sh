#!/bin/sh
echo Removing existing packages
rm -rf bin/ar71xx
echo Building
make
