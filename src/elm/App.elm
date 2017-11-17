module App exposing (init, update, subscriptions)

import EverySet as ESet
import Ports
import Selection
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
                                , selection = Selection.empty
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

        SelectOne id ->
            let
                newProject =
                    model.project
                        |> Maybe.map
                            (\project ->
                                case id of
                                    PackageId packageId ->
                                        { project
                                            | selection =
                                                Selection
                                                    (ESet.singleton packageId)
                                                    project.selection.module_
                                                    project.selection.definition
                                        }

                                    ModuleId moduleId ->
                                        { project
                                            | selection =
                                                Selection
                                                    project.selection.packages
                                                    (Just moduleId)
                                                    project.selection.definition
                                        }

                                    DefinitionId definitionId ->
                                        { project
                                            | selection =
                                                Selection
                                                    project.selection.packages
                                                    project.selection.module_
                                                    (Just definitionId)
                                        }
                            )
            in
                ( { model | project = newProject }
                , Cmd.none
                )

        SelectAnother id ->
            let
                newProject =
                    model.project
                        |> Maybe.map
                            (\project ->
                                case id of
                                    PackageId packageId ->
                                        { project
                                            | selection =
                                                Selection
                                                    (ESet.insert packageId project.selection.packages)
                                                    project.selection.module_
                                                    project.selection.definition
                                        }

                                    ModuleId moduleId ->
                                        { project
                                            | selection =
                                                Selection
                                                    project.selection.packages
                                                    (Just moduleId)
                                                    project.selection.definition
                                        }

                                    DefinitionId definitionId ->
                                        { project
                                            | selection =
                                                Selection
                                                    project.selection.packages
                                                    project.selection.module_
                                                    (Just definitionId)
                                        }
                            )
            in
                ( { model | project = newProject }
                , Cmd.none
                )

        Deselect id ->
            let
                newProject =
                    model.project
                        |> Maybe.map
                            (\project ->
                                case id of
                                    -- TODO maybe filter all descendants also?
                                    PackageId packageId ->
                                        { project
                                            | selection =
                                                Selection
                                                    (ESet.remove packageId project.selection.packages)
                                                    project.selection.module_
                                                    project.selection.definition
                                        }

                                    ModuleId moduleId ->
                                        { project
                                            | selection =
                                                Selection
                                                    project.selection.packages
                                                    Nothing
                                                    project.selection.definition
                                        }

                                    DefinitionId _ ->
                                        { project
                                            | selection =
                                                Selection
                                                    project.selection.packages
                                                    project.selection.module_
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
