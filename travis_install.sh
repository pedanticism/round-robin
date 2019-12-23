!#/bin/bash
set -evx
 
pip install -r requirements.txt
curl -sLo /tmp/terraform.zip https://releases.hashicorp.com/terraform/0.12.17/terraform_0.12.17_linux_amd64.zip
unzip /tmp/terraform.zip -d /tmp
curl -sLo /tmp/packer.zip    https://releases.hashicorp.com/packer/1.5.1/packer_1.5.1_linux_amd64.zip
unzip /tmp/packer.zip -d /tmp
mkdir -p ~/bin/
mv /tmp/terraform ~/bin/ 
mv /tmp/packer    ~/bin/

export PATH="~/bin:$PATH"