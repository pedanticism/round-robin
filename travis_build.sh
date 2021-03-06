#!/bin/bash
set -evx
# Inject the build metadata into the service configuration
sed -i.bak -E "s/(TRAVIS_COMMIT=).*/\1$TRAVIS_COMMIT/" ./nodejs/nodeapp.service
sed -i.bak -E "s/(TRAVIS_BUILD_NUMBER=).*/\1$TRAVIS_BUILD_NUMBER/" ./nodejs/nodeapp.service

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

python3 scale_up_and_down.py