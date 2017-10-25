#!/bin/sh
GIT_DIR="../rainmachine-openwrt-feed/.git/"
FEED_BRANCH="next-rev2-fix"

check_branch() {

    CURRENT_BRANCH=`git --git-dir=$GIT_DIR symbolic-ref -q --short HEAD`
    echo "Checking Rainmachine Feed for the $FEED_BRANCH == $CURRENT_BRANCH"

    if [ $FEED_BRANCH != $CURRENT_BRANCH ]
    then
    echo "Error not in the correct branch: $FEED_BRANCH"
    if [ $1 ]
    then
	echo "Previous attempt to switch branch failed. Aborting"
	exit 2
    fi
    echo "Switching to $FEED_BRANCH branch"
    pushd $GIT_DIR/..
    git checkout $FEED_BRANCH
    popd
    fi

}

check_branch
check_branch final

echo Removing existing packages
rm -rf bin/ar71xx
echo Cleaning kernel
make target/linux/clean

echo Building
make -j4
