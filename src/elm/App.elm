module App exposing (init, update, subscriptions)

import Ports
import Types exposing (..)


init : ( Model, Cmd Msg )
init =
    ( { project = Nothing
      , footerMsg = Nothing
      }
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

        EditorChanged ->
            ( model
            , Ports.sendMsgForElectron FetchEditorValue
            )

        ShowFooterMsg footerMsg ->
            ( { model | footerMsg = Just footerMsg }
            , Cmd.none
            )

        HideFooterMsg ->
            ( { model | footerMsg = Nothing }
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
                                , selection = Selection [] [] Nothing
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

                EditorValue sourceCode ->
                    let
                        _ =
                            Debug.log "TODO Do something about the changed source code!" sourceCode
                    in
                        ( model
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
                                                    project.selection.definition
                                        }

                                    ModuleColumn ->
                                        { project
                                            | selection =
                                                Selection
                                                    project.selection.packages
                                                    [ identifier ]
                                                    project.selection.definition
                                        }

                                    DefinitionColumn ->
                                        { project
                                            | selection =
                                                Selection
                                                    project.selection.packages
                                                    project.selection.modules
                                                    (Just identifier)
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
                                                    project.selection.definition
                                        }

                                    ModuleColumn ->
                                        { project
                                            | selection =
                                                Selection
                                                    project.selection.packages
                                                    (identifier :: project.selection.modules)
                                                    project.selection.definition
                                        }

                                    DefinitionColumn ->
                                        { project
                                            | selection =
                                                Selection
                                                    project.selection.packages
                                                    project.selection.modules
                                                    (Just identifier)
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
                                                    project.selection.definition
                                        }

                                    ModuleColumn ->
                                        { project
                                            | selection =
                                                Selection
                                                    project.selection.packages
                                                    (project.selection.modules
                                                        |> List.filter (\module_ -> identifier /= module_)
                                                    )
                                                    project.selection.definition
                                        }

                                    DefinitionColumn ->
                                        { project
                                            | selection =
                                                Selection
                                                    project.selection.packages
                                                    project.selection.modules
                                                    Nothing
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
