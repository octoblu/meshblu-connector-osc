{EventEmitter}  = require 'events'
debug           = require('debug')('meshblu-connector-osc:index')
osc             = require 'osc-min'
udp             = require "dgram"
_               = require 'lodash'

class Connector extends EventEmitter
  constructor: ->
    @options = {}

  isOnline: (callback) =>
    callback null, running: true

  close: (callback) =>
    debug 'on close'
    callback()

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

  getArgValue: ({ type, value }) =>
    return parseInt(value) if type == 'integer'
    return parseFloat(value) if type == 'float'
    return true if type == 'true'
    return true if type == true
    return false if type == 'false'
    return false if type == false
    return null

  formatMessage: (payload={}) =>
    payload.oscType = "message"
    payload.args = _.map payload.args, (arg={}) =>
      arg.value = @getArgValue arg
      return arg
    return payload

  formatBundle: (payload={}) =>
    payload.oscType = "bundle"
    payload.elements = _.map payload.elements, @formatMessage
    return payload

  handleMessage: (payload) =>
    message = @formatMessage payload
    @sendOSC message

  handleBundle: (payload) =>
    message = @formatBundle payload
    @sendOSC message

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


  start: (device, callback) =>
    debug 'started'
    @onConfig device
    callback()

module.exports = Connector
