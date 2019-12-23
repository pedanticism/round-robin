

var os = require('os')
var http = require('http')

function handleRequest(req, res) {
  console.log('Request. Version:' + process.env.TRAVIS_BUILD_NUMBER)
  res.write('<HTML><BODY>')
  res.write('<P>Hi there! I\'m being served from ' + os.hostname() + '</P>')
  res.write('<P>AMI built from commit' + process.env.TRAVIS_COMMIT + '</P>')
  res.write('<P>Travis build numberc' + process.env.TRAVIS_BUILD_NUMBER + '</P>')
  res.write('</BODY></HTML>')
  res.end()
}

http.createServer(handleRequest).listen(3000)
