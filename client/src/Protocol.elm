module Protocol exposing 
  (OutboundMessage(..)
  ,InboundMsg(..)
  ,decodeInboundMsg
  ,encodeChannelMessage
  ,encodeChangeNickRequest
  ) 




import Json.Decode as JD
import Json.Encode as JE

import Model exposing (..) -- Yes, we want to import everything.



-- TYPES

type OutboundMessage
  = OutboundChannelMessageMsg    ChannelMessage
  | OutboundChangeNickMsg Nickname


type InboundMsg 
  = InboundChannelMessageMsg     ChannelMessage
  | InboundSetNicknameMsg Nickname




-- JSON SERIALISATION

decodeInboundMsg : JD.Decoder InboundMsg
decodeInboundMsg =
  JD.field "_tag" JD.string |> JD.andThen decodeInboundMsgByTag


decodeInboundMsgByTag : String -> JD.Decoder InboundMsg
decodeInboundMsgByTag tag = case tag of
  "_chanMsg" ->
    JD.map InboundChannelMessageMsg <| JD.map3 ChannelMessage
      (JD.field "channelName"    JD.string) 
      (JD.field "authorNickname" JD.string) 
      (JD.field "messageText"    JD.string)
        
  "_setNickname" ->
    JD.map InboundSetNicknameMsg <| JD.field "nickname" JD.string

  _ ->  
    JD.fail <| "JSON decoding failed. Unrecognised type tag: '" ++ tag ++ "'.'"


encodeChannelMessage : ChannelMessage -> String
encodeChannelMessage {channelName, authorNickname, messageText} =
  JE.encode encoderIndentation (JE.object 
    [("_tag",           JE.string "_chanMsg")
    ,("channelName",    JE.string channelName)
    ,("authorNickname", JE.string authorNickname)
    ,("messageText",    JE.string messageText)
    ]
  )


encodeChangeNickRequest : Nickname -> String
encodeChangeNickRequest nickname = 
  JE.encode encoderIndentation (JE.object 
    [("_tag",     JE.string "_setNickname")
    ,("nickname", JE.string nickname)
    ]
  )


encoderIndentation : Int
encoderIndentation = 2
