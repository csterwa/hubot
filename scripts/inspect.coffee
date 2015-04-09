_ = require 'lodash'
util = require 'util'

lookup = (obj, str) ->
  _.reduce(_.tail(str.split('.')), ((acc, id) -> acc[id]), obj)

inspect = (obj, depth) ->
  "```
  #{util.inspect obj, (depth && {depth: depth})}
  ```"

module.exports = (robot) ->

  robot.respond /inspect (\S+)(?:\s+(\d+))?/, (msg) ->
    id = msg.match[1]
    depth = msg.match[2]
    console.log 'id = ', id, ' depth = ', depth
    if (id is 'msg')
      msg.send inspect msg, depth
    else
      msg.send inspect lookup(msg, msg.match[1]), depth
