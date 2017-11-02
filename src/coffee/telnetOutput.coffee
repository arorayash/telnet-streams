# telnetOutput.coffee
#----------------------------------------------------------------------------

TELNET_DO = 253
TELNET_DONT = 254
TELNET_IAC = 255
TELNET_SUB_BEGIN = 250
TELNET_SUB_END = 240
TELNET_WILL = 251
TELNET_WONT = 252

Transform = require('stream').Transform
util = require 'util'

duplicateIAC = (buffer) ->
  bufferIndex = 0
  xlateIndex = 0
  xlateBuf = new Buffer (buffer.length * 2)
  while bufferIndex < buffer.length
    data = buffer[bufferIndex]
    bufferIndex++
    xlateBuf.writeUInt8 data, xlateIndex
    xlateIndex++;
    if data is TELNET_IAC
      xlateBuf.writeUInt8 data, xlateIndex
      xlateIndex++
  return xlateBuf.slice 0, xlateIndex

TelnetOutput = (options) ->
  return new TelnetOutput options if (this instanceof TelnetOutput) is false
  Transform.call this, options
  return this

util.inherits TelnetOutput, Transform

TelnetOutput::_transform = (chunk, encoding, done) ->
  @push duplicateIAC chunk
  done()

TelnetOutput::_writeOption = (command, option) ->
  cmdBuf = new Buffer 3
  cmdBuf[0] = TELNET_IAC
  cmdBuf[1] = command
  cmdBuf[2] = option
  @push cmdBuf

TelnetOutput::writeCommand = (command) ->
  cmdBuf = new Buffer 2
  cmdBuf[0] = TELNET_IAC
  cmdBuf[1] = command
  @push cmdBuf

TelnetOutput::writeDo = (option) ->
  @_writeOption TELNET_DO, option

TelnetOutput::writeDont = (option) ->
  @_writeOption TELNET_DONT, option

TelnetOutput::writeSub = (option, buffer) ->
  negBuf = duplicateIAC buffer
  subBuf = new Buffer negBuf.length + 5
  subBuf[0] = TELNET_IAC
  subBuf[1] = TELNET_SUB_BEGIN
  subBuf[2] = option
  subBuf[i+3] = negBuf[i] for i in [0..negBuf.length-1]
  subBuf[negBuf.length+3] = TELNET_IAC
  subBuf[negBuf.length+4] = TELNET_SUB_END
  @push subBuf

TelnetOutput::writeWill = (option) ->
  @_writeOption TELNET_WILL, option

TelnetOutput::writeWont = (option) ->
  @_writeOption TELNET_WONT, option

exports.TelnetOutput = TelnetOutput

#----------------------------------------------------------------------------
# end of telnetOutput.coffee
