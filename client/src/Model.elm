module Model exposing (..) -- Yes, we want to expose everything.




-- TYPES

type alias Nickname = String
type alias ChannelName = String
type alias MessageText = String
type alias InputBoxContent = String


type alias Model =
  { nickname : Maybe Nickname
  , messages : List ChannelMessage
  , activeChannelName : ChannelName
  , inputBoxContent : InputBoxContent
  }


type alias ChannelMessage = 
  { channelName : ChannelName
  , authorNickname : Nickname
  , messageText : MessageText
  }




-- VALUES

initModel : Model
initModel = 
  { nickname = Nothing
  , messages = []
  , activeChannelName = defaultActiveChannelName
  , inputBoxContent = ""
  }


defaultActiveChannelName : ChannelName 
defaultActiveChannelName = "#general"


broadcastChannelName : ChannelName 
broadcastChannelName = "##broadcast"
