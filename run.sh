#!/bin/bash

export $(grep -v '^#' .env | xargs)

if [[ -z $EXCLUDE_GROUP_REGEX ]]
then
  EXCLUDE_GROUP_REGEX=""
else
  EXCLUDE_GROUP_REGEX="|${EXCLUDE_GROUP_REGEX}"
fi

GITLAB_URL=$(echo ${GITLAB_URL} | sed "s|\(.*\)/|\1|g")

echo "EXCLUDE_GROUP=$EXCLUDE_GROUP_REGEX"
echo "GITLAB_URL=$GITLAB_URL"
echo "PRIVATE_TOKEN=$PRIVATE_TOKEN"

pages=$(curl -s -I -H "PRIVATE-TOKEN: $PRIVATE_TOKEN" ${GITLAB_URL}/api/v4/groups | grep -iP "x-total-pages" | grep -oP "\d+")

echo $pages

for page in `seq $pages`; do
    for group in $(curl -s -H "PRIVATE-TOKEN: $PRIVATE_TOKEN" ${GITLAB_URL}/api/v4/groups?page=$page | jq ".[].full_path" | grep -vE "(.*/)$EXCLUDE_GROUP_REGEX" | tr -d '"'); do
        echo "Start group $group"
        python gitlab-search.py ${GITLAB_URL}/ $PRIVATE_TOKEN $FILE_FILTER_REGEX $SEARCH_TEXT_REGEX $group --internal-debug --filename-is-regex -o ${DIR_REPORT}${group}_report.json
    done
done
echo "Finish"

