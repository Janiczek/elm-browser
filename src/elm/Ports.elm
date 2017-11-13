port module Ports exposing (..)

import Types exposing (..)
import Json.Decode as JD
import Json.Encode as JE


port msgForElectron : PortData -> Cmd msg


port msgForElm : (PortData -> msg) -> Sub msg


sendMsgForElectron : MsgForElectron -> Cmd msg
sendMsgForElectron msg =
    msgForElectron <|
        case msg of
            ChooseProjectPath ->
                { tag = "ChooseProjectPath", data = JE.null }

            ErrorLogRequested err ->
                { tag = "ErrorLogRequested", data = JE.string err }


getMsgForElm : (MsgForElm -> msg) -> (String -> msg) -> Sub msg
getMsgForElm tagger onError =
    msgForElm
        (\portData ->
            case portData.tag of
                "ProjectPathChosen" ->
                    case JD.decodeValue JD.string portData.data of
                        Ok path ->
                            tagger <| ProjectPathChosen path

                        Err e ->
                            onError e

                "NoProjectPathChosen" ->
                    tagger <| NoProjectPathChosen

                _ ->
                    onError <| "Unexpected Msg for Elm: " ++ toString portData
        )
