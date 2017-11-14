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

            SetEditorModel { sourceCode, language } ->
                { tag = "SetEditorModel"
                , data =
                    JE.object
                        [ ( "sourceCode", JE.string sourceCode )
                        , ( "language", JE.string <| languageString language )
                        ]
                }


languageString : Language -> String
languageString language =
    case language of
        Elm ->
            "elm"

        JavaScript ->
            "javascript"


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

                _ ->
                    onError <| "Unexpected Msg for Elm: " ++ toString portData
        )
