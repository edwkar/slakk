module View exposing (view)




import Html            exposing (..)
import Html.Attributes exposing (..)
import Html.Events     exposing (..)
import Json.Decode     
import List
import Maybe           exposing (withDefault)
import Set

import Model exposing  (..)
import Update exposing (Msg(InputBoxChanged, KeyDown, SetActiveChan))




view : Model -> Html Msg
view model = 
  let 
    channelNames = extractChannelNames (.messages model)

    activeChannelMessages = 
      List.filter (\m -> m.channelName == (.activeChannelName model))
                  (.messages model)
  in
    div []
      [viewSidebar 
         channelNames 
         (.activeChannelName model)
         (.nickname model)
      ,viewMainContainer activeChannelMessages
      ]


extractChannelNames : List ChannelMessage -> List String
extractChannelNames messageList =
  List.map .channelName messageList |> Set.fromList |> Set.toList


-- https://stackoverflow.com/a/40114176, thanks:
onKeyDown : (Int -> msg) -> Attribute msg
onKeyDown tagger =
  on "keydown" (Json.Decode.map tagger keyCode)


viewMainContainer : List ChannelMessage -> Html Msg
viewMainContainer messages =
  let
    viewMessage {channelName, authorNickname, messageText} = 
      div [class "message"] 
          [span [class "nickname"] [text authorNickname]
          ,span [class "text"]     [text messageText]
          ]
  in
    div [id "mainContainer"]
        [div [id "activeChannelMessagesWrapper"]
             [div [id "activeChannelMessages"] 
                  (List.map viewMessage (List.reverse messages))
             ] 
        ,input [id "inputBox", onInput InputBoxChanged, onKeyDown KeyDown] []
        ] 


viewSidebar : List ChannelName -> ChannelName -> Maybe Nickname -> Html Msg
viewSidebar channelNames activeChannelName maybeNickname =
  let
    viewChannelName cn = 
      li [onClick (SetActiveChan cn)] 
         [if cn == activeChannelName 
            then span [class "active"] [text cn]
            else text cn
         ]
  in
    div [id "sidebar"]
        [span [id "nickname"] 
              [text <| withDefault "(nonick)" maybeNickname
              ,text " @ slakk"
              ]
        ,ul [id "channelList"] (List.map viewChannelName channelNames)
        ]


