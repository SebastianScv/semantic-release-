#!/bin/bash

# File paths
json_file="release_data.json"

# Default branch if no parameter is provided
default_branch="main"
branch="${1:-$default_branch}"

# Initialize or create the JSON file if it doesn't exist
if [ ! -f "$json_file" ]; then
    echo '[{"version": "2.2", "date": "", "fixes": [], "features": [], "lastCommitId": ""}]' > "$json_file"
    echo "Initialized an empty JSON file at $json_file."
fi

# Fetch current date
current_date=$(date +%d/%m/%Y)

# Fetch the most recent commit ID in the branch
latest_commit_id=$(git rev-parse HEAD)

# Determine the starting commit ID based on lastCommitId
last_commit_id=$(jq -r '.[0].lastCommitId // empty' $json_file)
if [[ "$last_commit_id" == "$latest_commit_id" ]]; then
    echo "No new commits since the last run."
    exit 0
fi
commit_range=${last_commit_id:+$last_commit_id..}$latest_commit_id

# Determine the next version number
last_version=$(jq -r '.[0].version' $json_file)
if [[ "$last_version" =~ ^([0-9]+)\.([0-9]+)$ ]]; then
    major=${BASH_REMATCH[1]}
    minor=${BASH_REMATCH[2]}
    next_version="$major.$((minor + 1))"
else
    next_version="2.3"  # Default start version if pattern matching fails
fi

# Fetch commit messages from the specified branch, starting from the last commit processed
IFS=$'\n' # change the Internal Field Separator to newline
commit_entries=$(git log $branch $commit_range --pretty=format:"%H %s")

# Prepare new version entry and prepend it to the array
jq --arg date "$current_date" --arg next_version "$next_version" --arg latest_commit_id "$latest_commit_id" \
   '. = [{"version": $next_version, "date": $date, "fixes": [], "features": [], "lastCommitId": $latest_commit_id}] + .' $json_file > temp.json && mv temp.json $json_file

echo "Processing new commits from branch '$branch'..."

# Process each commit message
found=0
for entry in $commit_entries; do
    commit_id=$(echo "$entry" | cut -d ' ' -f1)
    msg=$(echo "$entry" | cut -d ' ' -f2-)
    if [[ "$msg" =~ ^(feat|fix|hotfix|bug):\ DIJ\-[0-9]+ ]]; then
        type=$(echo "$msg" | cut -d':' -f1)
        jira_id=$(echo "$msg" | grep -o 'DIJ-[0-9]\+')
        description=$(echo "$msg" | cut -d' ' -f3-)

        # Update JSON file based on type
        if [[ "$type" == "feat" ]]; then
            jq --arg jira_id "$jira_id" --arg description "$description" \
               '.[0].features += [{"jiraId": $jira_id, "title": $description}]' $json_file > temp.json && mv temp.json $json_file
        else
            jq --arg jira_id "$jira_id" --arg description "$description" \
               '.[0].fixes += [{"jiraId": $jira_id, "title": $description}]' $json_file > temp.json && mv temp.json $json_file
        fi
        found=1
    fi
done

if [ $found -eq 0 ]; then
    echo "No new relevant commits found to update the JSON file."
else
    echo "Finished processing new commits."
fi
