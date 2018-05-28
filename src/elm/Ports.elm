port module Ports exposing (..)

import Json.Decode as JD
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

            FetchEditorValue ->
                { tag = "FetchEditorValue", data = JE.null }


getMsgForElm : (MsgForElm -> msg) -> (String -> msg) -> Sub msg
getMsgForElm tagger onError =
    msgForElm
        (\portData ->
            case portData.tag of
                "EditorValue" ->
                    case JD.decodeValue JD.string portData.data of
                        Ok sourceCode ->
                            tagger <| EditorValue (SourceCode sourceCode)

                        Err e ->
                            onError <| "Invalid data for EditorValue: " ++ e

                "ProjectClosed" ->
                    tagger ProjectClosed

                _ ->
                    onError <| "Unexpected Msg for Elm: " ++ toString portData
        )
