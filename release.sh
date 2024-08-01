#!/bin/sh
#
# This script:
#   - creates a new tag
#   - updates all the action references to the new tag
#   - commits the changes
#   - pushes a new release
#
# The tag pattern is YYMM.0.XXX:
#   - YY: the year with two letters; e.g. 23 or 24
#   - MM: the month with two letters; e.g. 05 or 12
#   - XXX: an unique release number that starts counting at 101; e.g. 108 or 112
# This results in unique version numbers like 2407.0.101 or 2312.0.105
# that always go up and let you see how far behind you are.

set -o errexit
set -o nounset
set -o xtrace

# the year and month with two letters each; e.g. 2312 or 2407
MAJOR_MINOR=$(date -u +"%y%m")

# sync local tags with info from remote
git fetch \
  --prune \
  --prune-tags \
  --tags \
  --force

# the goal is to push a tagged commit that updates all @$version references.
# since we don't know which tags were already created, we start counting up
# and see which push is successful. that push needs to already have the
# correct changes. so we create an empty commit that is amended again and
# again until it is pushed successfully. then we're done.

git commit \
  --allow-empty \
  --message "this commit will be amended later"

# count up starting at 101 until 999 allowing 898 releases per month
for MICRO in $(seq 101 999); do

  # this is the version pattern
  VERSION=${MAJOR_MINOR}.0.${MICRO}

  # fails if the tag exists
  if git tag "v${VERSION}"; then

    bash update-action-references.sh "v${VERSION}"

    # output the changes to the console
    git diff

    # amend the initial commit with the changes
    git commit \
      --amend \
      --all \
      --message "update references to v${VERSION}"

    # update the tag reference to the latest commit before pushing
    git tag \
      --force \
      "v${VERSION}"

    # try pushing
    if git push origin "v${VERSION}"; then
      # if it worked, we're done
      break
    fi

    # remove the local tag if the push failed
    git tag --delete "v${VERSION}"

  fi

done
