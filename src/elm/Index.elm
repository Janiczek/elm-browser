module Index exposing (..)

import EveryDict as EDict exposing (EveryDict)
import EverySet as ESet exposing (EverySet)
import Json.Decode as JD exposing (Decoder)
import Json.Decode.Pipeline as JDP
import Maybe.Extra as Maybe
import Selection
import Types exposing (..)
import Types.Json exposing (..)
import Utils


decoder : Decoder JsonIndex
decoder =
    JD.list package


package : Decoder JsonPackage
package =
    JDP.decode JsonPackage
        |> JDP.required "author" JD.string
        |> JDP.required "name" JD.string
        |> JDP.required "version" JD.string
        |> JDP.required "isUserPackage" JD.bool
        |> JDP.required "isDirectDependency" JD.bool
        |> JDP.required "containsEffectModules" JD.bool
        |> JDP.required "containsNativeModules" JD.bool
        |> JDP.required "modules" (JD.list module_)


module_ : Decoder JsonModule
module_ =
    JD.map7 JsonModule
        (JD.field "name" JD.string)
        (JD.field "isExposed" JD.bool)
        (JD.field "isEffect" JD.bool)
        (JD.field "isNative" JD.bool)
        (JD.field "isPort" JD.bool)
        (JD.field "definitions" (JD.list definition))
        (JD.field "language" language)


definition : Decoder Definition
definition =
    JD.map4 Definition
        (JD.field "name" JD.string)
        definitionKind
        (JD.field "isExposed" JD.bool)
        (JD.field "sourceCode" JD.string)


language : Decoder Language
language =
    JD.string
        |> JD.andThen
            (\string ->
                case string of
                    "javascript" ->
                        JD.succeed JavaScript

                    "elm" ->
                        JD.succeed Elm

                    _ ->
                        JD.fail "Unknown language"
            )


definitionKind : Decoder DefinitionKind
definitionKind =
    JD.field "kind" JD.string
        |> JD.andThen
            (\kind ->
                case kind of
                    "constant" ->
                        constant

                    "function" ->
                        function

                    "type" ->
                        type_

                    "typeConstructor" ->
                        typeConstructor

                    "typeAlias" ->
                        typeAlias

                    _ ->
                        JD.fail "Unknown definition kind!"
            )


constant : Decoder DefinitionKind
constant =
    JD.field "type" JD.string
        |> JD.map (\type_ -> Constant { type_ = type_ })


function : Decoder DefinitionKind
function =
    JD.field "type" JD.string
        |> JD.map (\type_ -> Function { type_ = type_ })


type_ : Decoder DefinitionKind
type_ =
    JD.succeed Type


typeConstructor : Decoder DefinitionKind
typeConstructor =
    JD.field "type" JD.string
        |> JD.map (\type_ -> TypeConstructor { type_ = type_ })


typeAlias : Decoder DefinitionKind
typeAlias =
    JD.succeed TypeAlias


sourceCode : Selection -> Index -> FilterConfig -> Maybe String
sourceCode selection index filterConfig =
    selectedModuleIdAndDefinition selection index
        |> ifDefinitionCanBeShown selection index filterConfig
        |> Maybe.map (\( _, definition ) -> definition.sourceCode)


selectedLanguage : Selection -> Index -> Maybe Language
selectedLanguage selection index =
    moduleForSelectedDefinition selection index
        |> Maybe.map .language


moduleForSelectedDefinition : Selection -> Index -> Maybe Module
moduleForSelectedDefinition selection index =
    selection.definition
        |> Maybe.andThen
            (\definitionId ->
                index.modules
                    |> EDict.filter (\_ module_ -> ESet.member definitionId module_.definitions)
                    |> EDict.values
                    |> List.head
            )


moduleIdForSelectedDefinition : Selection -> Index -> Maybe ModuleOnlyId
moduleIdForSelectedDefinition selection index =
    selection.definition
        |> Maybe.andThen
            (\definitionId ->
                index.modules
                    |> EDict.filter (\_ module_ -> ESet.member definitionId module_.definitions)
                    |> EDict.keys
                    |> List.head
            )


selectedModuleIdAndDefinition : Selection -> Index -> Maybe ( ModuleOnlyId, Definition )
selectedModuleIdAndDefinition selection index =
    Maybe.map2 (,)
        (moduleIdForSelectedDefinition selection index)
        (selectedDefinition selection index)
        |> Maybe.andThen
            (\( moduleId, definition ) ->
                if selection.module_ == (Just moduleId) then
                    Just ( moduleId, definition )
                else
                    Nothing
            )


selectedDefinition : Selection -> Index -> Maybe Definition
selectedDefinition selection index =
    selection.definition
        |> Maybe.andThen (\selectedDefinitionId -> EDict.get selectedDefinitionId index.definitions)


selectedDefinitionAndId : Selection -> Index -> Maybe ( DefinitionOnlyId, Definition )
selectedDefinitionAndId selection index =
    Maybe.map2 (,)
        selection.definition
        (selectedDefinition selection index)


ifDefinitionCanBeShown :
    Selection
    -> Index
    -> FilterConfig
    -> Maybe ( ModuleOnlyId, Definition )
    -> Maybe ( ModuleOnlyId, Definition )
ifDefinitionCanBeShown selection index filterConfig maybeModuleIdAndDefinition =
    let
        shownDefs =
            shownDefinitions index selection filterConfig.definitions
                |> List.map Tuple.second
    in
        maybeModuleIdAndDefinition
            |> Maybe.filter (\( _, def ) -> List.member def shownDefs)


selectedPackages : Selection -> Index -> EverySet Package
selectedPackages selection index =
    index.packages
        |> EDict.filter (\packageId _ -> ESet.member packageId selection.packages)
        |> Utils.dictValuesToSet


empty : Index
empty =
    { packages = EDict.empty
    , modules = EDict.empty
    , definitions = EDict.empty
    }


normalize : JsonIndex -> Index
normalize index =
    let
        modulesToIds : List JsonModule -> ModuleIds
        modulesToIds modules =
            modules
                |> List.map Selection.moduleId
                |> ESet.fromList

        packages =
            index
                |> List.map
                    (\jsonPackage ->
                        { author = jsonPackage.author
                        , name = jsonPackage.name
                        , version = jsonPackage.version
                        , dependencyType =
                            if jsonPackage.isUserPackage then
                                UserPackage
                            else if jsonPackage.isDirectDependency then
                                DirectDependency
                            else
                                DependencyOfDependency
                        , containsEffectModules = jsonPackage.containsEffectModules
                        , containsNativeModules = jsonPackage.containsNativeModules
                        , modules = modulesToIds jsonPackage.modules
                        }
                    )
                |> List.map (\package -> ( Selection.packageId package, package ))
                |> EDict.fromList

        definitionsToIds : String -> List Definition -> DefinitionIds
        definitionsToIds moduleName definitions =
            definitions
                |> List.map (Selection.definitionId moduleName)
                |> ESet.fromList

        modules =
            index
                |> List.concatMap .modules
                |> List.map
                    (\module_ ->
                        { module_
                            | definitions =
                                definitionsToIds
                                    module_.name
                                    module_.definitions
                        }
                    )
                |> List.map
                    (\module_ ->
                        ( Selection.moduleId module_
                        , module_
                        )
                    )
                |> EDict.fromList

        definitions =
            -- (ModuleName, Definition)
            -- EDict DefinitionId Definition
            index
                |> List.concatMap .modules
                |> List.map (\module_ -> ( module_.name, module_.definitions ))
                |> List.concatMap
                    (\( moduleName, definitions ) ->
                        definitions
                            |> List.map (\definition -> ( moduleName, definition ))
                    )
                |> List.map
                    (\( moduleName, definition ) ->
                        ( Selection.definitionId moduleName definition
                        , definition
                        )
                    )
                |> EDict.fromList
    in
        { packages = packages
        , modules = modules
        , definitions = definitions
        }


shownDefinitions : Index -> Selection -> DefinitionsFilterConfig -> List ( DefinitionOnlyId, Definition )
shownDefinitions index selection { exposed } =
    let
        showAll =
            not exposed
    in
        if canShowDefinitionsFromSelectedModule index selection then
            selection.module_
                |> Maybe.andThen ((flip EDict.get) index.modules)
                |> Maybe.map .definitions
                |> Maybe.withDefault ESet.empty
                |> Utils.dictGetKv index.definitions
                |> List.filter
                    (\( _, { isExposed } ) ->
                        showAll
                            || if exposed then
                                isExposed
                               else
                                True
                    )
        else
            []


canShowDefinitionsFromSelectedModule : Index -> Selection -> Bool
canShowDefinitionsFromSelectedModule index selection =
    selection.module_
        |> Maybe.map (\module_ -> ESet.isEmpty selection.packages || ESet.member module_ (Selection.modulesForPackages selection.packages index))
        |> Maybe.withDefault True
