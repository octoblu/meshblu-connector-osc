{EventEmitter}  = require 'events'
debug           = require('debug')('meshblu-connector-osc:index')
_               = require('lodash')
osc             = require 'osc-min'
udp             = require "dgram"

class Osc extends EventEmitter
  constructor: ->
    debug 'Osc constructed'

  isOnline: (callback) =>
    callback null, running: true

  close: (callback) =>
    debug 'on close'
    callback()

  onMessage: (message) =>
    return unless message.payload?
    payload = message.payload || {}

    @sendOSC payload

  onConfig: (device) =>
    @options = _.defaults(device.options,
      listenPort: 7400
      sendToPort: 3333
      sendToIp: '127.0.0.1')
    debug 'on config', @options

  bindOSC: () =>
    @sock = udp.createSocket "udp4", (msg, rinfo) =>
      try
          debug 'OSC MESSAGE RECEIVED', osc.fromBuffer msg
      catch error
          console.log "invalid OSC packet"
    @sock.bind @options.listenPort

  sendOSC: (message) =>
    buf = osc.toBuffer message
    udp.send buf, 0, buf.length, @options.sendToPort, @options.sendToIp

  start: (device) =>
    { @uuid } = device
    debug 'started', @uuid

module.exports = Osc
