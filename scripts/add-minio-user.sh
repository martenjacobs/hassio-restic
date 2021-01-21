#!/bin/bash

echo -n "Back-up repository name: "
read CLIENT

USER="$CLIENT-restic"

echo -n "Client password: "
read PASSWD

echo -n "MinIO alias: "
read MINIO

echo -n "Will create a user called \"$USER\" with password \"$PASSWD\" on minio instance \"$MINIO\". Continue? (y/n) "
read CONT
if [[ "$CONT" != "y" ]]; then
  exit 1
fi

# create and enable the user
mc admin user add $MINIO $USER "$PASSWD"
mc admin user enable $MINIO $USER

# create a policy
cat <<EOF | mc admin policy add $MINIO $USER /dev/stdin 
{
  "Version": "2012-10-17",
  "Statement": [
        {
            "Sid": "ListObjectsInBucket",
            "Effect": "Allow",
            "Action": ["s3:ListBucket"],
            "Resource": ["arn:aws:s3:::restic-backups"]
        },
        {
            "Sid": "AllObjectActions",
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": ["arn:aws:s3:::restic-backups/$CLIENT/*"]
        }
    ]
}
EOF

# attach the policy to the user
mc admin policy set $MINIO $USER user=$USER

# echo the settings to the user
echo "Use these environment variables:"
echo "AWS_ACCESS_KEY_ID: '$USER'"
echo "AWS_SECRET_ACCESS_KEY: '$PASSWD'"
echo "RESTIC_REPOSITORY: 's3:<minio server address>/restic-backups/$CLIENT'"

