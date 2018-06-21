module Index exposing (..)

import Elm.Syntax.Range as Range
import EveryDict as EDict exposing (EveryDict)
import EverySet as ESet exposing (EverySet)
import Json.Decode as JD exposing (Decoder)
import Maybe.Extra as Maybe
import Selection
import Types exposing (..)
import Utils


definition : Decoder Definition
definition =
    JD.map5 Definition
        (JD.field "name" JD.string)
        definitionKind
        (JD.field "isExposed" JD.bool)
        (JD.field "sourceCode" (JD.string |> JD.map SourceCode))
        (JD.field "range" Range.decode)


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


sourceCode : Selection -> Index -> FilterConfig -> EveryDict DefinitionId SourceCode -> Maybe SourceCode
sourceCode selection index filterConfig changes =
    let
        definitionId : Maybe DefinitionId
        definitionId =
            Selection.selectedDefinitionId selection

        moduleIdAndDefinition : Maybe ( ModuleId, Definition )
        moduleIdAndDefinition =
            selectedModuleIdAndDefinition selection index
                |> ifDefinitionCanBeShown selection index filterConfig
    in
    Maybe.map2
        (\definitionId ( _, definition ) ->
            changes
                |> EDict.get definitionId
                |> Maybe.withDefault definition.sourceCode
        )
        definitionId
        moduleIdAndDefinition


selectedLanguage : Selection -> Index -> Maybe Language
selectedLanguage selection index =
    moduleForSelectedDefinition selection index
        |> Maybe.map .language


moduleForSelectedDefinition : Selection -> Index -> Maybe Module
moduleForSelectedDefinition selection index =
    selection
        |> Selection.selectedDefinitionId
        |> Maybe.andThen
            (\definitionId ->
                index.modules
                    |> EDict.filter (\_ module_ -> ESet.member definitionId module_.definitions)
                    |> EDict.values
                    |> List.head
            )


moduleIdForSelectedDefinition : Selection -> Index -> Maybe ModuleId
moduleIdForSelectedDefinition selection index =
    selection
        |> Selection.selectedDefinitionId
        |> Maybe.andThen
            (\definitionId ->
                index.modules
                    |> EDict.filter (\_ module_ -> ESet.member definitionId module_.definitions)
                    |> EDict.keys
                    |> List.head
            )


selectedModuleIdAndDefinition : Selection -> Index -> Maybe ( ModuleId, Definition )
selectedModuleIdAndDefinition selection index =
    Maybe.map2 (,)
        (moduleIdForSelectedDefinition selection index)
        (selectedDefinition selection index)
        |> Maybe.andThen
            (\( moduleId, definition ) ->
                if Selection.selectedModuleId selection == Just moduleId then
                    Just ( moduleId, definition )
                else
                    Nothing
            )


selectedDefinition : Selection -> Index -> Maybe Definition
selectedDefinition selection index =
    selection
        |> Selection.selectedDefinitionId
        |> Maybe.andThen (\definitionId -> EDict.get definitionId index.definitions)


selectedDefinitionAndId : Selection -> Index -> Maybe ( DefinitionId, Definition )
selectedDefinitionAndId selection index =
    Maybe.map2 (,)
        (Selection.selectedDefinitionId selection)
        (selectedDefinition selection index)


ifDefinitionCanBeShown :
    Selection
    -> Index
    -> FilterConfig
    -> Maybe ( ModuleId, Definition )
    -> Maybe ( ModuleId, Definition )
ifDefinitionCanBeShown selection index filterConfig maybeModuleIdAndDefinition =
    let
        shownDefs =
            shownDefinitions index selection filterConfig.definitions
                |> List.map Tuple.second
    in
    maybeModuleIdAndDefinition
        |> Maybe.filter (\( _, def ) -> List.member def shownDefs)


selectedPackage : Selection -> Index -> Maybe Package
selectedPackage selection index =
    Selection.selectedPackageId selection
        |> Maybe.andThen (\packageId -> EDict.get packageId index.packages)


empty : Index
empty =
    { packages = EDict.empty
    , modules = EDict.empty
    , definitions = EDict.empty
    }


shownDefinitions : Index -> Selection -> DefinitionsFilterConfig -> List ( DefinitionId, Definition )
shownDefinitions index selection { exposed } =
    let
        showAll =
            not exposed
    in
    if canShowDefinitionsFromSelectedModule index selection then
        selection
            |> Selection.selectedModuleId
            |> Maybe.andThen (flip EDict.get index.modules)
            |> Maybe.map .definitions
            |> Maybe.withDefault ESet.empty
            |> Utils.dictGetKv index.definitions
            |> List.filter
                (\( _, { isExposed } ) ->
                    showAll
                        || (if exposed then
                                isExposed
                            else
                                True
                           )
                )
    else
        []


canShowDefinitionsFromSelectedModule : Index -> Selection -> Bool
canShowDefinitionsFromSelectedModule index selection =
    let
        noPackageSelected : Bool
        noPackageSelected =
            Selection.selectedPackageId selection == Nothing

        selectedModuleIsInSelectedPackage : Bool
        selectedModuleIsInSelectedPackage =
            Maybe.map2 (moduleIsInPackage index)
                (Selection.selectedModuleId selection)
                (Selection.selectedPackageId selection)
                |> Maybe.withDefault True
    in
    noPackageSelected
        || selectedModuleIsInSelectedPackage


moduleIsInPackage : Index -> ModuleId -> PackageId -> Bool
moduleIsInPackage index moduleId packageId =
    index.packages
        |> EDict.get packageId
        |> Maybe.map .modules
        |> Maybe.map (ESet.member moduleId)
        |> Maybe.withDefault False
