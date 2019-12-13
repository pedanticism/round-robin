#! /bin/bash
sudo apt-get install -y curl
curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -
sudo apt-get -y install nodejs

cat << EOF > /etc/systemd/system/nodeapp.service
[Unit]
Description=My Node app

[Service]
ExecStart=/usr/bin/node /var/www/nodeapp/index.js
Restart=always
User=nobody
# Note Debian/Ubuntu uses 'nogroup', RHEL/Fedora uses 'nobody'
Group=nogroup
Environment=PATH=/usr/bin:/usr/local/bin
Environment=NODE_ENV=production
WorkingDirectory=/var/www/nodeapp

[Install]
WantedBy=multi-user.target

EOF
# Clearly not the scalable way to do this. 
# As size of app increases, need to bake the content into the AMI
# Or use a deployment tool like codebuild agent etc.

mkdir -p /var/www/nodeapp/
cat << EOF2 > /var/www/nodeapp/index.js
#!/usr/bin/env node
var os = require('os')
var http = require('http')
function handleRequest(req, res) {
  console.log('Request')
  res.write('Hi there! I\'m being served from ' + os.hostname())
  res.end()
}
http.createServer(handleRequest).listen(3000)
EOF2

### install the service
systemctl start nodeapp
systemctl enable nodeapp