describe 'Schemas', ->
  it 'main schema should be requirable', ->
    expect( => require('../schemas.json')).to.not.throw(Error)

  it 'message schema should be requirable', ->
    expect( => require('../message.json')).to.not.throw(Error)
