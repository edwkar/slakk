module Model exposing (..)

import Time exposing (Time)


--
-- TYPES
--


type alias Nickname =
    String


type alias ChannelName =
    String


type alias MessageText =
    String


type alias InputBoxContent =
    String


type alias Url =
    String


type alias Model =
    { nickname : Maybe Nickname
    , avatarThumbnailUrl : Url
    , messages : List ChannelMessage
    , activeChannelName : ChannelName
    , inputBoxContent : InputBoxContent
    }


type alias ChannelMessage =
    { channelName : ChannelName
    , authorNickname : Nickname
    , messageText : MessageText
    , timestamp : Time
    }



--
-- VALUES
--


initModel : Model
initModel =
    { nickname = Nothing
    , avatarThumbnailUrl = defaultAvatarThumbnailUrl
    , messages = []
    , activeChannelName = defaultActiveChannelName
    , inputBoxContent = ""
    }


defaultAvatarThumbnailUrl : Url
defaultAvatarThumbnailUrl =
    "https://randomuser.me/api/portraits/thumb/women/1.jpg"


defaultActiveChannelName : ChannelName
defaultActiveChannelName =
    "#general"


broadcastChannelName : ChannelName
broadcastChannelName =
    "##broadcast"
