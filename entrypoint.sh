#!/bin/bash
set -u

repo_token=$1

if [ "$GITHUB_EVENT_NAME" != "milestone" ]; then
    echo "::debug::The event name was '$GITHUB_EVENT_NAME'"
    exit 0
fi

echo "::debug::GitHub event path $GITHUB_EVENT_PATH"
echo "::debug::GitHub event path $GITHUB_EVENT_PATH"

event_type=$(jq --raw-output .action $GITHUB_EVENT_PATH)

if [ $event_type != "closed" ]; then
    echo "::debug::The event type was '$event_type'"
    exit 0
fi

milestone_name=$(jq --raw-output .milestone.title $GITHUB_EVENT_PATH)

IFS='/' read owner repository <<< "$GITHUB_REPOSITORY"

git_release_manager_output=$(dotnet gitreleasemanager create \
            --milestone $milestone_name \
            --targetcommitish $GITHUB_SHA \
            --token $repo_token \
            --owner $owner \
            --repository $repository 2>&1 )

 if [ $? -ne 0 ]; then
    echo "::error::Failed to create the release draft"
    exit 1
 fi

release_url=$(echo $git_release_manager_output | grep -A 1 'Drafted release is available at' | sed "s/.*available at: //;s/\s.*//" )

echo "::debug::------Release url '$release_url'"
echo "::set-output name=release-url::$release_url"

exit 0