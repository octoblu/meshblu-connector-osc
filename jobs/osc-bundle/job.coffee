http = require 'http'

class OscBundle
  constructor: ({@connector}) ->
    throw new Error 'OscBundle requires connector' unless @connector?

  do: ({data}, callback) =>
    return callback @_userError(422, 'data.address is required') unless data?.address?

    @connector.handleBundle data

    metadata =
      code: 200
      status: http.STATUS_CODES[200]

    callback null, {metadata, data}

  _userError: (code, message) =>
    error = new Error message
    error.code = code
    return error

module.exports = OscBundle
