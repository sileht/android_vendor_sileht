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

[ -z "$PS1" ] && return

export JAVA_HOME=$HOME/workspace/android/jdk1.6.0_22/
export PATH=$JAVA_HOME/bin:$PATH
export USE_CCACHE=1
export CCACHE_DIR=$HOME/workspace/mydroid/ccache/

githublogin="sileht"

function msync(){
    pushd .repo/manifests/
    git pull
    popd >/dev/null 
    reposync
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
		msync && automerge
	fi
}
function fbuild(){
    buildvariant="$1"
    [ -z "$buildvariant" ] && buildvariant="userdebug"
    . build/envsetup.sh
	lunch sileht_sapphire-$buildvariant
    make -j4 it
}

function fallstep(){
	fprep
	fbuild
}

myrepos(){
	filter="$1"
	[ -z "$filter" ] && filter="sileht"
	[ "$filter" = "-a" ] && filter=""
	repos=($(sed -n -e 's/<project path="\([^"]*\)".*/\1/gp' .repo/manifest.xml))
    for repo in $repos; do
    	[ ! -d $repo ] && continue
    	pushd $repo
		remote=$({ git remote -v || echo "Error on: $repo" >&2 ; } | egrep --color=no "^github.*$filter.*fetch" | tail -1 | awk '{print $2}' | awk -F/ '{print $4"/"$5}')
		automerge=$(git remote -v | egrep --color=no "^automerge" | tail -1 | awk '{print $2}')
		[ -z "$remote" -a -n "$automerge" ] && remote=$(git remote -v | egrep --color=no "^github.*fetch" | tail -1 | awk '{print $2}' | awk -F/ '{print $4"/"$5}')
        if [ -n "$remote" ]; then
			flag1=
			flag2=
			flag3=
            git remote | grep automerge >/dev/null && flag1="M"
			git diff --no-ext-diff --ignore-submodules --quiet --exit-code || flag2="¹"
			git diff-index --cached --quiet --ignore-submodules HEAD || flag3="²"
			[ -n "$automerge" ] && automerge=" -> $automerge"
			printf '%35s [%1s%1s%1s] : %s%s\n' "$repo" "$flag1" "$flag2" "$flag3" "$remote" "$automerge"
		fi
		popd
	done 
}

function list_fetch_and_exec(){
	cmd="$1"
	repos="$2"
	[ -z "$repos" ] && repos=($(sed -n -e 's/<project path="\([^"]*\)".*/\1/gp' .repo/manifest.xml))
    for repo in $repos; do
        [ ! -d $repo ] && continue
        pushd $repo
        { git remote -v || echo "Error on: $repo" >&2 ; } | grep "^github.*$githublogin" >/dev/null
        if [ $? -eq 0 ]; then
            branch=$({ git remote || echo "Error on: $repo" >&2 ; } | grep automerge | sed 's/^automerge#//g')
            remote="automerge#$branch"
            if [ -n "$branch" ]; then
                echo -ne "* Checking for repo $repo: "
                echo "$branch"
                git fetch $remote
                case $cmd in
                    merge|rebase)
                        git $cmd $remote/$branch && git push $githublogin --force
                        ;;
                    diff)
                        git $cmd $remote/$branch
                        ;;
                    onlyfetch)
                        ;;
                    *)
                        ;;
                esac
            fi
        fi
        popd
    done
}
function autodiff(){
    list_fetch_and_exec diff "$1"
}
function autofetch(){
	list_fetch_and_exec fetchonly "$1"
}
function autorebase(){
	list_fetch_and_exec rebase "$1"
}

function automerge(){
	list_fetch_and_exec merge "$1"
}


setuprepo(){
    repo="$1"
    if [ -z "$repo" -o ! -d "$repo" -o ! -d "$repo/.git" ] ; then
        echo "Not a valid repo."
        return 1
    fi

    branch=$(grep "$repo" .repo/manifest.xml | sed -n -e 's@.*revision="\([^"]*\)".*@\1@gp')
    [ -z "$branch" ] && branch="froyo"

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

