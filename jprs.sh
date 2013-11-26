#!/bin/bash
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

# Expecting repo to be setup with git-review -s already and for
# changes.txt to be populated with numerical change ids separated by newlines.

# Tested with repo and changes.txt in same directory as this script.

changelist=changes.txt
repo=tempest
sourcebranch=master
destbranch=$sourcebranch+pending
prefix="JPRS:"

read -a changearray <<< `cat $changelist`
pushd $repo
git checkout $sourcebranch
git pull
git checkout -B $destbranch

# strip colors, delete last "Found" line, and extract only change numbers
git-review --list | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g" | sed '$d' | cut -d " " -f1 > available.txt
read -a availablearray <<< `cat available.txt`

length=${#changearray[@]}
for (( i = 0; i < $length; i++ )); do
  if ! [[ ${availablearray[*]} =~ "${changearray[$i]}" ]]; then
    echo "$prefix Skipping change ${changearray[$i]}"
    unset changearray[$i]
    continue
  fi
  echo "$prefix Applying change ${changearray[$i]}"
  git-review -x ${changearray[$i]} $destbranch
  status=$?
  if [ $status -ne 0 ]; then
    echo "$prefix Error: git-review returned $status"
    exit
  fi
done

popd
cp $changelist $changelist.old
printf "%s\n" ${changearray[@]} > $changelist
echo "$prefix All done! Changes applied: ${changearray[@]}"
#diff -u $changelist.old $changelist
