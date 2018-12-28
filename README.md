# Backup / Restore mongodb using AWS S3 with Docker

This was heavily inspired by [this repository](https://github.com/firstandthird/mongobackup-s3). Reason for a new repo instead of fork.

- main repo has not been updated for a long time
- it missed a few options:
  - no auth option
  - could not set database
  - could not set folder where to backup/restore

With this you can:
- backup database(s) to s3
- restore (latest or invidual backup)
- list backup files

## How to run

Copy `.env.example` -> `.env` (or the name of your liking). It will be used as `--env-file` parameter when running docker command.

### Env variables used

- AWS_ACCESS_KEY_ID **required**
- AWS_SECRET_ACCESS_KEY **required**
- DATEFORMAT - default `%Y-%m-%d_%H%M%S`
- (*) FILEPREFIX - prefix the filename before the date
  - filename will consist by default of the [DATEFORMAT].tar.gz. Use this if you want to prefix before the date.
- (*) FOLDER - folder in your S3 bucket
- MONGO_DB
- MONGO_HOST - default is "mongo"
- MONGO_PASSWORD
- MONGO_PORT - default is 2017
- MONGO_USER
- S3BUCKET **required**

When using FOLDER the final filename will be

```
s3://{S3BUCKET}/{FOLDER}/{FILEPREFIX}{DATEFORMAT}.tar.gz
```

If folder is not set it will be

```
s3://{S3BUCKET}/{FILEPREFIX}{DATEFORMAT}.tar.gz
```
---

### Backup to s3 bucket

```
docker run --rm --env-file .env cahva/mongodb-s3-backup backup
```

### List backup files from s3 bucket

```
docker run --rm --env-file .env cahva/mongodb-s3-backup list
```

### Restore latest from s3 bucket

```
docker run --rm --env-file .env cahva/mongodb-s3-backup latest
```

### Restore from chosen backup file

```
docker run --rm --env-file .env cahva/mongodb-s3-backup [backup filename]
```