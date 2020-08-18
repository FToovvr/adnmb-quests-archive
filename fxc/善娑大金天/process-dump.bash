#!/usr/bin/env bash

LUWEI_DOWNLOAD_PATH="./luwei_download"
DUMP_PATH="./dump"

rm -rf "$DUMP_PATH"
mkdir -p "$DUMP_PATH"/{pages,assets}

function moveImageFiles {
    if [[ -z "$1" ]]; then
        return
    fi
    for FILENAME in $1; do
        cp "$LUWEI_DOWNLOAD_PATH/images/$FILENAME" "$DUMP_PATH/assets/$FILENAME"
    done
}

for DATA_PATH in "$LUWEI_DOWNLOAD_PATH"/data/*; do
    DATA_FILENAME=$(basename $DATA_PATH)
    DATA_PAGE_NUMBER=${DATA_FILENAME%.*}
    
    CONTENT=$(cat $DATA_PATH)
    CONTENT=${CONTENT:11:${#CONTENT}-11-2}
    
    if [[ $DATA_PAGE_NUMBER -eq 1 ]]; then
        PROCESSED_DATA=$(jq '. | del(.replys, .replyCount)' <<< "$CONTENT")
        echo "$PROCESSED_DATA" > "$DUMP_PATH"/thread.json
        FILENAMES=$(jq -r '.fileName' <<< "$PROCESSED_DATA")
        moveImageFiles "$FILENAMES"
    fi
    
    PROCESSED_DATA=$(jq '.replys | map(select(.userid != "芦苇"))' <<< "$CONTENT")
    echo "$PROCESSED_DATA" > "$DUMP_PATH"/pages/$DATA_PAGE_NUMBER.json
    FILENAMES=$(jq -r '. | map(select(.fileName? and .fileName != "") | .fileName) | @tsv' <<< "$PROCESSED_DATA")
    moveImageFiles "$FILENAMES"
done