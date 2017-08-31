/* DISCLAIMER:
 *
 * The server is a sad mess, ATM.
 * Should rewrite, but it's low priority...
 */


const WebSocket = require('ws')


/* CONSTANTS.
 */
const SERVER_NICKNAME = '@server'
const BROADCAST_CHANNEL_NAME = '##broadcast'
const RESET_ALL_STATE_TAG = '_resetAllState'
const CHANNEL_MSG_TAG = '_chanMsg'
const SET_NICKNAME_TAG = '_setNickname'
const SET_AVATAR_THUMBNAIL_URL_TAG = '_setAvatarThumbnailUrl'


/* LOW-LEVEL NETWORKING.
 */
const sockets = []

/* Map a web socket to an integer identifier. 
 */
const identifySocket = function(ws) {
  var socketId = -1
  sockets.forEach(function (s, i) { if (s === ws) socketId = i; })
  console.assert(socketId !== -1)
  return socketId
}

const sendOn = function(ws) {
  return function(msg) {
    try {
      if (ws.readyState === WebSocket.OPEN) {
        console.log(`Sending "${JSON.stringify(msg)}" to ${identifySocket(ws)}.`)
        ws.send(JSON.stringify(msg))
      }
    } catch (error) {
      console.error(error)
    }
  }
}

const sendOnAll = (msg) => sockets.forEach(s => sendOn(s)(msg))


/* HIGHER-LEVEL APPLICATION LOGIC.
 */
const globalMessageLog = []

const socketIdToNicknameMap = {}

const nicknameIsInUse = (n) => 
  Object.values(socketIdToNicknameMap).indexOf(n) !== -1

const saveAndSendOnAll = function(msg) {
  globalMessageLog.push(msg)
  sendOnAll(msg)
}

const broadcastServerNotice = function(msg) {
  saveAndSendOnAll({
    _tag: CHANNEL_MSG_TAG, 
    channelName: BROADCAST_CHANNEL_NAME,
    authorNickname: SERVER_NICKNAME,
    messageText: msg,
    timestamp: Date.now()
  })
}

const createRandomNickname = function() {
  for (;;) {
    const nn = 'anon_' + Math.round(10000*Math.random())
    if (!nicknameIsInUse(nn))
      return nn
  }
}

const createChannelWelcomeMessage = (name, newUserNickname) => ({
  _tag: CHANNEL_MSG_TAG, 
  channelName: name,
  authorNickname: SERVER_NICKNAME,
  messageText: `Welcome to ${name}, ${newUserNickname}!`,
  timestamp: Date.now()
})

const createSignonMessagesFor = (nickname) => [
  { _tag: RESET_ALL_STATE_TAG },
  { _tag: SET_NICKNAME_TAG, nickname: nickname },
  { 
    _tag: SET_AVATAR_THUMBNAIL_URL_TAG, 
    url: (
      'https://randomuser.me/api/portraits/thumb/' +
      (Math.random() < .5 ? 'men' : 'women') + 
      '/' +
      Math.round(1 + 60*Math.random()) + 
      '.jpg'
    )
  },
  createChannelWelcomeMessage('#general', nickname),
  createChannelWelcomeMessage('#random',  nickname),
  createChannelWelcomeMessage('#zzz',     nickname)
]

// XXX TODO. BAD FLOW&STYLE, INFINITE SECURITY HOLES. FIX.
const processInboundMsg = function(ws) {
  const socketId = identifySocket(ws)

  return function(rawMsg) {
    // Safety hatches.
    if (rawMsg.length > 600 || globalMessageLog.length > 10000)
      return

    try {
      const msg = JSON.parse(rawMsg)
      console.log(`Successfully parsed "${rawMsg}".`)

      if (msg._tag === SET_NICKNAME_TAG) {
        console.assert(typeof(socketIdToNicknameMap[socketId] === 'string'))

        const isAccepted = (
          typeof(msg.nickname) === 'string' &&
          /^[A-Za-z0-9_]{1,20}$/.test(msg.nickname) &&
          !nicknameIsInUse(msg.nickname)
        )

        if (isAccepted) {
          const oldNickname = socketIdToNicknameMap[socketId]
          socketIdToNicknameMap[socketId] = msg.nickname
          broadcastServerNotice(
            `${oldNickname} is now known as ${msg.nickname}.`
          )
          sendOn(ws)(msg)
        } else {
          console.log(
            `Rejected nickname change for client on connection #${socketId}.`
          )
        }
      } else if (msg._tag === CHANNEL_MSG_TAG) {
        const isAccepted = (
          typeof(msg.channelName) === 'string' &&
          /^#[A-Za-z_][A-Za-z0-9_]{0,20}$/.test(msg.channelName) &&
          typeof(msg.authorNickname) === 'string' &&
          nicknameIsInUse(msg.authorNickname) &&
          msg.authorNickname === socketIdToNicknameMap[socketId] &&
          typeof(msg.messageText) === 'string' &&
          msg.messageText.trim().length >= 1
        )

        if (isAccepted) {  
          msg.timestamp = Date.now()
          saveAndSendOnAll(msg)
        }
      } else {
        console.log(
          `Got unrecognised message from client. `
          + `Raw data: ${rawMsg}.`
        )
      }
    } catch (error) {
      console.error(
        `Exception in processInboundMsg for raw message ${rawMsg}: ` +
        error + '.'
      )
    }
  }
}

const acceptConnection = function connection(ws) {
  // Safety hatch.
  if (sockets.length > 1000)
    return

  sockets.push(ws)
  const socketId = identifySocket(ws)
  console.log(`Accepted connection ${socketId}.`)

  const nickname = createRandomNickname()
  socketIdToNicknameMap[socketId] = nickname
  const signOnMessages = createSignonMessagesFor(nickname)

  signOnMessages.forEach(sendOn(ws))
  globalMessageLog.forEach(sendOn(ws))

  ws.on('message', processInboundMsg(ws))

  ws.on('close', function() {
    if (typeof(socketIdToNicknameMap[socketId]) === 'string')
      delete socketIdToNicknameMap[socketId]
    console.assert(typeof(socketIdToNicknameMap[socketId]) === 'undefined')
    console.log(`Connection ${socketId} closed.`)
  })
}


const wss = new WebSocket.Server({ 
  host: 'edvard-edb.plysjbyen.net', 
  port: 33446 
})
wss.on('connection', acceptConnection)
