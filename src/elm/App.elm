module App exposing (init, update, subscriptions)

import EverySet as ESet
import Ports
import Html exposing (Html)
import FilterConfig
import Cmd.Extra exposing (..)
import Selection
import Types exposing (..)


init : ( Model, Cmd Msg )
init =
    { project = Nothing
    , footerMsg = Nothing
    }
        |> withNoCmd


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AskForProject ->
            askForProject model

        CloseProject ->
            closeProject model

        EditorChanged ->
            editorChanged model

        ShowFooterMsg footerMsg ->
            showFooterMsg footerMsg model

        HideFooterMsg ->
            hideFooterMsg model

        MsgForElm msgForElm ->
            case msgForElm of
                ProjectPathChosen path ->
                    projectPathChosen path model

                NoProjectPathChosen ->
                    noProjectPathChosen model

                ProjectClosed ->
                    projectClosed model

                IndexCreated index ->
                    indexCreated index model

                EditorValue sourceCode ->
                    editorValue sourceCode model

        LogError err ->
            logError err model

        SelectOne id ->
            selectOne id model

        SelectAnother id ->
            selectAnother id model

        Deselect id ->
            deselect id model

        SetFilter filterType isActive ->
            setFilter filterType isActive model


askForProject : Model -> ( Model, Cmd Msg )
askForProject model =
    model
        |> withCmd (Ports.sendMsgForElectron ChooseProjectPath)


closeProject : Model -> ( Model, Cmd Msg )
closeProject model =
    { model | project = Nothing }
        |> withNoCmd


editorChanged : Model -> ( Model, Cmd Msg )
editorChanged model =
    model
        |> withCmd (Ports.sendMsgForElectron FetchEditorValue)


showFooterMsg : ( Html Msg, String ) -> Model -> ( Model, Cmd Msg )
showFooterMsg footerMsg model =
    { model | footerMsg = Just footerMsg }
        |> withNoCmd


hideFooterMsg : Model -> ( Model, Cmd Msg )
hideFooterMsg model =
    { model | footerMsg = Nothing }
        |> withNoCmd


logError : String -> Model -> ( Model, Cmd Msg )
logError err model =
    model
        |> withCmd (Ports.sendMsgForElectron (ErrorLogRequested err))


selectOne : Id -> Model -> ( Model, Cmd Msg )
selectOne id model =
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
        { model | project = newProject }
            |> withNoCmd


selectAnother : Id -> Model -> ( Model, Cmd Msg )
selectAnother id model =
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
        { model | project = newProject }
            |> withNoCmd


deselect : Id -> Model -> ( Model, Cmd Msg )
deselect id model =
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
        { model | project = newProject }
            |> withNoCmd


setFilter : FilterType -> Bool -> Model -> ( Model, Cmd Msg )
setFilter filterType isActive model =
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
        { model | project = newProject }
            |> withNoCmd


projectPathChosen : String -> Model -> ( Model, Cmd Msg )
projectPathChosen path model =
    { model
        | project =
            Just
                { rootPath = path
                , index = Nothing
                , selection = Selection.empty
                , filterConfig = FilterConfig.empty
                }
    }
        |> withCmds
            [ Ports.sendMsgForElectron CreateIndex
            , Ports.sendMsgForElectron (ChangeTitle (windowTitle (Just path)))
            ]


noProjectPathChosen : Model -> ( Model, Cmd Msg )
noProjectPathChosen model =
    model
        |> withNoCmd


projectClosed : Model -> ( Model, Cmd Msg )
projectClosed model =
    { model | project = Nothing }
        |> withCmd (Ports.sendMsgForElectron (ChangeTitle (windowTitle Nothing)))


indexCreated : Index -> Model -> ( Model, Cmd Msg )
indexCreated index model =
    { model
        | project =
            model.project
                |> Maybe.map
                    (\project -> { project | index = Just index })
    }
        |> withNoCmd


editorValue : String -> Model -> ( Model, Cmd Msg )
editorValue sourceCode model =
    -- TODO do something about the changed source code
    model
        |> withNoCmd


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
