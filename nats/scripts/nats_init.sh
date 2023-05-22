#!/bin/sh
# script to bootstrap a nats operator environment

if nsc describe operator; then
    echo "operator exists, not overwriting config"
    exit 0
fi

echo "Cleaning up NATS environment"
rm -rf /nsc/*

echo "Creating NATS operator"
nsc add operator --generate-signing-key --sys --name LOCAL
nsc edit operator -u 'nats://nats:4222'
nsc list operators
nsc describe operator

export OPERATOR_SIGNING_KEY_ID=`nsc describe operator -J | jq -r '.nats.signing_keys | first'`

echo "Creating NATS account for apis"
nsc add account -n INFRA9APIS -K ${OPERATOR_SIGNING_KEY_ID}
nsc edit account INFRA9APIS --sk generate --js-mem-storage -1 --js-disk-storage -1 --js-streams -1 --js-consumer -1
nsc describe account INFRA9APIS

export ACCOUNTS_SIGNING_KEY_ID=`nsc describe account INFRA9APIS -J | jq -r '.nats.signing_keys | first'`

echo "Creating NATS user for api"
nsc add user -n USER -K ${ACCOUNTS_SIGNING_KEY_ID}
nsc describe user USER

echo "Generating NATS resolver.conf"
nsc generate config --mem-resolver --sys-account SYS --config-file /nats/resolver.conf --force

echo "Dumping NATS user creds file"
nsc --data-dir=$DEVCONTAINER_DIR/nsc/nats/nsc/stores generate creds -a INFRA9APIS -n USER > /api-creds/user.creds

echo "Dumping NATS sys creds file"
nsc --data-dir=$DEVCONTAINER_DIR/nsc/nats/nsc/stores generate creds -a SYS -n sys > /api-creds/sys.creds

# Make things readable to all users
chmod 666 -R /nsc/*
chmod 666 /api-creds/*
