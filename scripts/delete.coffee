_ = require 'lodash'

module.exports = (robot) ->

  robot.respond /delete(?:\s+(\d+)\s+ago)?/, (msg) ->
    age = (msg.match[1] || 1) - 1
    token = msg.robot.adapter.client.token
    channel = msg.message.rawMessage.channel
    me = msg.robot.adapter.client.self.id
    you = msg.message.user.id
    # console.log {age: age, token: token, channel: channel, me: me, you: you}

    historyUrl = "https://slack.com/api/channels.history?token=#{token}&channel=#{channel}&count=50"
    robot.http(historyUrl).get() (err, res, body) ->
      if not err
        messages = JSON.parse(body).messages
        myMessages = _(messages)
          .filter((msg) -> msg.user is me)
          .sortBy('ts')
          .reverse()
          .value()
        if (age >= myMessages.length)
          msg.reply "Sorry, I only know about the last #{myMessages.length} things I've said in this channel."
        else
          message = myMessages[age]

          deleteUrl = "https://slack.com/api/chat.delete?token=#{token}&channel=#{channel}&ts=#{message.ts}"
          robot.http(deleteUrl).get() (err, res, body) ->
            if not err
              msg.reply "Whoops, sorry about that! "
            else
              msg.reply "Sorry, I could not delete the message: " + err
      else
        msg.reply "I can't figure out what I've said lately: " + err
