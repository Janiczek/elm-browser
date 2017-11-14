module Main exposing (main)

import Html
import Ports
import Types exposing (..)
import View exposing (view)


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


init : ( Model, Cmd Msg )
init =
    ( { project = Nothing }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AskForProject ->
            ( model
            , Ports.sendMsgForElectron ChooseProjectPath
            )

        CloseProject ->
            ( { model | project = Nothing }
            , Cmd.none
            )

        MsgForElm msgForElm ->
            case msgForElm of
                ProjectPathChosen path ->
                    ( { model
                        | project =
                            Just
                                { rootPath = path
                                , index = Nothing
                                , selection = Selection [] [] []
                                }
                      }
                    , Cmd.batch
                        [ Ports.sendMsgForElectron CreateIndex
                        , Ports.sendMsgForElectron (ChangeTitle (windowTitle (Just path)))
                        ]
                    )

                NoProjectPathChosen ->
                    ( model
                    , Cmd.none
                    )

                ProjectClosed ->
                    ( { model | project = Nothing }
                    , Ports.sendMsgForElectron (ChangeTitle (windowTitle Nothing))
                    )

                IndexCreated index ->
                    ( { model
                        | project =
                            model.project
                                |> Maybe.map
                                    (\project -> { project | index = Just index })
                      }
                    , Cmd.none
                    )

        LogError err ->
            ( model
            , Ports.sendMsgForElectron (ErrorLogRequested err)
            )

        SelectOne column identifier ->
            let
                newProject =
                    model.project
                        |> Maybe.map
                            (\project ->
                                case column of
                                    PackageColumn ->
                                        { project
                                            | selection =
                                                Selection
                                                    [ identifier ]
                                                    project.selection.modules
                                                    project.selection.definitions
                                        }

                                    ModuleColumn ->
                                        { project
                                            | selection =
                                                Selection
                                                    project.selection.packages
                                                    [ identifier ]
                                                    project.selection.definitions
                                        }

                                    DefinitionColumn ->
                                        { project
                                            | selection =
                                                Selection
                                                    project.selection.packages
                                                    project.selection.modules
                                                    [ identifier ]
                                        }
                            )
            in
                ( { model | project = newProject }
                , Cmd.none
                )

        SelectAnother column identifier ->
            let
                newProject =
                    model.project
                        |> Maybe.map
                            (\project ->
                                case column of
                                    PackageColumn ->
                                        { project
                                            | selection =
                                                Selection
                                                    (identifier :: project.selection.packages)
                                                    project.selection.modules
                                                    project.selection.definitions
                                        }

                                    ModuleColumn ->
                                        { project
                                            | selection =
                                                Selection
                                                    project.selection.packages
                                                    (identifier :: project.selection.modules)
                                                    project.selection.definitions
                                        }

                                    DefinitionColumn ->
                                        { project
                                            | selection =
                                                Selection
                                                    project.selection.packages
                                                    project.selection.modules
                                                    (identifier :: project.selection.definitions)
                                        }
                            )
            in
                ( { model | project = newProject }
                , Cmd.none
                )

        Deselect column identifier ->
            let
                newProject =
                    model.project
                        |> Maybe.map
                            (\project ->
                                case column of
                                    -- TODO maybe filter all descendants also?
                                    PackageColumn ->
                                        { project
                                            | selection =
                                                Selection
                                                    (project.selection.packages
                                                        |> List.filter (\package -> identifier /= package)
                                                    )
                                                    project.selection.modules
                                                    project.selection.definitions
                                        }

                                    ModuleColumn ->
                                        { project
                                            | selection =
                                                Selection
                                                    project.selection.packages
                                                    (project.selection.modules
                                                        |> List.filter (\module_ -> identifier /= module_)
                                                    )
                                                    project.selection.definitions
                                        }

                                    DefinitionColumn ->
                                        { project
                                            | selection =
                                                Selection
                                                    project.selection.packages
                                                    project.selection.modules
                                                    (project.selection.definitions
                                                        |> List.filter (\definition -> identifier /= definition)
                                                    )
                                        }
                            )
            in
                ( { model | project = newProject }
                , Cmd.none
                )


subscriptions : Model -> Sub Msg
subscriptions model =
    Ports.getMsgForElm MsgForElm LogError


windowTitle : Maybe String -> String
windowTitle maybePath =
    case maybePath of
        Nothing ->
            "Elm Browser"

        Just path ->
            let
                lastDirectory =
                    path
                        |> String.split "/"
                        |> List.reverse
                        |> List.head
                        |> Maybe.withDefault path
            in
                "Elm Browser - " ++ lastDirectory
