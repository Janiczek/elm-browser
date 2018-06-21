port module Ports exposing (..)

import Elm.Syntax.Range exposing (Location)
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

            ReplaceInFile data ->
                { tag = "ReplaceInFile"
                , data =
                    JE.object
                        [ ( "filepath", JE.string data.filepath )
                        , ( "from", encodeLocation data.from )
                        , ( "to", encodeLocation data.to )
                        , ( "replacement", JE.string data.replacement )
                        ]
                }

            AskForNewProjectPath ->
                { tag = "AskForNewProjectPath"
                , data = JE.null
                }

            AskForOpenProjectPath ->
                { tag = "AskForOpenProjectPath"
                , data = JE.null
                }

            CreateIndex ->
                { tag = "CreateIndex"
                , data = JE.null
                }


encodeLocation : Location -> JE.Value
encodeLocation { row, column } =
    JE.object
        [ ( "line", JE.int row )
        , ( "column", JE.int column )
        ]


getMsgForElm : (MsgForElm -> msg) -> (String -> msg) -> Sub msg
getMsgForElm tagger onError =
    msgForElm
        (\portData ->
            case portData.tag of
                "ProjectClosed" ->
                    tagger ProjectClosed

                "ProjectCreated" ->
                    case JD.decodeValue JD.string portData.data of
                        Ok path ->
                            tagger (ProjectCreated path)

                        Err err ->
                            onError <| "Invalid data for ProjectCreated: " ++ err

                "ProjectOpened" ->
                    case JD.decodeValue JD.string portData.data of
                        Ok path ->
                            tagger (ProjectOpened path)

                        Err err ->
                            onError <| "Invalid data for ProjectOpened: " ++ err

                _ ->
                    onError <| "Unexpected Msg for Elm: " ++ toString portData
        )
