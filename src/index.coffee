{EventEmitter}  = require 'events'
debug           = require('debug')('meshblu-connector-osc:index')
_               = require('lodash')
osc             = require 'osc-min'
udp             = require "dgram"

class Osc extends EventEmitter
  constructor: ->
    debug 'Osc constructed'
    @options = {}

  isOnline: (callback) =>
    callback null, running: true

  close: (callback) =>
    debug 'on close'
    callback()

  onMessage: (message) =>
    return unless message.payload?
    payload = message.payload || {}

    payload = @formatMessage payload if payload.oscType == 'message'
    payload = @formatBundle payload if payload.oscType == 'bundle'
    @sendOSC payload

  formatMessage: (payload) =>
    collection = []
    _.forEach payload.args, (arg) =>
      switch arg.type
        when 'integer' then arg.value = parseInt(arg.value)
        when 'float' then arg.value = parseFloat(arg.value)
        when 'true' then arg.value = true
        when 'false' then arg.value = false
        when 'bang' then arg.value = null
        when 'null' then arg.value = null
      collection.push arg
    payload.args = collection
    return payload

  formatBundle: (payload) =>
    elements = []
    _.forEach payload.elements, (element) =>
      elements.push @formatMessage element
    payload.elements = elements
    return payload

  onConfig: (device) =>
    return if _.isEqual(@options, device.options)
    @options = _.defaults(device.options,
      listenIp: "0.0.0.0"
      listenPort: 7400
      sendToPort: 3333
      sendToIp: '127.0.0.1')
    debug 'on config', @options
    @bindOSC()

  bindOSC: () =>
    @sock = udp.createSocket "udp4", (msg, rinfo) =>
      try
          debug 'OSC MESSAGE RECEIVED', osc.fromBuffer msg
          @emit 'message', {
            devices: ['*']
            payload: osc.fromBuffer msg
          }
      catch error
          debug "invalid OSC packet"
    @sock.bind @options.listenPort, @options.listenIp

  sendOSC: (message) =>
    buf = osc.toBuffer message
    @sock.send buf, 0, buf.length, @options.sendToPort, @options.sendToIp

  start: (device) =>
    { @uuid } = device
    debug 'started', @uuid
    @onConfig device

module.exports = Osc
