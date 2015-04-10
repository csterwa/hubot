_ = require 'lodash'
Q = require 'q'
util = require 'util'

class Client
  constructor: (robot, msg) ->
    @http = robot.http
    @token = msg.robot.adapter.client.token
    @channel = msg.message.rawMessage.channel
    @robotId = msg.robot.adapter.client.self.id
    @userId = msg.message.user.id

  loadRecentMessages: (count) ->
    count = count || 50
    url = "https://slack.com/api/channels.history?" +
      "token=#{@token}&channel=#{@channel}&count=#{count}"
    deferred = Q.defer()
    @http(url).get() (err, res, body) =>
      if err
        deferred.reject "I don't know what I've said lately: #{err}"
      else
        messages = JSON.parse(body).messages
        myMessages = _(messages)
          .filter((msg) => msg.user is @robotId)
          .sortBy('ts')
          .reverse()
          .value()
        deferred.resolve(myMessages)
    return deferred.promise

  deleteMessage: (message) ->
    url = "https://slack.com/api/chat.delete?" +
      "token=#{@token}&channel=#{@channel}&ts=#{message.ts}"
    deferred = Q.defer()
    @http(url).get() (err, res, body) ->
      if err
        deferred.reject "I couldn't delete my message: #{err}"
      else
        deferred.resolve(JSON.parse(body))
    return deferred.promise

  updateMessage: (message, modifyText) ->
    text = modifyText message.text
    url = "https://slack.com/api/chat.update?" +
      "token=#{@token}&channel=#{@channel}&ts=#{message.ts}&text=#{text}"
    deferred = Q.defer()
    @http(url).get() (err, res, body) ->
      if err
        deferred.reject "I couldn't modify my message: #{err}"
      else
        deferred.resolve(JSON.parse(body))
    return deferred.promise

selectMessage = (messages, age) ->
  deferred = Q.defer()
  if age < messages.length
    deferred.resolve(messages[age])
  else
    deferred.reject \
      "Sorry, I only know about the last #{messages.length} things I've said."
  return deferred.promise

class Rot13
  constructor: () ->
    src = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    dst = "nopqrstuvwxyzabcdefghijklmNOPQRSTUVWXYZABCDEFGHIJKLM"
    @txmap = {}
    for i in [0...52]
      @txmap[src[i]] = dst[i]

  encode: (text) ->
    text.split('').map((char) => @txmap[char] || char).join('')

  decode: @encode

module.exports = (robot) ->

  rot13 = new Rot13()

  robot.respond /delete(?: (\d+))?(?:(?: messages?) ago)?/, (msg) ->
    age = (msg.match[1] || 1) - 1
    client = new Client robot, msg

    client.loadRecentMessages()
      .then((messages) -> selectMessage messages, age)
      .then((message) -> client.deleteMessage message)
      .then(() -> msg.reply "Whoops, sorry about that!")
      .catch ((err) -> console.log util.inspect err; msg.reply err)
      .done()

  robot.respond /rot13(?: yourself)?(?: (\d+))?(?:(?: messages?) ago)?/, (msg) ->
    age = (msg.match[1] || 1) - 1
    client = new Client robot, msg

    client.loadRecentMessages()
      .then((messages) -> selectMessage messages, age)
      .then((message) -> client.updateMessage message, (text) ->
        rot13.encode text)
      .then(() -> msg.reply "Your secret is safe with me.")
      .catch((err) -> console.log util.inspect err; msg.reply err)
      .done()

  robot.respond /redact(?: yourself)?(?: (\d+))?(?:(?: messages?) ago)?/, (msg) ->
    age = (msg.match[1] || 1) - 1
    client = new Client robot, msg

    client.loadRecentMessages()
      .then((messages) -> selectMessage messages, age)
      .then((message) -> client.updateMessage message, () -> '[REDACTED]')
      .then(() -> msg.reply "My lips are sealed.")
      .catch((err) -> console.log util.inspect err; msg.reply err)
      .done()
