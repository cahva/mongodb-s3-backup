#!/bin/bash
set -e

function removeinvalidindexoptions {
  echo "Cleaning invalid index (safe:null)"
  for filename in dump/**/*.metadata.json
  do
    mv "$filename" "$filename.tmp"
    sed -e 's/,"safe":null//g' \
        -e 's/"safe":null,//g' <"$filename.tmp" >"$filename"
    rm "$filename.tmp"
  done
}

function restore {
  KEY=$1
  BASENAME=$(basename "$KEY")
  aws s3api get-object --bucket "$S3BUCKET" --key "$KEY" "/backup/$BASENAME"
  tar -zxvf "/backup/$BASENAME" -C /backup
  removeinvalidindexoptions

  mongorestore \
    --host "$MONGO_HOST" \
    --drop \
    "${general_opts[@]}" \
    "${restore_opts[@]}" \
    dump/
  echo "Cleaning up..."
  rm -rf dump/ "/backup/$BASENAME"
}

# Setup arrays for options
general_opts=()
list_opts=()
restore_opts=()

if [ -z "$AWS_ACCESS_KEY_ID" ]; then
  echo "AWS_ACCESS_KEY_ID must be set"
  exit 1
fi

if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
  echo "AWS_SECRET_ACCESS_KEY must be set"
  exit 1

fi

if [ -z "$S3BUCKET" ]; then
  echo "S3BUCKET must be set"
  exit 1
fi

if [ -z "$DATEFORMAT" ]; then
  DATEFORMAT='%Y-%m-%d_%H%M%S'
fi

if [ -z "$FILEPREFIX" ]; then
  FILEPREFIX=''
fi

if [ -z "$MONGO_HOST" ]; then
  MONGO_HOST="mongo"
fi

if [ -z "$MONGO_PORT" ]; then
  MONGO_PORT="27017"
fi

if [ -n "$MONGO_USER" ]; then
  general_opts+=(--username "$MONGO_USER")
  restore_opts+=(--authenticationDatabase "$MONGO_DB")
fi

if [ -n "$MONGO_PASSWORD" ]; then
  general_opts+=(--password "$MONGO_PASSWORD")
fi

if [ -n "$MONGO_DB" ]; then
  general_opts+=(--db "$MONGO_DB")
fi

if [ -n "$FOLDER" ]; then
  list_opts+=(--prefix "$FOLDER")
fi

if [ "$1" == "backup" ]; then
  echo "Starting backup..."

  DATE=$(date +$DATEFORMAT)
  FILENAME=$FILEPREFIX$DATE.tar.gz
  FILE=/backup/backup-$FILENAME

  if [ -n "$FOLDER" ]; then
    FULLPATH="$FOLDER/$FILENAME"
  else
    FULLPATH="$FILENAME"
  fi
  mongodump --host "$MONGO_HOST" --port "$MONGO_PORT" "${general_opts[@]}"
  rc=$?; if [[ $rc != 0 ]]; then echo "Error with mongodump: $rc"; exit $rc; fi

  tar -zcvf "$FILE" dump/
  aws s3 cp "$FILE" "s3://$S3BUCKET/$FULLPATH"

  rc=$?; if [[ $rc != 0 ]]; then echo "Error with S3 upload: $rc"; exit $rc; fi

  echo "Cleaning up..."
  rm -rf dump/ "$FILE"
elif [ "$1" == "list" ]; then
  echo "Listing backups..."

  aws s3api list-objects --bucket "$S3BUCKET" "${list_opts[@]}" --query 'Contents[].{Key: Key, Size: Size}' --output table
elif [ "$1" == "latest" ]; then
  echo "Determining backup to restore..."

  S3KEY=$(aws s3api list-objects --bucket "$S3BUCKET" "${list_opts[@]}" --query "reverse(sort_by(Contents,&LastModified))"|jq -r '.[0].Key')
  echo "Restoring $S3KEY."
  restore "$S3KEY"
else
  echo "Starting restore"

  FILE=$1
  restore "$FILE"
fi
