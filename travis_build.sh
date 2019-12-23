#!/bin/bash
set -evx
# Inject the commit hash into the service configuration
sed -i.bak -E "s/(GIT_HASH=).*/\1$TRAVIS_COMMIT/" ./nodejs/nodeapp.service

# Check the replace worked ok
cat ./nodejs/nodeapp.service

pushd packer
packer validate round-robin.json
packer build round-robin.json
popd

pushd terraform
terraform init -input=false
terraform plan -out ./tfplan.tmp
terraform apply -auto-approve "./tfplan.tmp"

popd
./scale_up_and_down.py