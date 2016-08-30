http = require 'http'

class OscBundle
  constructor: ({@connector}) ->
    throw new Error 'OscBundle requires connector' unless @connector?

  do: ({data}, callback) =>
    # return callback @_userError(422, 'data.timetag is required') unless data?.timetag?

    @connector.handleBundle data
    callback null

  _userError: (code, message) =>
    error = new Error message
    error.code = code
    return error

module.exports = OscBundle
