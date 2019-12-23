

var os = require('os')
var http = require('http')

function handleRequest(req, res) {
  console.log('Request')
  res.write('Hi there! I\'m being served from ' + os.hostname())
  res.write('I am built from commit' + process.env.TRAVIS_COMMIT )
  res.end()
}

http.createServer(handleRequest).listen(3000)
