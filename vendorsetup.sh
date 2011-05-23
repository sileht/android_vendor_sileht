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
export CCACHE_DIR=$HOME/workspace/android/mydroid/ccache/
export CYANOGEN_NIGHTLY=true


function putfiles(){
    for i in $* ; do 
		dest=$i
		dest=${dest#*vision}
		dest=${dest#*dream_sapphire}
        adb push $HOME/workspace/mydroid/$i $dest
    done
}

githublogin="sileht"
workingversion="gingerbread"

echobold(){
    echo -e "\033[1m$@\033[0m"
}

function get_device(){
	echo "$TARGET_PRODUCT" | sed -n -e 's/^cyanogen_//gp'
}

function b(){
	if [ -z "$(get_device)" ] ; then
        bib ${1:=vision} ${2:=-p}
    fi
	echobold "** Build module for $(get_device) **"
    mm
}

function bb(){
	[ ! -d .repo ] && echo 'Not root dir' && return
    [ "$1" = "-s" ] && shift && msync
    find out -name \*.prop | xargs rm -f ;
    bib ${1:=vision} ${2:=-p}
    mka bacon && getzip
}


function getzip(){
	name=$(get_device)
    last=$(ls -1t update-sm-$name-*-signed.zip 2>/dev/null | head -1 | sed -n 's/update-sm-'$name'-\([[:digit:]]*\)-signed.zip/\1/gp')
    new=$((last + 1))
    mv out/target/product/$name/update-squished.zip update-sm-$name-$new-signed.zip || exit 1
    rm -f out/target/product/vision/update-squished.zip.md5sum
    ls -la update-sm-$name-$new-signed.zip
    n=$new
    while [ $n -ne 0 ]; do
        n=$((n - 1))
        zip="update-sm-$name-$n-signed.zip"
        [ ! -e "$zip" ] && break;
        rm --interactive=never "$zip" 
    done
    #md5sum update-sm-$name-$new-signed.zip |tee update-sm-$name-$new-signed.zip.md5sum
}

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
function upload_work(){
    git branch | grep current-work > /dev/null && {
        echobold "** Upload $repo on sileht **"
        git checkout current-work
        git push sileht current-work
        git branch | grep current-work-perso > /dev/null && {
            git checkout current-work-perso
            git push sileht current-work-perso
        }
    }
}
function myupload(){
    myrepos --hook upload_work
}

function msync(){


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
			currentwork=
			currentworkperso=
			stage1=
			stage2=
            autosyncflags=

            remote=$(git remote -v | grep ^github.*fetch.* | awk '{print $2}')
            [ -z "$remote" ] && remote=$(git remote -v | grep ^korg.*fetch.* | awk '{print $2}')
            [ -z "$remote" ] && remote=$(git remote -v | grep ^origin.*fetch.* | awk '{print $2}')
            [ -z "$remote" ] && remote=$(git remote -v | grep ^sileht.*fetch.* | awk '{print $2}')

        	remote_name=$(git  remote -v | grep "$remote.*fetch" | awk '{print $1}')

            if [ -e .git/refs/heads/current-work ]; then
				if [ -n "$(git diff current-work $remote_name/$workingversion 2>/dev/null)" ] ; then
					currentwork="C"
				else
					currentwork="c"
				fi
			fi

            if [ -e .git/refs/heads/current-work-perso ]; then
				if [ -n "$(git diff current-work-perso current-work 2>/dev/null)" ] ; then
					currentworkperso="P"
				else
					currentworkperso="p"
				fi
			fi

            git stash list | grep autosync >/dev/null && autosyncflags="F"

			git diff --no-ext-diff --ignore-submodules --quiet --exit-code || stage1="¹"
			git diff-index --cached --quiet --ignore-submodules HEAD || stage2="²"

            if [ -z "$hook" ]; then
    			printf '%35s [%1s%1s%1s%1s%1s] : %s%s\n' "$repo" "$currentwork" "$currentworkperso" "$stage1" "$stage2" "$autosyncflags" "$remote"
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


