module Index exposing (..)

import EveryDict as EDict exposing (EveryDict)
import EverySet as ESet exposing (EverySet)
import Json.Decode as JD exposing (Decoder)
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
    JD.map7 JsonPackage
        (JD.field "author" JD.string)
        (JD.field "name" JD.string)
        (JD.field "version" JD.string)
        (JD.field "isUserPackage" JD.bool)
        (JD.field "containsEffectModules" JD.bool)
        (JD.field "containsNativeModules" JD.bool)
        (JD.field "modules" (JD.list module_))


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


sourceCode : Selection -> Index -> Maybe String
sourceCode selection index =
    selectedModuleIdAndDefinition selection index
        |> ifInSelectedPackage selection index
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


ifInSelectedPackage :
    Selection
    -> Index
    -> Maybe ( ModuleOnlyId, Definition )
    -> Maybe ( ModuleOnlyId, Definition )
ifInSelectedPackage selection index maybeModuleIdAndDefinition =
    maybeModuleIdAndDefinition
        |> Maybe.filter (\( moduleId, definition ) -> moduleIsInSelectedPackage selection index moduleId)


moduleIsInSelectedPackage : Selection -> Index -> ModuleOnlyId -> Bool
moduleIsInSelectedPackage selection index moduleId =
    selectedPackages selection index
        |> ESet.map .modules
        |> ESet.toList
        |> List.foldl ESet.union ESet.empty
        |> ESet.member moduleId


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
                |> List.map (\package -> { package | modules = modulesToIds package.modules })
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
