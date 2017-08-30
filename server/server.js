const WebSocket = require('ws')




const createRandomNickname = () => 'anon' + Math.round(1000*Math.random())

const createChannelWelcomeMessage = (name) => ({
    _tag: '_chanMsg', 
    channelName: name,
    authorNickname: '@system', 
    messageText: `Welcome to the ${name} channel.` 
  })

const createSignonMessages = (nickname) => [
  { _tag: '_setNickname', nickname: nickname },
  createChannelWelcomeMessage('#general'),
  createChannelWelcomeMessage('#random'),
  createChannelWelcomeMessage('#zzz')
]




const sockets = []

const sendTo = function(ws) {
  return function(msg) {
    var socketId = -1
    sockets.forEach(function (s, i) { if (s == ws) socketId = i; })

    try {
      if (ws.readyState === WebSocket.OPEN) {
        console.log(`Sending "${JSON.stringify(msg)}" to ${socketId}.`)
        ws.send(JSON.stringify(msg))
      }
    } catch (error) {
      console.error(error)
    }
  }
}




const messageLog = []

const sendToAll = (msg) => sockets.forEach(s => sendTo(s)(msg))

const saveAndSendToAll = function(msg) {
  messageLog.push(msg)
  sendToAll(msg)
}

const processInboundMsg = function(ws) {
  return function(rawMsg) {
    var socketId = -1
    sockets.forEach(function (s, i) { if (s == ws) socketId = i; })
    console.log(socketId)

    try {
      console.log(`Trying to parse "${rawMsg}".`)
      const msg = JSON.parse(rawMsg)
      console.log('Parse succeeded.')

      if (msg._tag == '_setNickname') 
        sendTo(ws)(msg)
      else if (msg._tag == '_chanMsg')
        saveAndSendToAll(msg)
    } catch (error) {
      console.error(error) // TODO
    }
  }
}

const broadcastServerNotice = function(msg) {
  saveAndSendToAll({
    _tag: '_chanMsg', 
    channelName: '##broadcast', 
    authorNickname: '@system', 
    messageText: msg
  })
}




const wss = new WebSocket.Server({ port: 8080 })

wss.on('connection', function connection(ws) {
  sockets.push(ws)

  const nickname = createRandomNickname()
  const signOnMessages = createSignonMessages(nickname)

  signOnMessages.forEach(sendTo(ws))
  messageLog.forEach(sendTo(ws))

  // Note: Must come after sending messageLog, to avoid sending it twice.
  broadcastServerNotice(`${nickname} just connected to the server. Welcome!`)

  ws.on('message', processInboundMsg(ws))
})
