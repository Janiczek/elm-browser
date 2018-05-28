module App exposing (init, subscriptions, update)

import Cmd.Extra exposing (..)
import EveryDict as EDict
import EverySet as ESet
import Html exposing (Html)
import Index
import Ports
import Selection
import Types exposing (..)


init : ( Model, Cmd Msg )
init =
    { project = Nothing
    , footerMsg = Nothing
    }
        |> withNoCmd


subscriptions : Model -> Sub Msg
subscriptions model =
    Ports.getMsgForElm MsgForElm LogError


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        CreateNewProject ->
            createNewProject model

        EditorChanged ->
            editorChanged model

        ShowFooterMsg footerMsg ->
            showFooterMsg footerMsg model

        HideFooterMsg ->
            hideFooterMsg model

        MsgForElm msgForElm ->
            case msgForElm of
                EditorValue sourceCode ->
                    editorValue sourceCode model

                ProjectClosed ->
                    projectClosed model

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


createNewProject : Model -> ( Model, Cmd Msg )
createNewProject model =
    let
        userPackageId =
            PackageId "author/project"

        mainModuleId =
            ModuleId "Main"

        basicsId =
            ModuleId "Basics"

        listId =
            ModuleId "List"

        mainId =
            DefinitionId "Main.main"

        absId =
            DefinitionId "Basics.abs"

        singletonId =
            DefinitionId "List.singleton"
    in
    { model
        | project =
            Just
                { rootPath = "/tmp/elm-browser-project/"
                , index =
                    Just
                        { packages =
                            [ ( userPackageId
                              , { name = "author/project"
                                , version = Nothing
                                , dependencyType = UserPackage
                                , containsEffectModules = False
                                , containsNativeModules = False
                                , modules = ESet.fromList [ mainModuleId ]
                                }
                              )
                            , ( PackageId "elm/core"
                              , { name = "elm/core"
                                , version = Just "1.0.0"
                                , dependencyType = DirectDependency
                                , containsEffectModules = True
                                , containsNativeModules = True
                                , modules = ESet.fromList [ basicsId, listId ]
                                }
                              )
                            ]
                                |> EDict.fromList
                        , modules =
                            [ ( mainModuleId
                              , { name = "Main"
                                , isExposed = True
                                , isEffect = False
                                , isNative = False
                                , isPort = False
                                , definitions = ESet.fromList [ mainId ]
                                , language = Elm
                                }
                              )
                            , ( basicsId
                              , { name = "Basics"
                                , isExposed = True
                                , isEffect = False
                                , isNative = False
                                , isPort = False
                                , definitions = ESet.fromList [ absId ]
                                , language = Elm
                                }
                              )
                            , ( listId
                              , { name = "List"
                                , isExposed = True
                                , isEffect = False
                                , isNative = False
                                , isPort = False
                                , definitions = ESet.fromList [ singletonId ]
                                , language = Elm
                                }
                              )
                            ]
                                |> EDict.fromList
                        , definitions =
                            [ ( mainId
                              , { name = "main"
                                , kind = Constant { type_ = "Html msg" }
                                , isExposed = True
                                , sourceCode = SourceCode """main : Html msg
main =
    Html.text ""
"""
                                }
                              )
                            , ( absId
                              , { name = "abs"
                                , kind = Constant { type_ = "number -> number" }
                                , isExposed = True
                                , sourceCode = SourceCode """abs : number -> number
abs number =
    if number < 0 then
        negate number
    else
        number
"""
                                }
                              )
                            , ( singletonId
                              , { name = "singleton"
                                , kind = Constant { type_ = "a -> List a" }
                                , isExposed = True
                                , sourceCode = SourceCode """singleton : a -> List a
singleton x =
    [x]
"""
                                }
                              )
                            ]
                                |> EDict.fromList
                        }
                , selection = ModuleAndDefinitionSelected mainModuleId mainId
                , filterConfig =
                    { packages =
                        { user = False
                        , directDeps = False
                        , depsOfDeps = False
                        }
                    , modules =
                        { exposed = False
                        , effect = False
                        , native = False
                        , port_ = False
                        }
                    , definitions =
                        { exposed = False
                        }
                    }
                }
    }
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


editorValue : SourceCode -> Model -> ( Model, Cmd Msg )
editorValue sourceCode model =
    let
        selectedDefinitionId : Maybe DefinitionId
        selectedDefinitionId =
            model.project
                |> Maybe.map .selection
                |> Maybe.andThen Selection.selectedDefinitionId

        maybeIndex : Maybe Index
        maybeIndex =
            model.project
                |> Maybe.andThen .index

        selectedDefinition : Maybe Definition
        selectedDefinition =
            Maybe.map2 (\index definitionId -> EDict.get definitionId index.definitions)
                maybeIndex
                selectedDefinitionId
                |> Maybe.andThen identity
    in
    selectedDefinition
        |> Maybe.map (\definition -> { definition | sourceCode = sourceCode })
        |> Maybe.map (asDefinitionIn maybeIndex selectedDefinitionId)
        |> Maybe.map (asIndexIn model.project)
        |> Maybe.map (asProjectIn model)
        |> Maybe.withDefault model
        |> withNoCmd


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
        |> withNoCmd


projectClosed : Model -> ( Model, Cmd Msg )
projectClosed model =
    { model | project = Nothing }
        |> withCmd (Ports.sendMsgForElectron (ChangeTitle (windowTitle Nothing)))


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
