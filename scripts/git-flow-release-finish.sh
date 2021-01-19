#!/usr/bin/env bash

set -e

DIRTY_FILE="/tmp/git-flow-release~dirty.dat"
TAG_FILE="/tmp/git-flow-release~tag.dat"

if [[ ! -f "$DIRTY_FILE" ]]; then
	echo "Cannot detect that git-flow-release-start has been run."
	exit 1;
fi

dirty=`cat $DIRTY_FILE`
tag=`cat $TAG_FILE`

echo -e "\nrelease finish...\n"
git commit -am "chore: bump version ($tag)"
git checkout master
git merge release/$tag
git tag $tag
git push origin $tag
git push
git checkout develop
git merge release/$tag
git branch -d release/$tag
git push

if [ "$dirty" = true ]
then
	git stash pop
fi

rm $TAG_FILE
rm $DIRTY_FILE