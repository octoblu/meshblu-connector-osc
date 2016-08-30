http = require 'http'

class OscMessage
  constructor: ({@connector}) ->
    throw new Error 'OscMessage requires connector' unless @connector?

  do: ({data}, callback) =>
    return callback @_userError(422, 'data.address is required') unless data?.address?

    @connector.handleMessage data
    callback null

  _userError: (code, message) =>
    error = new Error message
    error.code = code
    return error

module.exports = OscMessage
