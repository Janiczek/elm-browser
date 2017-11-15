port module Ports exposing (..)

import Index
import Json.Decode as JD
import Json.Encode as JE
import Types exposing (..)


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

            CreateIndex ->
                { tag = "CreateIndex", data = JE.null }

            ChangeTitle title ->
                { tag = "ChangeTitle", data = JE.string title }

            FetchEditorValue ->
                { tag = "FetchEditorValue", data = JE.null }


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
                            onError <| "Invalid data for ProjectPathChosen: " ++ e

                "NoProjectPathChosen" ->
                    tagger <| NoProjectPathChosen

                "ProjectClosed" ->
                    tagger <| ProjectClosed

                "IndexCreated" ->
                    case JD.decodeValue Index.decoder portData.data of
                        Ok index ->
                            tagger <| IndexCreated index

                        Err e ->
                            onError <| "Invalid data for IndexCreated: " ++ e

                "EditorValue" ->
                    case JD.decodeValue JD.string portData.data of
                        Ok sourceCode ->
                            tagger <| EditorValue sourceCode

                        Err e ->
                            onError <| "Invalid data for EditorValue: " ++ e

                _ ->
                    onError <| "Unexpected Msg for Elm: " ++ toString portData
        )
