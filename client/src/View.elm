module View exposing (view)

import Date exposing (fromTime, hour, minute, second)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode
import List
import Maybe exposing (withDefault)
import Set
import Model exposing (..)
import Update exposing (Msg(InputBoxChanged, KeyDown, SetActiveChan))


view : Model -> Html Msg
view model =
    let
        channelNames =
            extractChannelNames (.messages model)

        activeChannelMessages =
            List.filter isActiveChannelMessage (.messages model)

        -- Somewhat fugly with the broadcastChannelName stuff. Re-think.
        isActiveChannelMessage m =
            let
                cn =
                    m.channelName
            in
                cn == (.activeChannelName model) || cn == broadcastChannelName

        inputBoxContent =
            .inputBoxContent model
    in
        div []
            [ viewSidebar
                channelNames
                (.activeChannelName model)
                (.nickname model)
                (.avatarThumbnailUrl model)
            , viewMainContainer activeChannelMessages inputBoxContent
            ]


extractChannelNames : List ChannelMessage -> List String
extractChannelNames messageList =
    List.map .channelName messageList
        |> Set.fromList
        |> Set.toList
        |> List.filter ((/=) broadcastChannelName)



-- (Thanks to https://stackoverflow.com/a/40114176 for onKeyDown.)


onKeyDown : (Int -> msg) -> Attribute msg
onKeyDown tagger =
    on "keydown" (Json.Decode.map tagger keyCode)


viewMainContainer : List ChannelMessage -> InputBoxContent -> Html Msg
viewMainContainer messages inputBoxContent =
    let
        szpad n =
            (if n < 10 then
                "0"
             else
                ""
            )
                ++ (toString n)

        dateStr date =
            (szpad <| hour date)
                ++ ":"
                ++ (szpad <| minute date)
                ++ ":"
                ++ (szpad <| second date)

        viewMessage { channelName, authorNickname, messageText, timestamp } =
            div [ class "message" ]
                [ div [ class "nicknameAndDateWrapper" ]
                    [ span [ class "nickname" ] [ text authorNickname ]
                    , span [ class "date" ]
                        [ text <| dateStr <| fromTime timestamp ]
                    ]
                , span [ class "text" ] [ text messageText ]
                ]
    in
        div [ id "mainContainer" ]
            [ div [ id "activeChannelMessagesWrapper" ]
                [ div [ id "activeChannelMessages" ]
                    (List.map viewMessage (List.reverse messages))
                ]
            , input
                [ id "inputBox"
                , onInput InputBoxChanged
                , onKeyDown KeyDown
                , value inputBoxContent
                ]
                []
            ]


viewSidebar :
    List ChannelName
    -> ChannelName
    -> Maybe Nickname
    -> Url
    -> Html Msg
viewSidebar channelNames activeChannelName maybeNickname avatarThumbnailUrl =
    let
        viewChannelName cn =
            li [ onClick (SetActiveChan cn) ]
                [ if cn == activeChannelName then
                    span [ class "active" ] [ text cn ]
                  else
                    text cn
                ]
    in
        div [ id "sidebar" ]
            [ span [ id "nickname" ]
                [ img [ id "sidebarAvatarThumb", src avatarThumbnailUrl ] []
                , text <| withDefault "(nonick)" maybeNickname
                , text " @ slakk"
                ]
            , ul [ id "channelList" ] (List.map viewChannelName channelNames)
            ]
