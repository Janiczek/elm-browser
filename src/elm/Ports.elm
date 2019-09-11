port module Ports exposing (..)

import Elm.Syntax.Range exposing (Location)
import Json.Decode as JD exposing (Decoder)
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

            CreateProject ->
                { tag = "CreateProject"
                , data = JE.null
                }

            OpenProject ->
                { tag = "OpenProject"
                , data = JE.null
                }

            ListFilesForIndex projectPath ->
                { tag = "ListFilesForIndex"
                , data = JE.object [ ( "path", JE.string projectPath ) ]
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
                            onError <| "Invalid data for ProjectCreated: " ++ JD.errorToString err

                "ProjectOpened" ->
                    case JD.decodeValue JD.string portData.data of
                        Ok path ->
                            tagger (ProjectOpened path)

                        Err err ->
                            onError <| "Invalid data for ProjectOpened: " ++ JD.errorToString err

                "FilesForIndex" ->
                    case JD.decodeValue filesForIndexDecoder portData.data of
                        Ok files ->
                            tagger (FilesForIndex files)

                        Err err ->
                            onError <| "Invalid data for FilesForIndex: " ++ JD.errorToString err

                _ ->
                    onError <| "Unexpected Msg for Elm: " ++ portData.tag
        )


filesForIndexDecoder : Decoder (List ( String, String ))
filesForIndexDecoder =
    JD.list
        (JD.map2 (\a b -> ( a, b ))
            (JD.index 0 JD.string)
            (JD.index 1 JD.string)
        )
