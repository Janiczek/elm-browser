module App exposing (init, subscriptions, update)

import Cmd.Extra exposing (..)
import Editor
import Elm.Syntax.Range exposing (Location)
import EveryDict as EDict exposing (EveryDict)
import FilterConfig
import Html exposing (Html)
import Index
import Normalize
import Ports
import Selection
import Types exposing (..)


init : ( Model, Cmd Msg )
init =
    { project = Nothing
    , isCompiling = False
    , footerMsg = Nothing
    , editor = Editor.init ""
    }
        |> withNoCmd


subscriptions : Model -> Sub Msg
subscriptions model =
    Ports.getMsgForElm MsgForElm LogError


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        CreateProjectPressed ->
            createProjectPressed model

        OpenProjectPressed ->
            openProjectPressed model

        SaveChange definitionId newSourceCode ->
            saveChange definitionId newSourceCode model

        EditorMsg msg_ ->
            editorMsg msg_ model

        ShowFooterMsg footerMsg ->
            showFooterMsg footerMsg model

        HideFooterMsg ->
            hideFooterMsg model

        MsgForElm msgForElm ->
            case msgForElm of
                ProjectClosed ->
                    projectClosed model

                ProjectCreated path ->
                    projectCreated path model

                ProjectOpened path ->
                    projectOpened path model

                FilesForIndex files ->
                    filesForIndex files model

        LogError err ->
            logError err model

        SetFilter filterType isActive ->
            setFilter filterType isActive model

        SelectPackage packageId ->
            selectPackage packageId model

        SelectModule moduleId ->
            selectModule moduleId model

        SelectDefinition definitionId ->
            selectDefinition definitionId model

        DeselectPackage ->
            deselectPackage model

        DeselectModule ->
            deselectModule model

        DeselectDefinition ->
            deselectDefinition model


createProjectPressed : Model -> ( Model, Cmd Msg )
createProjectPressed model =
    { model | isCompiling = True }
        |> withCmd (Ports.sendMsgForElectron CreateProject)


openProjectPressed : Model -> ( Model, Cmd Msg )
openProjectPressed model =
    { model | isCompiling = True }
        |> withCmd (Ports.sendMsgForElectron OpenProject)


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


markAsDirty : Model -> SourceCode -> Model
markAsDirty model sourceCode =
    let
        selectedDefinitionId : Maybe DefinitionId
        selectedDefinitionId =
            model.project
                |> Maybe.map .selection
                |> Maybe.andThen Selection.selectedDefinitionId
    in
    Maybe.map2
        (\project definitionId ->
            project.changes
                |> EDict.insert definitionId sourceCode
                |> asChangesIn model.project
                |> asProjectIn model
        )
        model.project
        selectedDefinitionId
        |> Maybe.withDefault model


saveChange : DefinitionId -> SourceCode -> Model -> ( Model, Cmd Msg )
saveChange definitionId (SourceCode sourceCode) model =
    let
        definition : Maybe Definition
        definition =
            model.project
                |> Maybe.andThen .index
                |> Maybe.andThen (\index -> EDict.get definitionId index.definitions)

        filepath : Maybe String
        filepath =
            Maybe.map2 (\selection index -> Index.moduleForSelectedDefinition selection index)
                (model.project |> Maybe.map .selection)
                (model.project |> Maybe.andThen .index)
                |> Maybe.andThen identity
                |> Maybe.map .path

        from : Maybe Location
        from =
            definition
                |> Maybe.map (.range >> .start)

        to : Maybe Location
        to =
            definition
                |> Maybe.map (.range >> .end)

        replaceInFileCmd : Cmd Msg
        replaceInFileCmd =
            Maybe.map4
                (\definition filepath from to ->
                    Ports.sendMsgForElectron
                        (ReplaceInFile
                            { filepath = filepath
                            , from = from
                            , to = to
                            , replacement = sourceCode
                            }
                        )
                )
                definition
                filepath
                from
                to
                |> Maybe.withDefault Cmd.none
    in
    model
        |> removeChange definitionId
        |> withCmd replaceInFileCmd


removeChange : DefinitionId -> Model -> Model
removeChange definitionId model =
    model.project
        |> Maybe.map .changes
        |> Maybe.map (EDict.remove definitionId)
        |> Maybe.map (asChangesIn model.project)
        |> Maybe.withDefault model.project
        |> asProjectIn model


selectPackage : PackageId -> Model -> ( Model, Cmd Msg )
selectPackage packageId model =
    selectHelper model
        (\selection ->
            case selection of
                NothingSelected ->
                    PackageSelected packageId

                PackageSelected _ ->
                    PackageSelected packageId

                ModuleSelected moduleId ->
                    model.project
                        |> Maybe.andThen .index
                        |> Maybe.map
                            (\index ->
                                if Index.moduleIsInPackage index moduleId packageId then
                                    PackageAndModuleSelected packageId moduleId
                                else
                                    PackageSelected packageId
                            )
                        |> Maybe.withDefault (PackageSelected packageId)

                PackageAndModuleSelected oldPackageId _ ->
                    if oldPackageId == packageId then
                        selection
                    else
                        PackageSelected packageId

                ModuleAndDefinitionSelected moduleId definitionId ->
                    model.project
                        |> Maybe.andThen .index
                        |> Maybe.map
                            (\index ->
                                if Index.moduleIsInPackage index moduleId packageId then
                                    AllSelected packageId moduleId definitionId
                                else
                                    PackageSelected packageId
                            )
                        |> Maybe.withDefault (PackageSelected packageId)

                AllSelected oldPackageId _ _ ->
                    if oldPackageId == packageId then
                        selection
                    else
                        PackageSelected packageId
        )


selectModule : ModuleId -> Model -> ( Model, Cmd Msg )
selectModule moduleId model =
    selectHelper model
        (\selection ->
            case selection of
                NothingSelected ->
                    ModuleSelected moduleId

                PackageSelected packageId ->
                    PackageAndModuleSelected packageId moduleId

                ModuleSelected _ ->
                    ModuleSelected moduleId

                PackageAndModuleSelected packageId _ ->
                    PackageAndModuleSelected packageId moduleId

                ModuleAndDefinitionSelected oldModuleId _ ->
                    if moduleId == oldModuleId then
                        selection
                    else
                        ModuleSelected moduleId

                AllSelected packageId oldModuleId _ ->
                    if moduleId == oldModuleId then
                        selection
                    else
                        PackageAndModuleSelected packageId moduleId
        )


selectDefinition : DefinitionId -> Model -> ( Model, Cmd Msg )
selectDefinition definitionId model =
    selectHelper model
        (\selection ->
            case selection of
                NothingSelected ->
                    selection

                PackageSelected _ ->
                    selection

                ModuleSelected moduleId ->
                    ModuleAndDefinitionSelected moduleId definitionId

                PackageAndModuleSelected packageId moduleId ->
                    AllSelected packageId moduleId definitionId

                ModuleAndDefinitionSelected moduleId _ ->
                    ModuleAndDefinitionSelected moduleId definitionId

                AllSelected packageId moduleId _ ->
                    AllSelected packageId moduleId definitionId
        )


deselectPackage : Model -> ( Model, Cmd Msg )
deselectPackage model =
    selectHelper model
        (\selection ->
            case selection of
                NothingSelected ->
                    selection

                PackageSelected _ ->
                    NothingSelected

                ModuleSelected _ ->
                    selection

                PackageAndModuleSelected _ moduleId ->
                    ModuleSelected moduleId

                ModuleAndDefinitionSelected _ _ ->
                    selection

                AllSelected _ moduleId definitionId ->
                    ModuleAndDefinitionSelected moduleId definitionId
        )


deselectModule : Model -> ( Model, Cmd Msg )
deselectModule model =
    selectHelper model
        (\selection ->
            case selection of
                NothingSelected ->
                    selection

                PackageSelected _ ->
                    selection

                ModuleSelected _ ->
                    NothingSelected

                PackageAndModuleSelected packageId _ ->
                    PackageSelected packageId

                ModuleAndDefinitionSelected _ _ ->
                    NothingSelected

                AllSelected packageId _ _ ->
                    PackageSelected packageId
        )


deselectDefinition : Model -> ( Model, Cmd Msg )
deselectDefinition model =
    selectHelper model
        (\selection ->
            case selection of
                NothingSelected ->
                    selection

                PackageSelected _ ->
                    selection

                ModuleSelected _ ->
                    selection

                PackageAndModuleSelected _ _ ->
                    selection

                ModuleAndDefinitionSelected moduleId _ ->
                    ModuleSelected moduleId

                AllSelected packageId moduleId _ ->
                    PackageAndModuleSelected packageId moduleId
        )


selectHelper : Model -> (Selection -> Selection) -> ( Model, Cmd Msg )
selectHelper model fn =
    model.project
        |> Maybe.map .selection
        |> Maybe.map fn
        |> Maybe.andThen (asSelectionIn model.project)
        |> asProjectIn model
        |> updateEditorContent
        |> withNoCmd


updateEditorContent : Model -> Model
updateEditorContent model =
    let
        (SourceCode code) =
            Maybe.map2
                (\index project ->
                    Index.sourceCode project.selection index project.filterConfig project.changes
                )
                (model.project |> Maybe.andThen .index)
                model.project
                |> Maybe.andThen identity
                |> Maybe.withDefault (SourceCode "")

        newEditor =
            model.editor
                |> Editor.setContent code

        modelWithSource =
            { model | editor = newEditor }
    in
    modelWithSource


projectClosed : Model -> ( Model, Cmd Msg )
projectClosed model =
    { model | project = Nothing }
        |> withCmd (Ports.sendMsgForElectron (ChangeTitle (windowTitle Nothing)))


projectCreated : String -> Model -> ( Model, Cmd Msg )
projectCreated path model =
    { model
        | project =
            Just
                { rootPath = path
                , index = Nothing
                , selection = NothingSelected
                , filterConfig = FilterConfig.empty
                , changes = EDict.empty
                }
        , isCompiling = False
    }
        |> withCmds
            [ Ports.sendMsgForElectron (ChangeTitle (windowTitle (Just path)))
            , Ports.sendMsgForElectron (ListFilesForIndex path)
            ]


projectOpened : String -> Model -> ( Model, Cmd Msg )
projectOpened path model =
    { model
        | project =
            Just
                { rootPath = path
                , index = Nothing
                , selection = NothingSelected
                , filterConfig = FilterConfig.empty
                , changes = EDict.empty
                }
        , isCompiling = False
    }
        |> withCmds
            [ Ports.sendMsgForElectron (ChangeTitle (windowTitle (Just path)))
            , Ports.sendMsgForElectron (ListFilesForIndex path)
            ]


filesForIndex : List ( String, String ) -> Model -> ( Model, Cmd Msg )
filesForIndex files model =
    model.project
        |> Maybe.map
            (\project ->
                files
                    |> Normalize.toIndex project.rootPath
                    |> asIndexIn model.project
                    |> asProjectIn model
            )
        |> Maybe.withDefault model
        |> withNoCmd


editorMsg : Editor.Msg -> Model -> ( Model, Cmd Msg )
editorMsg msg_ model =
    let
        ( newEditor, maybeNewContent ) =
            Editor.update msg_ model.editor

        modelWithNewEditor =
            { model | editor = newEditor }
    in
    maybeNewContent
        |> Maybe.map SourceCode
        |> Maybe.map (markAsDirty modelWithNewEditor)
        |> Maybe.withDefault modelWithNewEditor
        |> withNoCmd


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


asSelectionIn : Maybe Project -> Selection -> Maybe Project
asSelectionIn maybeProject selection =
    maybeProject
        |> Maybe.map (\project -> { project | selection = selection })


asChangesIn : Maybe Project -> EveryDict DefinitionId SourceCode -> Maybe Project
asChangesIn maybeProject changes =
    maybeProject
        |> Maybe.map (\project -> { project | changes = changes })


asProjectIn : Model -> Maybe Project -> Model
asProjectIn model maybeProject =
    { model | project = maybeProject }


asIndexIn : Maybe Project -> Maybe Index -> Maybe Project
asIndexIn maybeProject maybeIndex =
    maybeProject
        |> Maybe.map (\project -> { project | index = maybeIndex })


asDefinitionIn : Maybe Index -> Maybe DefinitionId -> Definition -> Maybe Index
asDefinitionIn maybeIndex maybeDefinitionId definition =
    Maybe.map2 (\index id -> { index | definitions = EDict.insert id definition index.definitions })
        maybeIndex
        maybeDefinitionId
