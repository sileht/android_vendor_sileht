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

[ -z "$PS1" ] && return

export JAVA_HOME=$HOME/workspace/android/jdk1.6.0_22/
export PATH=$JAVA_HOME/bin:$PATH
export USE_CCACHE=1
export CCACHE_DIR=$HOME/workspace/mydroid/ccache/
export CYANOGEN_NIGHTLY=true

githublogin="sileht"
workingversion="gingerbread"

echobold(){
    echo -e "\033[1m$@\033[0m"
}

function bb(){
	[ ! -d .repo ] && echo 'Not root dir' && return
    [ "$1" = "-s" ] && msync
    find out -name \*.prop | xargs rm -f ;
    bib vision -p
    mka bacon
    getzip
}


function getzip(){
    last=$(ls -1 update-sm-*-signed.zip 2>/dev/null| sort -n | head -1 | sed -n 's/update-sm-\([[:digit:]]*\)-signed.zip/\1/g')
    new=$((last + 1))
    mv out/target/product/vision/update-squished.zip update-sm-$new-signed.zip
    rm -f out/target/product/vision/update-squished.zip.md5sum
    ls -la update-sm-$new-signed.zip
    md5sum update-sm-$new-signed.zip |tee update-sm-$new-signed.zip.md5sum
}

function msync(){
    function check_repo() {
        if [ -n "$stage2" ]; then
            echo "repo \"$repo\" have staged changed, can't continue"
            return 1
        fi
        if [ -n "$autosyncflags" ]; then
            echo -n "repo \"$repo\" have previous failed autosync"
            if [ -z "$stage1" ] ; then
                echo ", reapply it"
                git stash pop || return 1
            else
                echo
                return 1
            fi
        fi
        return 0
    }

    function stash_save_repo(){
        [ -n "$stage2" ] && return 1
        if [ -n "$stage1" ]; then
            echobold "** Stash change in $repo **"
            git stash save autosync || return 1
            echo
        fi
    }

    function stash_restore_repo(){
        if [ -n "$autosyncflags" ]; then
            echobold "** Restore change in $repo **"
            git stash pop || return 1
            echo
        fi
    }

    function rebase_work(){
        git branch | grep current-work > /dev/null && {
            remote_name=$(git  remote -v | grep "$remote.*fetch" | awk '{print $1}')

            echobold "** Rebase $repo on $remote_name/$workingversion **"

            git checkout current-work
            git rebase $remote_name/$workingversion && \
            git push sileht current-work --force

            git branch | grep current-work-perso > /dev/null && {
                git checkout current-work-perso
                git rebase current-work && \
                git push sileht current-work-perso --force
            } || true
            echo
        } || true
    } 

    echobold "** Checking repos... **"
    myrepos --hook check_repo || return
    echo
    myrepos --hook stash_save_repo || return
    reposync
    echo
    myrepos --hook rebase_work || return
    myrepos --hook stash_restore_repo || return

    return
}

myrepos(){
    all=
    hook=
    if [ "$1" = "-a" ]; then
        all=1
        shift
    fi
    if [ "$1" = "--hook" ]; then
        shift
        hook=$@
    fi

	repos=($(sed -n -e 's/<project .*path="\([^"]*\)".*/\1/gp' .repo/manifest.xml .repo/local_manifest.xml))
    for repo in $repos; do
    	[ ! -d $repo ] && continue
    	pushd $repo
        if [ -n "$all" -o -d .git/refs/remotes/sileht ]; then
			curhead=
			stage1=
			stage2=
            autosyncflags=

            remote=$(git remote -v | grep ^github.*fetch.* | awk '{print $2}')
            [ -z "$remote" ] && remote=$(git remote -v | grep ^korg.*fetch.* | awk '{print $2}')
            [ -z "$remote" ] && remote=$(git remote -v | grep ^origin.*fetch.* | awk '{print $2}')
            [ -z "$remote" ] && remote=$(git remote -v | grep ^sileht.*fetch.* | awk '{print $2}')


            [ -e .git/refs/heads/current-work ] && curhead="C"
            [ -e .git/refs/heads/current-work-perso ] && curhead="P"

            git stash list | grep autosync >/dev/null && autosyncflags="F"

			git diff --no-ext-diff --ignore-submodules --quiet --exit-code || stage1="¹"
			git diff-index --cached --quiet --ignore-submodules HEAD || stage2="²"

            if [ -z "$hook" ]; then
    			printf '%35s [%1s%1s%1s%1s] : %s%s\n' "$repo" "$curhead" "$stage1" "$stage2" "$autosyncflags" "$remote"
            else
                $hook
                ret=$?
                if [ $ret -ne 0 ]; then
                    popd
                    return $ret
                fi
            fi
		fi
		popd
	done 
}

return

function list_fetch_and_exec(){
	cmd="$1"
	repos="$2"
	[ -z "$repos" ] && repos=($(sed -n -e 's/<project .*path="\([^"]*\)".*/\1/gp' .repo/manifest.xml .repo/local_manifest.xml))
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

return

# disable
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

