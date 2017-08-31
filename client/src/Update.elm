module Update
    exposing
        ( Msg
            ( InputBoxChanged
            , KeyDown
            , ProcessRawInboundMessage
            , SetActiveChan
            )
        , update
        )

import Json.Decode as JD
import WebSocket
import Configuration
import Model exposing (..)
import Protocol
    exposing
        ( InboundMsg(..)
        , decodeInboundMsg
        , encodeChannelMessage
        , encodeChangeNickRequest
        )


--
-- TYPES
--


type alias RawInputCommandText =
    String


type alias RawMessageText =
    String


type
    Msg
    -- Local low-level messages.
    = InputBoxChanged InputBoxContent
    | KeyDown Int
    | EnterKeyDown
      -- Locally initiated high-level messages.
    | SetActiveChan ChannelName
    | ProcessRawInputCommand RawInputCommandText
    | ProcessRawChannelMessage RawMessageText
      -- Communication from server.
    | ProcessRawInboundMessage String
    | ProcessInboundMessage InboundMsg



--
-- MAIN UPDATE FUNCTION
--


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        -- Local low-level messages.
        InputBoxChanged s ->
            ( { model | inputBoxContent = s }, Cmd.none )

        KeyDown key ->
            let
                enterKeyId =
                    13
            in
                if key == enterKeyId then
                    model |> update EnterKeyDown
                else
                    ( model, Cmd.none )

        EnterKeyDown ->
            let
                content =
                    .inputBoxContent model

                withEmptyBox =
                    { model | inputBoxContent = "" }
            in
                if String.startsWith ("/") <| content then
                    withEmptyBox |> update (ProcessRawInputCommand content)
                else
                    withEmptyBox |> update (ProcessRawChannelMessage content)

        -- Locally initiated high-level messages.
        SetActiveChan newActiveChannelName ->
            ( { model | activeChannelName = newActiveChannelName }, Cmd.none )

        ProcessRawInputCommand rawCmdText ->
            let
                isNickCmd =
                    (String.startsWith ("/nick ") rawCmdText)
                        && (String.length rawCmdText >= 7)

                -- Note: newNickName may be invalid in else branch below.
                newNickName =
                    String.dropLeft (String.length "/nick ") rawCmdText
            in
                if isNickCmd then
                    ( model, wsSend <| encodeChangeNickRequest newNickName )
                else
                    ( model, Cmd.none )

        ProcessRawChannelMessage rawMsgText ->
            case .nickname model of
                Just nn ->
                    let
                        channelMsg =
                            { channelName = .activeChannelName model
                            , authorNickname = nn
                            , messageText = rawMsgText
                            , timestamp = -1 -- Ignored by the server.
                            }
                    in
                        ( model, wsSend <| encodeChannelMessage channelMsg )

                Nothing ->
                    ( model, Cmd.none )

        -- Communication from server.
        ProcessRawInboundMessage str ->
            case JD.decodeString decodeInboundMsg str of
                Ok decodedMsg ->
                    model |> update (ProcessInboundMessage decodedMsg)

                Err error ->
                    Debug.crash error

        ProcessInboundMessage decodedMsg ->
            case decodedMsg of
                InboundResetAllStateMsg ->
                    ( initModel, Cmd.none )

                InboundChannelMessageMsg chanMsg ->
                    ( { model | messages = (chanMsg :: .messages model) }, Cmd.none )

                InboundSetNicknameMsg newNickname ->
                    ( { model | nickname = Just newNickname }, Cmd.none )

                InboundSetAvatarThumbnailUrlMsg url ->
                    ( { model | avatarThumbnailUrl = url }, Cmd.none )



--
-- UTILITIES
--


wsSend : String -> Cmd Msg
wsSend rawString =
    WebSocket.send Configuration.webSocketUrl rawString
