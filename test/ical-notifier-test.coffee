chai = require 'chai'
sinon = require 'sinon'
chai.use require 'sinon-chai'

expect = chai.expect

describe 'ical-notifier', ->
  beforeEach ->
    @robot =
      respond: sinon.spy()
      hear: sinon.spy()

    require('../src/ical-notifier')(@robot)

  it 'registers cal:add listener', ->
    expect(@robot.respond).to.have.been.calledWith(/cal:add (.+)/)

  it 'registers cal:list listener', ->
    expect(@robot.respond).to.have.been.calledWith(/cal:list/)

  it 'registers cal:clear listener', ->
    expect(@robot.respond).to.have.been.calledWith(/cal:clear/)
