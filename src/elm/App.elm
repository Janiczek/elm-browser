module App exposing (init, update, subscriptions)

import EverySet as ESet
import Ports
import FilterConfig
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
                                , filterConfig = FilterConfig.empty
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

        SetFilter filterType isActive ->
            let
                newProject =
                    model.project
                        |> Maybe.map
                            (\project ->
                                let
                                    { packages, modules, definitions } =
                                        project.filterConfig
                                in
                                    case filterType of
                                        UserPackages ->
                                            { packages | user = isActive }
                                                |> asPackagesFilterConfigIn project.filterConfig
                                                |> asFilterConfigIn project

                                        DirectDeps ->
                                            { packages | directDeps = isActive }
                                                |> asPackagesFilterConfigIn project.filterConfig
                                                |> asFilterConfigIn project

                                        DepsOfDeps ->
                                            { packages | depsOfDeps = isActive }
                                                |> asPackagesFilterConfigIn project.filterConfig
                                                |> asFilterConfigIn project

                                        ExposedModules ->
                                            { modules | exposed = isActive }
                                                |> asModulesFilterConfigIn project.filterConfig
                                                |> asFilterConfigIn project

                                        EffectModules ->
                                            { modules | effect = isActive }
                                                |> asModulesFilterConfigIn project.filterConfig
                                                |> asFilterConfigIn project

                                        NativeModules ->
                                            { modules | native = isActive }
                                                |> asModulesFilterConfigIn project.filterConfig
                                                |> asFilterConfigIn project

                                        PortModules ->
                                            { modules | port_ = isActive }
                                                |> asModulesFilterConfigIn project.filterConfig
                                                |> asFilterConfigIn project

                                        ExposedDefinitions ->
                                            { definitions | exposed = isActive }
                                                |> asDefinitionsFilterConfigIn project.filterConfig
                                                |> asFilterConfigIn project
                            )
            in
                ( { model | project = newProject }
                , Cmd.none
                )


asPackagesFilterConfigIn : FilterConfig -> PackagesFilterConfig -> FilterConfig
asPackagesFilterConfigIn filterConfig packages =
    { filterConfig | packages = packages }


asModulesFilterConfigIn : FilterConfig -> ModulesFilterConfig -> FilterConfig
asModulesFilterConfigIn filterConfig modules =
    { filterConfig | modules = modules }


asDefinitionsFilterConfigIn : FilterConfig -> DefinitionsFilterConfig -> FilterConfig
asDefinitionsFilterConfigIn filterConfig definitions =
    { filterConfig | definitions = definitions }


asFilterConfigIn : Project -> FilterConfig -> Project
asFilterConfigIn project filterConfig =
    { project | filterConfig = filterConfig }


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
