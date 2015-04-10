_ = require 'lodash'
Q = require('q')

loadRecentMessages = (http, token, channel, robotId, count) ->
  count = count || 50
  url = "https://slack.com/api/channels.history?" +
    "token=#{token}&channel=#{channel}&count=#{count}"
  deferred = Q.defer()
  http(url).get() (err, res, body) ->
    if err
      deferred.reject "I don't know what I've said lately: #{err}"
    else
      messages = JSON.parse(body).messages
      myMessages = _(messages)
        .filter((msg) -> msg.user is robotId)
        .sortBy('ts')
        .reverse()
        .value()
      deferred.resolve(myMessages)
  return deferred.promise

deleteMessage = (http, token, channel, message) ->
  url = "https://slack.com/api/chat.delete?" +
    "token=#{token}&channel=#{channel}&ts=#{message.ts}"
  deferred = Q.defer()
  http(url).get() (err, res, body) ->
    if err
      deferred.reject "I couldn't delete my message: #{err}"
    else
      deferred.resolve()
  return deferred.promise

selectMessage = (messages, age) ->
  deferred = Q.defer()
  if age < messages.length
    deferred.resolve(messages[age])
  else
    deferred.reject "Sorry, I only know about the last #{messages.length} things I've said."
  return deferred.promise

module.exports = (robot) ->

  robot.respond /delete(?:\s+(\d+)\s+ago)?/, (msg) ->
    age = (msg.match[1] || 1) - 1
    token = msg.robot.adapter.client.token
    channel = msg.message.rawMessage.channel
    robotId = msg.robot.adapter.client.self.id
    you = msg.message.user.id
    # console.log {age: age, token: token, channel: channel, robotId: robotId, you: you}

    loadRecentMessages(robot.http, token, channel, robotId)
      .then((messages) -> selectMessage messages, age)
      .then((message) -> deleteMessage robot.http, token, channel, message)
      .then(() -> msg.reply "Whoops, sorry about that!")
      .catch((err) -> msg.reply err)
      .done()
