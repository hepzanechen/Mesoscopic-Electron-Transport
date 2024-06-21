#!/bin/bash

# Branch with changes
SOURCE_BRANCH="master"

# Get all branches except the source branch
TARGET_BRANCHES=($(git branch | grep -v "$SOURCE_BRANCH" | sed 's/^[ *]*//'))

# Checkout the source branch
git checkout $SOURCE_BRANCH

# Loop through each target branch and merge changes
for BRANCH in "${TARGET_BRANCHES[@]}"
do
    git checkout $BRANCH
    git merge $SOURCE_BRANCH

    if [ $? -ne 0 ]; then
        echo "Merge conflicts occurred in $BRANCH. Resolve them manually."
        exit 1
    fi
done

# Switch back to the source branch
git checkout $SOURCE_BRANCH

echo "Changes successfully propagated to all target branches."
