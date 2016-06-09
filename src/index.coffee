_               = require 'lodash'
{EventEmitter}  = require 'events'
osc             = require 'osc-min'
udp             = require "dgram"
debug           = require('debug')('meshblu-connector-osc:index')

class Osc extends EventEmitter
  onMessage: (message={}) =>
    { oscType } = message.payload ? {}
    return debug 'invalid oscType' unless oscType
    message = @formatMessage payload if oscType == 'message'
    message = @formatBundle payload if oscType == 'bundle'
    @sendOSC message

  getArgValue: ({ type, value }) =>
    return parseInt(value) if type == 'integer'
    return parseFloat(value) if type == 'float'
    return true if type == 'true'
    return true if type == true
    return false if type == 'false'
    return false if type == false
    return null

  formatMessage: (payload={}) =>
    program.args = _.map payload.args, (arg={}) =>
      arg.value = @getArgValue arg
      return arg
    return payload

  formatBundle: (payload={}) =>
    payload.elements = _.map payload.elements, @formatMessage
    return payload

  onConfig: (device={}) =>
    return if _.isEqual @options, device.options
    @options = _.defaults device.options, {
      listenIp: "0.0.0.0"
      listenPort: 7400
      sendToPort: 3333
      sendToIp: '127.0.0.1'
    }
    debug 'on config', @options
    @bindOSC()

  bindOSC: =>
    @sock = udp.createSocket "udp4", (msg, rinfo) =>
      try
        message = osc.fromBuffer msg
        debug 'OSC MESSAGE RECEIVED', message
        @emit 'message', {
          devices: ['*']
          topic: 'osc-message'
          payload: message
        }
      catch error
        console.error error

    @sock.bind @options.listenPort, @options.listenIp

  sendOSC: (message) =>
    buf = osc.toBuffer message
    @sock.send buf, 0, buf.length, @options.sendToPort, @options.sendToIp

  start: (device) =>
    @onConfig device

module.exports = Osc
