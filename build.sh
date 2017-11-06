#!/bin/bash
if [ "$#" -lt 1 ]; then
    echo "Use alpha, beta or release"
    exit 1
fi
if [ "$1" != "alpha" ] && [ "$1" != "beta" ] && [ "$1" != "release" ] ; then
    echo "Use alpha, beta or release"
    exit 1
fi

GIT_DIR="../rainmachine-openwrt-feed/.git/"

check_branch() {
    CURRENT_FEED_BRANCH=`git --git-dir=$GIT_DIR symbolic-ref -q --short HEAD`
    echo "Checking Rainmachine Feed for the $FEED_BRANCH == $CURRENT_FEED_BRANCH"
    if [ $FEED_BRANCH != $CURRENT_FEED_BRANCH ]
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


BRANCHES="rainmachine next|rainmachine-rev2 next-rev2-fix"

build_current_branch(){
    CURRENT_BUILD_BRANCH=`git symbolic-ref -q --short HEAD`
    IFS="|"
    for tuple in $BRANCHES; do
	BRANCH=$(echo $tuple | cut -d " " -f 1)
	FEED_BRANCH=$(echo $tuple | cut -d " " -f 2)
	if [ $CURRENT_BUILD_BRANCH == $BRANCH ]; then
	    check_branch
	    check_branch final
	    echo Removing existing packages
	    rm -rf bin/ar71xx
	    echo Cleaning kernel
	    make target/linux/clean
	    echo Building
	    make -j4
	fi
    done
}

build_all_branches(){
    IFS="|"
    for tuple in $BRANCHES; do
	BRANCH=$(echo $tuple | cut -d " " -f 1)
	FEED_BRANCH=$(echo $tuple | cut -d " " -f 2)
	git checkout $BRANCH
	check_branch
	check_branch final
        echo Removing existing packages
        rm -rf bin/ar71xx
        echo Cleaning kernel
        make target/linux/clean
        echo Building
        make -j4
	sync_remote_repository $1
    done	    
}

sync_remote_repository(){
    case $1 in
	"release")
	_sync_remote_repository "release"
	_sync_remote_repository "beta"
	_sync_remote_repository "alpha"
	;;
	"beta")
	_sync_remote_repository "beta"
	_sync_remote_repository "alpha"
	;;
	"alpha")
	_sync_remote_repository "alpha"
	;;
    esac
}

_sync_remote_repository(){
    . ./rainmachine-build.conf
    UPDATE_PATH=$UPDATE_LOCATION_ROOT/${UPDATE_LOCATION_PREFIX}rainmachine-ar71xx${MODEL_SUFFIX}
    if [ "$1" != "release" ]; then
	UPDATE_PATH=$UPDATE_PATH"-$1"
    fi
    UPDATE_PATH=$UPDATE_PATH
    echo "Syncing $MODEL $1 packages to $UPDATE_PATH"
    aws s3 sync bin/ar71xx/packages $UPDATE_PATH/packages/ --region=eu-central-1 --metadata "timestamp=$(date +%s)" 

    echo "Syncing $MODEL  images..."
    if [ -z  $MODEL_SUFFIX ]; then
	MODEL_SUFFIX="-generic"
    fi
    aws s3 cp bin/ar71xx/ $UPDATE_LOCATION_ROOT/$UPDATE_LOCATION_BIN/os/ --recursive --exclude "*" --include "openwrt-ar71xx${MODEL_SUFFIX}-rainmachine-jffs2-*"  --region=eu-central-1 --metadata "timestamp=$(date +%s)" 
    
    echo "Adding changelog"
    d=$(date +%Y-%m-%d)
    dt=$(date)
    f="Change-Daily-Build.txt"
    l_openwrt=$(git  log --since="1 day ago" --format=-%s)
    l_openwrtfeed=$(git --git-dir ../rainmachine-openwrt-feed/.git log --since="1 day ago" --format=-%s)
    l_rainmachine=$(git --git-dir ../rainmachine/.git log --since="1 day ago" --format=-%s )

    echo "Build $MODEL2: $dt" > $f
    echo "OpenWRT OS Changes:" >> $f
    echo "$l_openwrt" >> $f
    echo >> $f 
    echo "OpenWRT RainMachine Feed Changes:" >> $f
    echo "$l_openwrtfeed" >> $f
    echo >> $f
    echo "Rainmachine App Changes:" >> $f
    echo "$l_rainmachine" >> $f

    aws s3 cp $f  $UPDATE_LOCATION_ROOT/$UPDATE_LOCATION_BIN/os/ --region=eu-central-1 --metadata "timestamp=$(date +%s)" 
}

if [ "$#" -eq 1 ]; then
    echo Building current branch
    #build_current_branch
    sync_remote_repository $1    
    exit 0
fi

if [ $2 == "all" ]; then
    echo Build all branches
    build_all_branches $1
    exit 0
fi

