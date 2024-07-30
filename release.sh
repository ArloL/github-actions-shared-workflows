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

MAJOR_MINOR=$(date -u +"%y%m")

# sync local tags with info from remote
git fetch \
    --prune \
    --prune-tags \
    --tags \
    --force

# create an empty commit that will be amended later
git commit \
    --allow-empty \
    --message "this commit will be amended later"

for MICRO in $(seq 101 999); do

    VERSION=${MAJOR_MINOR}.0.${MICRO}

    if git tag "v${VERSION}"; then

        bash update-action-references.sh "v${VERSION}"

        git diff

        # commit the changes
        git commit \
            --amend \
            --all \
            --message "update references to v${VERSION}"

        # update the tag reference to the latest commit before pushing
        git tag \
            --force \
            "v${VERSION}"

        if git push origin "v${VERSION}"; then
            break
        fi

        # remove the local tag if the push failed
        git tag --delete "v${VERSION}"

    fi

done
