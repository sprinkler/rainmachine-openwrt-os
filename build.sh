#!/bin/bash
. ./rainmachine-build.conf

BRANCHES="rainmachine next|rainmachine-rev2 next-rev2-fix"

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
	sync_remote_repository alpha
    done
}

sync_remote_repository(){
    case $1 in
	"release")
	_sync_remote_repository "alpha"
	;;
	"beta")
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
    UPDATE_PATH_PRIVATE=$UPDATE_LOCATION_PRIVATE/${UPDATE_LOCATION_PREFIX}rainmachine-ar71xx${MODEL_SUFFIX}
    UPDATE_PATH=$UPDATE_PATH-alpha #force upload path to alpha
    UPDATE_PATH_PRIVATE=$UPDATE_PATH_PRIVATE-alpha #force upload path to alpha
        
    if [ $AWS_SYNC -eq 1 ]; then
        echo "Syncing $MODEL $1 packages to $UPDATE_PATH"
	TIMESTAMP_S3="$(date +%s)"
        aws s3 sync bin/ar71xx/packages $UPDATE_PATH/packages/ --region=us-west-2 --metadata "timestamp=$TIMESTAMP_S3" 
    fi

    if [ $LOCAL_SYNC -eq 1 ]; then
	echo "Copying $MODEL $1 packages to UPDATE_PATH_PRIVATE"
	cp bin/ar71xx/packages/*  $UPDATE_PATH_PRIVATE/packages/

        echo "Copying  $MODEL  images to local server"
	if [ -z  $MODEL_SUFFIX ]; then
	    MODEL_SUFFIX="-generic"
	fi
	cp bin/ar71xx/openwrt-ar71xx${MODEL_SUFFIX}-rainmachine-jffs2-* $UPDATE_LOCATION_PRIVATE/$UPDATE_LOCATION_BIN/os/
	cp $f  $UPDATE_LOCATION_PRIVATE/$UPDATE_LOCATION_BIN/os/ 
    fi
    
    echo "Adding changelog"
    d=$(date +%Y-%m-%d)
    dt=$(date)
    f="Change-Daily-Build.txt"
    l_openwrt=$(git  log --since="1 day ago" --format=-%s)
    l_openwrtfeed=$(git --git-dir ../rainmachine-openwrt-feed/.git log --since="1 day ago" --format=-%s)
    l_rainmachine=$(git --git-dir ../rainmachine/.git log --since="1 day ago" --format=-%s )

    cd tmp
    git clone git@github.com:sprinkler/rainmachine-web-ui.git -b next
    cd rainmachine-web-ui
    git checkout master
    l_rainmachine_webui=$(git log master..next --format=-%s | grep -v "Merge pull request" )
    cd ..
    rm -rf rainmachine-web-ui
    cd ..

    echo "Build $MODEL2: $dt" > $f
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
}

# This should copy and overwrite original packages in openwrt feed with our versions
overwrite_openwrt_feed_packages() {
    cp -a $RAINMACHINE_FEED_DIR/lighttpd feeds/packages/net/ 
}

if [ "$#" -lt 1 ]; then
    echo **Building current branch
    build_current_branch
    sync_remote_repository alpha
    exit 0
fi

if [ $1 == "all" ]; then
    echo **Building all branches
    build_all_branches alpha
    exit 0
fi

