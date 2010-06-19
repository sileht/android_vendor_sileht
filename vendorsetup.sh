#
# Copyright (C) 2009 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# This file is executed by build/envsetup.sh, and can use anything
# defined in envsetup.sh.
#
# In particular, you can add lunch options with the add_lunch_combo
# function: add_lunch_combo generic-eng

add_lunch_combo sileht_dream_sapphire-eng
add_lunch_combo sileht_dream_sapphire-userdebug

[ -z "$PS1" ] && return

if [ -z "$JAVA_HOME" ]; then
    export JAVA_HOME=/home/prout/workspace/android/jdk1.6.0_20/
    export PATH=$JAVA_HOME/bin:$PATH
fi

function genbuildspec(){
    buildvariant="$1"
    [ -z "$buildvariant" ] && buildvariant="eng"
    rm -f buildspec.mk
cat > buildspec.mk <<EOF
TARGET_PRODUCT:=sileht_dream_sapphire
TARGET_BUILD_VARIANT:=$buildvariant
TARGET_BUILD_TYPE:=release
EOF
}


githublogin="sileht"

function goroot(){
	cd ~/workspace/android/mydroid/
}

function reposync(){
    pushd .repo/manifests/
    git fetch --all && \
    git rebase cyanogen/eclair-ds && \
    git push sileht --force && \
    popd >/dev/null 
    repo sync 
}

function fclean(){
	[ ! -d .repo ] && echo 'Not root dir' && return
    find out -name \*.prop | xargs rm -f ;
}

function fprep(){
    fclean
	if [ "$1" == "-q" ]  ; then
		repo sync && automerge
	else
		reposync && automerge
	fi
}
function fbuild(){
    buildvariant="$1"
    [ -z "$buildvariant" ] && buildvariant="eng"
    . build/envsetup.sh
	lunch sileht_dream_sapphire-$buildvariant
    make -j4 it
}

function automerge(){
	repos="$1"
	[ -z "$repos" ] && repos=$(sed -n -e 's/<project path="\([^"]*\)".*/\1/gp' .repo/manifest.xml)
    for repo in $repos; do
        [ ! -d $repo ] && continue
        pushd $repo
        git remote -v | grep "^github.*$githublogin" >/dev/null
        if [ $? -eq 0 ]; then
            branch=$(git remote | grep automerge | sed 's/^automerge#//g')
            remote="automerge#$branch"
            if [ -n "$branch" ]; then
                echo -ne "* Checking for repo $repo: "
                echo "$branch"
                git fetch $remote
                git rebase $remote/$branch && git push $githublogin --force
            fi
        fi
        popd >/dev/null
    done
}


setuprepo(){
    repo="$1"
    if [ -z "$repo" -o ! -d "$repo" -o ! -d "$repo/.git" ] ; then
        echo "Not a valid repo."
        return 1
    fi

    branch=$(grep "$repo" .repo/manifest.xml | sed -n -e 's@.*revision="\([^"]*\)".*@\1@gp')
    [ -z "$branch" ] && branch="eclair"

    reporemote=$(grep "$repo" .repo/manifest.xml | sed -n -e 's@.*remote="\([^"]*\)".*@\1@gp')
    [ -z "$reporemote" ] && reporemote="korg"

    reponame=$(grep "$repo" .repo/manifest.xml | sed -n -e 's@.*name="\([^"]*\)".*@\1@gp')
    destreponame="$githublogin/$(echo $reponame | sed -e 's@cyanogen/@@g' -e 's@/@_@g')"

    sourceurl=$(cd $repo && git remote -v | egrep '^(korg|github).*push' | awk '{print $2}')
    desturl="git@github.com:$destreponame.git"

    echo "branch: $branch"
    echo "- source: $sourceurl"
    echo "- $githublogin: $desturl"
    echo "- repo: $destreponame"
    read
    pushd $repo
    git remote add $githublogin $desturl
    git remote add automerge#$branch $sourceurl
    git fetch --all -p
    popd >/dev/null
    pushd .repo/manifests/
    sed -i "s@${reponame}\".*@${destreponame}\" remote=\"github\" />@g" default.xml
    git commit -a -m "Use my $destreponame repo"
    popd >/dev/null
}

function cleanuprepo(){
    repo="$1"
    if [ -z "$repo" -o ! -d "$repo" -o ! -d "$repo/.git" ] ; then
        echo "Not a valid repo."
        return 1
    fi

#   commit=$(git log --grep="Use my $destreponame repo" --format='format:%H' | head -1)

#   sourceurl=$(cd $repo && git remote -v | egrep '^automerge.*push' | awk '{print $2}')

    pushd $repo
    for i in $(git remote); do
        git remote rm $i
    done
    popd >/dev/null
    repo sync $repo
    pushd $repo
    git fetch -p --all -v
    popd >/dev/null
}

