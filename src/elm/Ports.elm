port module Ports exposing (..)

import Json.Encode as JE
import Types exposing (..)


port msgForElectron : PortData -> Cmd msg


port msgForElm : (PortData -> msg) -> Sub msg


sendMsgForElectron : MsgForElectron -> Cmd msg
sendMsgForElectron msg =
    msgForElectron <|
        case msg of
            ErrorLogRequested err ->
                { tag = "ErrorLogRequested", data = JE.string err }

            ChangeTitle title ->
                { tag = "ChangeTitle", data = JE.string title }


getMsgForElm : (MsgForElm -> msg) -> (String -> msg) -> Sub msg
getMsgForElm tagger onError =
    msgForElm
        (\portData ->
            case portData.tag of
                "ProjectClosed" ->
                    tagger ProjectClosed

                _ ->
                    onError <| "Unexpected Msg for Elm: " ++ toString portData
        )
