#!/usr/bin/env bash

rm -rf data images
mkdir -p data images

function moveImageFiles {
    if [[ -z "$1" ]]; then
        return
    fi
    for FILENAME in $1; do
        cp "original/images/$FILENAME" "images/$FILENAME"
    done
}

for DATA_PATH in original/data/*; do
    DATA_FILENAME=$(basename $DATA_PATH)
    DATA_PAGE_NUMBER=${DATA_FILENAME%.*}
    
    CONTENT=$(cat $DATA_PATH)
    CONTENT=${CONTENT:11:${#CONTENT}-11-2}
    
    if [[ $DATA_PAGE_NUMBER -eq 1 ]]; then
        PROCESSED_DATA=$(jq '. | del(.replys, .replyCount)' <<< "$CONTENT")
        echo "$PROCESSED_DATA" > data/head.json
        FILENAMES=$(jq -r '.fileName' <<< "$PROCESSED_DATA")
        moveImageFiles "$FILENAMES"
    fi
    
    PROCESSED_DATA=$(jq '.replys | map(select(.userid != "芦苇"))' <<< "$CONTENT")
    echo "$PROCESSED_DATA" > data/$DATA_PAGE_NUMBER.json
    FILENAMES=$(jq -r '. | map(select(.fileName? and .fileName != "") | .fileName) | @tsv' <<< "$PROCESSED_DATA")
    moveImageFiles "$FILENAMES"
done