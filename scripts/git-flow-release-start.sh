#!/usr/bin/env bash

set -e

# Handle incorrect input
if [ -z "$1" ]
then
	echo "The second parameter (tag) must be given"
	exit 1
fi

# Find out if the current directory is dirty
if [[ $(git diff --stat) != '' ]]
then
  dirty=true
else
  dirty=false
fi

echo -e "\nrelease start...\n"

if [ "$dirty" = true ]
then
	git stash
fi

git checkout master
git fetch
git reset --hard origin/master
git checkout develop
mversion $1
git checkout -b release/$1

echo "Make release changes to this repository. Run \"grf\" to complete the release."

echo "$dirty" > /tmp/git-flow-release~dirty.dat
echo "$1" > /tmp/git-flow-release~tag.dat