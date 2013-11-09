express = require('express')
mysql = require('mysql')
path = require('path')

config = require('./config.json')
connection = mysql.createConnection(config.db)

app = express()

app.use(express.basicAuth(config.user, config.password))
app.set('views', path.join(__dirname, 'views'))
app.set('view engine', 'jade')
app.use(express.urlencoded())
app.use(express.bodyParser())
app.use(express.methodOverride())
app.use(app.router)
app.use(express.static(path.join(__dirname, 'public')))

app.get '/', (req, res) ->
  connection.query 'SELECT * FROM virtual_domains', (err, domains) ->
    return res.send(500, err) if err?
    connection.query 'SELECT * FROM virtual_users', (err, accounts) ->
      return res.send(500, err) if err?
      res.render('index', { domains: domains, accounts: accounts })

app.post '/add_domain', (req, res) ->
  domain = req.body.domain
  if domain
    connection.query 'INSERT INTO virtual_domains (name) VALUES (?)', [domain], (err) ->
      return res.send(500, err) if err?
      res.redirect('/')
  else
    throw "missing params"

app.post '/add_account', (req, res) ->
  email = req.body.email
  password = req.body.password

  if email and password
    parts = email.split('@')
    throw "invalid email" unless parts.length > 1
    domain = parts[parts.length - 1]

    connection.query 'SELECT id FROM virtual_domains WHERE name=?', [domain], (err, domains) ->
      return res.send(500, err) if err?
      return res.send(404, "domain not found") unless domains.length > 0

      domain = domains[0]
      connection.query 'INSERT INTO virtual_users (domain_id, password, email) VALUES (?, MD5(?), ?)', [domain.id, password, email], (err) ->
        res.redirect('/')
  else
    throw "missing params"

app.get '/delete_domain', (req, res) ->
  id = req.query.id
  if id? and (id = parseInt(id, 10))?
    connection.query 'DELETE FROM virtual_domains WHERE id=?', [id], (err) ->
      return res.send(500, err) if err?
      res.redirect('/')
  else
    throw "missing params"

app.get '/delete_account', (req, res) ->
  id = req.query.id
  if id? and (id = parseInt(id, 10))?
    connection.query 'DELETE FROM virtual_users WHERE id=?', [id], (err) ->
      return res.send(500, err) if err?
      res.redirect('/')
  else
    throw "missing params"

app.listen(3030)

