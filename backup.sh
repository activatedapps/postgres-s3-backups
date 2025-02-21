#!/bin/bash

set -o errexit -o nounset -o pipefail

export AWS_PAGER=""

s3() {
    aws s3 --endpoint-url "$DO_ENDPOINT" "$@"
}

s3api() {
    aws s3api "$1" --endpoint-url "$DO_ENDPOINT" --bucket "$DO_BUCKET_NAME" "${@:2}"
}

bucket_exists() {
    s3 ls "$DO_BUCKET_NAME" &> /dev/null
}

create_bucket() {
    echo "Bucket $DO_BUCKET_NAME doesn't exist. Creating it now..."

    # create bucket
    s3 mb "s3://$DO_BUCKET_NAME"
}

ensure_bucket_exists() {
    if bucket_exists; then
        return
    fi    
    create_bucket
}

pg_dump_database() {
    pg_dump  --no-owner --no-privileges --clean --if-exists --quote-all-identifiers "$DATABASE_URL"
}

upload_to_bucket() {
    # if the zipped backup file is larger than 50 GB add the --expected-size option
    # see https://docs.aws.amazon.com/cli/latest/reference/s3/cp.html
    s3 cp - "s3://$DO_BUCKET_NAME/$(date +%Y/%m/%d/backup-%H-%M-%S.sql.gz)"
}

main() {
    echo "Taking backup and uploading it to S3..."
    pg_dump_database | gzip | upload_to_bucket
    echo "Done."
}

main
