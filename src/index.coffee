{EventEmitter}  = require 'events'
debug           = require('debug')('meshblu-connector-osc:index')
_               = require('lodash')
osc             = require('osc')

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
    if payload.number == true
      args = []
      payload.args.forEach (val) ->
        args.push parseInt(val)
      payload.args = args
    debug 'onMessage', payload

    @connectToUdp @options if @updPort

    return @udpPort.send payload.bundle if payload.bundle
    @udpPort.send payload

  onConfig: (device) =>
    @options = _.defaults(device.options,
      ipAddress: '0.0.0.0'
      listenPort: 7400
      sendToPort: 3333
      sendToIp: '127.0.0.1')
    debug 'on config', @options

    if @udpPort
      debug 'already connected to udp, clearing and trying again'
      @udpPort.close()
      @udpPort = null
    @connectToUdp @options

  start: (device) =>
    { @uuid } = device
    debug 'started', @uuid

  connectToUdp = (options) =>
    debug 'connecting to udp'
    options =
      localAddress: options.ipAddress
      remoteAddress: options.sendToIp
      localPort: options.listenPort
      remotePort: options.sendToPort
    @udpPort = new (osc.UDPPort)(options)
    @udpPort.open()
    # Listen for incoming OSC bundles.
    @udpPort.on 'bundle', (oscBundle) =>
      debug 'an osc bundle just arrived!', oscBundle
      @emit 'message',
        devices: [ '*' ]
        payload: oscBundle
    #Listen for regular messages
    @udpPort.on 'message', (oscMsg) =>
      debug 'an osc message just arrived!', oscMsg
      @emit 'message',
        devices: [ '*' ]
        payload: oscMsg


module.exports = Osc
