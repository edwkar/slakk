module Main exposing (..)

import Html
import WebSocket
import Configuration
import Model exposing (Model, ChannelMessage, initModel)
import Update exposing (Msg, Msg(ProcessRawInboundMessage), update)
import View exposing (view)


main : Program Never Model Msg
main =
    Html.program
        { init = ( initModel, Cmd.none )
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


subscriptions : Model -> Sub Msg
subscriptions model =
    WebSocket.listen Configuration.webSocketUrl ProcessRawInboundMessage
