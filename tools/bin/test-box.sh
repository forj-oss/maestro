#!/bin/bash

# (c) Copyright 2014 Hewlett-Packard Development Company, L.P.
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.


#
# Script to configure a git on a specific kit to test some code.
#

function Help()
{
 BASE=$(basename $0)
 echo "Usage is $BASE [options] --configure <Ero IpAddress>
         $BASE [options] --restore
         $BASE [options] --send
         $BASE [options] --ssend <commit message>
         $BASE [options] --push-to
         $BASE [options] --report <branch>
         $BASE [options] --remove
There is 2 ways to use test-box:
1. Working on a test branch, and report updates to any wanted branch when you are done.
OR
2. Working on your branch where you have code to test on a remote server.

I strongly suggest the second option, easier to manage.

Actions used when ou working on a test branch:
- --configure <Server> to create your test branch
- --send or --ssend    to send your commit to the remoe server.
- --report             to merge your code on another branch, like master.
- --remove             to remove your test branch.

Actions used when you are working on your development branch, and wanted to test your code, on a server.
- --push-to <Server>     to send out all current branch commits to the remote server.
- --remote-from <Server> to remove links to the remote server.

Details:
 - configure <Server>     : Configure an eroplus to become a testing environment. The IP is the public address of the eroplus to use.
                            By default, configure will push your current branch code to the remote box. If you need to get the remote code locally and test on it, use --ref remote.
                            NOTE: If another user has configured the repo to his test, it will warn you, and require your approval.
 - remove                 : Will remove any configuration built by --configure. You need to be in the testing branch, and your testing code safe to be removed or already merged/rebased.
 - restore                : Restaure master branch on the testing environment. (git checkout master on the remote server)
 - send                   : shortcut to git push (in your workstation) and git pull on the eroPlus box.
 - ssend <commit message> : Will auto add all files and commit with the message, then will execute standard 'send' command.
 - report                 : Will merge and rebase your code from the current testing branch to any branch you want. Then it will propose to remove your testing branch, like is proposed by 'remove' command.
 - push-to <Server>       : Will merge all update on your current branch to the server testing branch, and send the update to the remote box (like --send)
 - remove-from <Server>   : Will remove any configuration built by --push-to to send commits to your remote server.

Options:
 --repo <REPONAME> : Without this option, by default, it will select maestro as repository. You can work with a different one.
                     you can set TEST_REPONAME Variable.
 --repo-dir <DIR>  : By default, the path owned by root, is /opt/config/production/git/ by convention (puppet references). You can change it.
                     If the DIR doesn't exist, it will be created by $BASE
                     You can set TEST_REPODIR Variable.
 --ref remote|local: During a configure, your testing branch code reference will be the remote server if you set 'remote' otherwise, it will be your local repository as the testing code data.
 --commit <Msg>    : Will commit your code, with a specific <message>
 --commit-all <Msg>: Same as --commit, but the commit will add all tracked updated files to the commit.
 --fixup <Commit>  : Will commit with 'fixup!' prefix your commit message for use with rebase --autosquash. See git help commit for details.
                     If you set 'last' to <Commit>, test-box will search for the last unfixed commit number.
 --squash <Commit> : Will commit with 'squash!' prefix your commit message for use with rebase --autosquash. See git help commit for details.

This script helps to implement everything to create a test environment connected to a testing local branch.
It helps you to test some code controlled by git (limit data loss risk, and environment controlled.) on a remote kit."
  exit
}

#function Error
#{
# echo "ERROR! $2"
# exit $1
#}

function task_exit
{
 Error 1 "Last commands fails. ${1}. Please review and fix it before retrying."
}

function local_task
{
 echo "[[1m$USER@$HOSTNAME $(pwd)[0m] $ [1;33m$*[0m"
 eval "$*" 2>&1 | grep -v "Shared connection "
 return $?
}

function fix_ero_ip
{
  echo "$ERO_IP" | grep @
  if [ $? -eq 0 ]; then
     ERO_IP_SHOW=$(echo $ERO_IP | cut -d "@" -f 2)
  else
     ERO_IP_SHOW=$ERO_IP
  fi  
  ssh-keygen -R $ERO_IP_SHOW
}

function remote_task
{
 echo "[[1m$REMOTE_USER@$ERO_IP_SHOW ~[0m] $ [1;33m$*[0m"
 eval "ssh $CONNECTION $*" 2>&1 | grep -v "Shared connection "
 return $?
}

function remote_root
{
 echo "[[1mroot@$ERO_IP_SHOW ~[0m] $ [1;33m$*[0m"
 eval "ssh $CONNECTION sudo -i \"bash -c \\\"$*\\\"\"" 2>&1 | grep -v "Shared connection "
 return $?
}

function remote_root_task
{
 echo "[[1mroot@$ERO_IP_SHOW $REPO_DIR$REPO[0m] $ [1;33m$*[0m"
 eval "ssh $CONNECTION sudo -i \"bash -c 'cd $REPO_DIR/$REPO ; $*'\"" 2>&1 | grep -v "Shared connection "
 return $?
}

function configure_from_local
{
 if ssh $CONNECTION [ ! -d git/${REPO}.git ]
 then
    remote_task "\"mkdir -p git ; git init --bare git/${REPO}.git\""
 fi
 echo "Creating local branch..."

 local_task git remote add testing-$ERO_IP "$ERO_IP:git/${REPO}.git"
 local_task git checkout -b testing-$USER-$ERO_IP
 local_task git push testing-$ERO_IP testing-$USER-$ERO_IP:testing-$USER
 local_task git branch --set-upstream-to=testing-$ERO_IP/testing-$USER

 if ssh $CONNECTION [ ! -d $REPO_DIR/$REPO ]
 then
    echo "Warning! The remote repository is not available.
Reminder: while booting your box, set --meta 'test-box=$REPO;testing-$USER'
You can add more test-box repository, like 'test-box=RepoName1;testing-$USER|RepoName2;testing-$USER[|...;...]'"
    return
 fi
 remote_root_task "git remote add testing /home/$REMOTE_USER/git/${REPO}.git/"
 remote_root_task "git fetch testing"
 #ssh $CONNECTION sudo -i "bash -c 'cd $REPO_DIR/${REPO} ; git remote add testing /home/ubuntu/git/${REPO}.git/ ; git fetch testing'"
 echo "Creating remote branch..."
 check_remote_branch newbranch
}

function check_remote_branch
{
 REM_BRANCH="$(ssh -o StrictHostKeyChecking=no -t "$ERO_IP" sudo -i "bash -c 'cd $REPO_DIR/${REPO} ; git rev-parse --abbrev-ref HEAD'" | dos2unix)"
 case "$REM_BRANCH" in
   "master" )
      remote_root_task "git stash -k -u "
      if [ "$1" = newbranch ]
      then
         remote_root_task "git checkout --track remotes/testing/testing-$USER"
      else
         remote_root_task "git checkout testing-$USER"
      fi
      ;;
   "testing-$USER")
      remote_root_task "git pull testing testing-${USER}"
      ;;
   "*")
      echo "Approval required: The remote repository $REPO is enabled on branch ${REM_BRANCH}. You need to confirm that you want to move to own branch"
      while true
      do
         read -i y -p "Enter y or n" -n 1 ANS
         case "$ANS" in
            y|Y)
              if [ "$1" = newbranch ]
              then
                 remote_root_task "git stash -k -u"
                 remote_root_task "git checkout -B --track remotes/testing/testing-$USER"
              else
                 remote_root_task "git checkout testing-$USER"
              fi
              break;;
            n|N)
              echo "Ok. Note that you have not swithed to your own branch. a git pull won't get your testing code. You will need to configure it again if you want to get your code to test."
              ssh -O exit $CONNECTION
              exit
              break;;
         esac
      done
      ;;
 esac
}

function configure_from_remote
{
 echo "Checking remote repository..."
 if ssh $CONNECTION [ ! -d $REPO_DIR/$REPO ]
 then
    Error 1 "$REPO_DIR/$REPO was not found on the remote server $ERO_IP"
 fi
 if ssh $CONNECTION [ ! -d git/${REPO}.git ]
 then
    remote_task "\"mkdir -p git ; git init --bare git/${REPO}.git\""
 fi
 remote_root_task "git remote add testing /home/$REMOTE_USER/git/${REPO}.git/"
 remote_root_task "git push testing HEAD:testing-$USER"
 remote_root_task "chown -R $REMOTE_USER:\\\$(id -gn $REMOTE_USER) /home/$REMOTE_USER/git/${REPO}.git"
 remote_root_task "git fetch testing"
 remote_root_task "git checkout --track remotes/testing/testing-$USER"

 local_task git remote add testing-$ERO_IP "$ERO_IP:git/${REPO}.git"
 local_task git fetch testing-$ERO_IP
 local_task git checkout --track remotes/testing/testing-$USER -b testing-$USER-$ERO_IP

}

function do_send()
{ # Function which describe how to send the update to the remote server.
 fix_ero_ip

 local_task git push testing-$ERO_IP HEAD:testing-$USER
 CONNECTION="-o ControlPath=~/.ssh/%h_%p_%r -t -o StrictHostKeyChecking=no $ERO_IP"
 ssh -o ControlMaster=yes -o ControlPath=~/.ssh/%h_%p_%r -o ControlPersist=60 $CONNECTION -f -N
 if [ $? -ne 0 ]
 then
    Error 1 "Unable to connect to '$ERO_IP'. Check the IP address. You may need to use ssh-add to add the required identity to access the ero box."
 fi
 REMOTE_USER="$(ssh $CONNECTION "id -un" | dos2unix)"
 check_remote_branch
 remote_root_task git reset --hard testing/testing-$USER
 remote_root_task git clean -f
 remote_root_task git pull testing testing-$USER
}

function do_add_all
{
 echo "Added tracked AND untracked files to commit"
 git add -A :/
}

function do_configure
{
 fix_ero_ip
 echo "Checking kit connection..."
 CONNECTION="-o ControlPath=~/.ssh/%h_%p_%r -t -o StrictHostKeyChecking=no $ERO_IP"
 ssh -o ControlMaster=yes -o ControlPath=~/.ssh/%h_%p_%r -o ControlPersist=60 $CONNECTION -f -N
 if [ $? -ne 0 ]
 then
    Error 1 "Unable to connect to '$ERO_IP'. Check the IP address. You may need to use ssh-add to add the required identity to access the ero box configure your ~/.ssh/config.
Typical input you can add in your .ssh/config:

host 15.125.*
        user ubuntu
        StrictHostKeyChecking no
        IdentityFile ~/.hpcloud/keypairs/nova.pem
        ProxyCommand corkscrew MyProxy 8080 %h %p # <= This line is optional. Required if direct access is prohibited.
"
 fi

 REMOTE_USER="$(ssh $CONNECTION id -un | dos2unix)"

 if [ "$REF" = local ]
 then
    configure_from_local
 else
    configure_from_remote
 fi
 ssh -O exit $CONNECTION
 printf "[1mDONE[0m\nYou are now in a new testing branch. Every commits here are specifics to this branch. a git push will move your code to the remote kit.
On the server, as root, you can do a git pull from $REPO_DIR/${REPO}. And test your code.

When you are done, you will be able to merge to the master branch or any other branch you would use. As your commits were for testing, you may need to merge all your commits to one. So, think to use 'git rebase -i' to merge your pending commits to few commits before git push (or git-push for git review)\n"
}

function do_commit
{
 OPT="$1"
 shift
 if [ -n "$1" ]; then
    message=$1
 else
    message="Anonymous commit $(date '+%Y-%d-%m %H:%M:%S')"
 fi
 case "$OPT" in
   "--commit-all")
      git commit -am "$message"
      ;;
   "--commit")
      git commit -m "$message"
      ;;
   '--squash' | "--fixup" )
      git commit $OPT $1
      ;;
 esac
 if [ $? -ne 0 ]
 then
    Error 1 "Unable to commit your code. Please review git error and instructions and retry."
 fi
}

REF=local
BIN_PATH=$(cd $(dirname $0); pwd)

# Load build.d files

for INC_FILE in $BIN_PATH/bash.d/*.d.sh
do
  source $INC_FILE
done


if [ $# -eq 0 ]
then
   Help
fi

if [ "$TEST_REPONAME" != "" ]
then
   REPO="$TEST_REPONAME"
else
   REPO="maestro"
fi

if [ "$TEST_REPODIR" != "" ]
then
   REPO_DIR="$TEST_REPODIR"
else
   REPO_DIR="/opt/config/production/git/"
fi

OPTS=$(getopt -o h -l ref:,repo-dir:,repo:,configure:,send,ssend,commit-all:,commit:,fixup:,squash:,report:,remove,push-to:,remove-from: -- "$@" )
if [ $? != 0 ]
then
    Help "Invalid options"
fi
eval set -- "$OPTS"

while [ $# -ne 0 ]
do
  case "$1" in
    "--ref")
       shift
       case "$1" in
        "remote"|"local" )
           REF=$1
           ;;
        *)
           Error 1 "Incorrect option '$1' for --ref. It accepts only 'remote' or 'local' option."
           ;;
       esac
       shift
       ;;
    "--repo-dir")
       shift
       REPO_DIR="$1"
       shift;;
    "--repo")
       shift
       REPO="$1"
       shift;;
    "--configure")
       shift
       ERO_IP="$1"
       if [ "$ERO_IP" = "" ]
       then
           echo "Error: configure requires an IP address or an hostname to contact."
           Help
       fi
       ACTION="CONFIGURE"
       shift;;
     "--send")
       ACTION="SEND"
       shift;;
     "--ssend")
       shift
       do_add_all
       do_commit --commit-all "$1"
       ACTION="SEND"
       shift;;
     "--commit-all")
       shift
       do_add_all
       do_commit --commit-all "$1"
       shift;;
     "--commit" | "--fixup" | "--squash")
       if [ "$(echo "$2" | cut -c1-2)"  = -- ]
       then
          do_commit "$1" ""
       else
          if [ "$2" = "last" ]
          then
             COMMITID="$(git log --oneline | grep -v fixup | head -n 1 | awk '{ print $1 }')"
             do_commit "$1" "$COMMITID"
          else
             do_commit "$1" "$2"
          fi
          shift
       fi
       shift;;
       # Adding this repository PATH to the test-box list to send out.
     "--report")
       shift
       REPORT_BRANCH="$1"
       if [ "$REPORT_BRANCH" = "" ]
       then
           echo "Error: report requires a valid local branch in your $REPO repository."
           Help
       fi
       ACTION="REPORT"
       shift;;
     "--remove-from")
       ACTION="REMOVE"
       REMOVE_BRANCH=testing-${USER}-$2
       shift
       shift;;
     "--remove")
       ACTION="REMOVE"
       shift;;
     "--push-to")
       ACTION="SYNC"
       ERO_IP=$2
       shift;shift;;
     --) 
       shift; break;;
     *)
       Error 1 "Incorrect option '$1'. Run this script without parameters to visualize the correct options."
       exit;;
  esac
done

git rev-parse --show-toplevel 2>/dev/null
if [ $? -ne 0 ]
then
   Error 1 "You are not in a git repository. Move to a $REPO clone repo directory and retry"
fi

if [ "$(git remote -v | grep "origin *.*$REPO")" = "" ]
then
   Error 1 "Are you sure to be in [1m$REPO[0m repository??? Move to a $REPO clone repo directory or set TEST_REPONAME to the one you want and retry."
fi

CUR_BRANCH=$(git rev-parse --abbrev-ref HEAD)


case $ACTION in
    "CONFIGURE")
        do_configure
     ;;
    "SYNC")
     if [ "$(echo $CUR_BRANCH | grep "^testing-${USER}-.*$")" != "" ]
     then
        Error 1 "option --push-to cannot be used from a testing branch. Do your update from any other branch you want. --push-to will push it to your testing branch with merge feature."
     fi
     REST_BRANCH=$CUR_BRANCH
     if [ "$(git branch | grep "\w*testing-${USER}-$ERO_IP$")" = "" ]
     then
        do_configure
        local_task git checkout $REST_BRANCH
        exit 
     fi
     local_task git checkout testing-${USER}-$ERO_IP
     local_task git merge $REST_BRANCH

     # Do SENT
     CUR_BRANCH=$(git rev-parse --abbrev-ref HEAD)
     if [ "$(echo $CUR_BRANCH | grep "^testing-${USER}-.*$")" = "" ]
     then
        Error 1 "You are not in a known eroplus testing branch. Do git checkout to move out to an eroplus testing branch before removing it."
     fi

     fix_ero_ip

     do_send
     ssh -O exit $CONNECTION
     # SEND done
     local_task git checkout $REST_BRANCH
     ;;
    "SEND")
     if [ "$(echo $CUR_BRANCH | grep "^testing-${USER}-.*$")" = "" ]
     then
        Error 1 "You are not in a known eroplus testing branch. Do git checkout to move out to an eroplus testing branch before removing it."
     fi

     ERO_IP=$(echo $CUR_BRANCH | sed "s/^testing-${USER}-"'\(.*\)$/\1/g')
     do_send
     ssh -O exit $CONNECTION
     ;;
    "REPORT")
     echo "Currently not implemented."
     ;;
    "REMOVE")
     set -x
     if [ "$REMOVE_BRANCH" != "" ]
     then
        local_task git checkout $REMOVE_BRANCH || task_exit ""
        CUR_BRANCH=$(git rev-parse --abbrev-ref HEAD)
     fi
     set +x
     if [ "$(echo $CUR_BRANCH | grep "^testing-${USER}-.*$")" = "" ]
     then
        Error 1 "You are not in a known maestro testing branch. Do git checkout to move out to an eroplus testing branch before removing it."
     fi
     ERO_IP=$(echo $CUR_BRANCH | sed "s/^testing-${USER}-"'\(.*\)$/\1/g')
     fix_ero_ip

     echo "Removing local branch..."
     local_task git checkout master
     local_task git branch -D $CUR_BRANCH
     local_task git remote remove testing-$ERO_IP

     echo "Checking kit connection..."
     CONNECTION="-o ControlPath=~/.ssh/%h_%p_%r -t -o StrictHostKeyChecking=no $ERO_IP"
     ssh -o ControlMaster=yes -o ControlPath=~/.ssh/%h_%p_%r -o ControlPersist=60 $CONNECTION -f -N
     if [ $? -ne 0 ]
     then
        Error 1 "Unable to connect to '$ERO_IP'. Check the IP address. You may need to use ssh-add to add the required identity to access the ero box."
     fi
     REMOTE_USER="$(ssh $CONNECTION id -un | dos2unix)"
     echo "Removing remote branch... The remote testing repo won't be removed to prevent other tester to loose their branch."
     remote_root_task "git reset --hard HEAD"
     remote_root_task "git checkout master"
     remote_root_task "git stash pop"
     remote_root_task "git branch -D testing-$USER"
     remote_root_task "cd /home/$REMOTE_USER/git/${REPO}.git/;git branch -D testing-$USER"
     # Do not remove the testing remote, if others are using the same box testing other things.
     remote_root_task "git branch | grep -i testing"
     if [ $? -eq 1 ]
     then
       remote_root_task "git remote rm testing"
       echo "git remote <testing> was deleted."
     else 
       echo "Note: On the remote server, I did not remove the git remote testing, which is used by others."
     fi          
     ssh -O exit $CONNECTION
     echo "$CUR_BRANCH fully removed."
     ;;
 esac
