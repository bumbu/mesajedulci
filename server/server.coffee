express = require 'express'

app = express()
app.use express.static __dirname + '/../public'
app.get '/', (req, res) ->
  filename = __dirname + '/../public/index.html'
  fs.readFile filename, 'binary', (err, file)->
    if err
      res.writeHead 500, 'Content-Type': 'text/plain'
      res.write err
      res.end()

    else
      res.writeHead 200
      res.write file, 'binary'
      res.end()

app.listen(8002)
console.log 'server started on port 8002'
