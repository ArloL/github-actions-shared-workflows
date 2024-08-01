#!/bin/bash
# This script updates all the action references to the first parameter.
# The second parameter is the name of the referenced repository.

set -o errexit
set -o nounset
set -o xtrace

reference=${1:-${GITHUB_HEAD_REF:-${GITHUB_REF_NAME:-$(git rev-parse --abbrev-ref HEAD)}}}
# escape all forward slashes with a backslash
reference=${reference//\//\\/}

repository=${2:-${GITHUB_REPOSITORY:-ArloL/actions}}
# escape all forward slashes with a backslash
repository=${repository//\//\\/}

# use gsed on e.g. macos if it is available; fall back to sed
hash gsed 2>/dev/null && SED='gsed' || SED='sed'

# update the version of every "local" action reference with sed
# in detail:
# s     <- substitute command
# |     <- first delimiter character; now comes the search regex
#   (   <- start first group
#   \s*  <- match all whitespace characters
#   uses: ${repository}   <- literal string match
#   [^@]+   <- match all characters except @
#   )   <- close first group
#   @   <- literal string match for the separator
#   (.*)    <- second group that matches everything after the @
# |     <- second delimiter character; now comes the replacement
#   \1  <- copies the whole text from the first group match
#   @   <- the separator between the action reference and the tag
#   v${VERSION}     <- the new version
# |     <- final delimiter character; finishes the replacement string
# g     <- global flag to replace every occurence

find .github/actions .github/workflows \
    -type f \
    \( -name "*.yml" -or -name "*.yaml" \) \
    -exec "${SED}" -i \
        -E \
        "s|(\s*uses: ${repository}[^@]+)@(.*)|\1@${reference}|g" \
        {} \;
