#!/usr/bin/env coffee
mysql = require('mysql')
path = require('path')
argv = require('optimist').argv

config = require('./config.json')

class VMail
  constructor: ->
    @connection = mysql.createConnection(config.db)

  close: ->
    @connection.end()

  list: (cb) ->
    @connection.query 'SELECT * FROM virtual_domains', (err, domains) =>
      return cb(err) if err?
      @connection.query 'SELECT * FROM virtual_users', (err, accounts) ->
        return cb(err) if err?
        cb(null, domains, accounts)

  addDomain: (domain, cb) ->
    if domain
      @connection.query 'INSERT INTO virtual_domains (name) VALUES (?)', [domain], (err) ->
        cb(err)
    else
      cb(new Error("Missing domain"))

  addAccount: (email, password, cb) ->
    if !email
      cb(new Error("Missing email"))
    else if !password
      cb(new Error("Missing password"))
    else
      parts = email.split('@')
      return cb(new Error("invalid email")) unless parts.length > 1

      domain = parts[parts.length - 1]
      @connection.query 'SELECT id FROM virtual_domains WHERE name=?', [domain], (err, domains) =>
        return cb(err) if err?
        return cb(new Error("Domain not found")) unless domains.length > 0

        domain = domains[0]
        @connection.query 'INSERT INTO virtual_users (domain_id, password, email) VALUES (?, MD5(?), ?)', [domain.id, password, email], (err) ->
          cb(err)

m = new VMail

cb = (err) ->
  m.close()
  console.error(err) if err
  return err?

if argv.domain
  switch argv._[0]
    when "add" then m.addDomain(argv.domain, cb)
    else console.error("command must be one of [add|remove]")

else if argv.email
  switch argv._[0]
    when "add" then m.addAccount(argv.email, argv.password, cb)
    else console.error("command must be one of [add|remove]")

else
  m.list (err, domains, accounts) ->
    return if cb(err)
    console.log "Domains:"
    console.log domains
    console.log "Accounts:"
    console.log accounts

