module Index exposing (decoder, sourceCode, language, definitionsWithModuleName)

import Json.Decode as JD exposing (Decoder)
import Selection
import Types exposing (..)


decoder : Decoder Index
decoder =
    JD.list package


package : Decoder Package
package =
    JD.map7 Package
        (JD.field "author" JD.string)
        (JD.field "name" JD.string)
        (JD.field "version" JD.string)
        (JD.field "isUserPackage" JD.bool)
        (JD.field "containsEffectModules" JD.bool)
        (JD.field "containsNativeModules" JD.bool)
        (JD.field "modules" (JD.list module_))


module_ : Decoder Module
module_ =
    JD.map6 Module
        (JD.field "name" JD.string)
        (JD.field "isExposed" JD.bool)
        (JD.field "isEffect" JD.bool)
        (JD.field "isNative" JD.bool)
        (JD.field "isPort" JD.bool)
        (JD.field "definitions" (JD.list definition))


definition : Decoder Definition
definition =
    JD.map4 Definition
        (JD.field "name" JD.string)
        definitionKind
        (JD.field "isExposed" JD.bool)
        (JD.field "sourceCode" JD.string)


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
    selectedModuleNameAndDefinition selection index
        |> ifInSelectedPackage selection index
        |> Maybe.map (\( _, definition ) -> definition.sourceCode)


language : Selection -> Index -> Maybe Language
language selection index =
    moduleForSelectedDefinition selection index
        |> Maybe.map languageForModule


moduleForSelectedDefinition : Selection -> Index -> Maybe Module
moduleForSelectedDefinition selection index =
    selectedModuleNameAndDefinition selection index
        |> Maybe.map (\( moduleName, _ ) -> moduleName)
        |> Maybe.andThen
            (\moduleName ->
                index
                    |> List.concatMap .modules
                    |> List.filter (\module_ -> module_.name == moduleName)
                    |> List.head
            )


selectedModuleNameAndDefinition : Selection -> Index -> Maybe ( ModuleName, Definition )
selectedModuleNameAndDefinition selection index =
    selection.definition
        |> Maybe.andThen
            (\selectedDefinition ->
                index
                    |> List.concatMap .modules
                    |> definitionsWithModuleName
                    |> List.filter
                        (\( moduleName, definition ) ->
                            Selection.definitionIdentifier moduleName definition == selectedDefinition
                        )
                    |> List.head
            )


ifInSelectedPackage : Selection -> Index -> Maybe ( ModuleName, Definition ) -> Maybe ( ModuleName, Definition )
ifInSelectedPackage selection index maybeModuleNameAndDefinition =
    maybeModuleNameAndDefinition
        |> Maybe.andThen
            (\( moduleName, definition ) ->
                selectedPackages selection index
                    |> List.concatMap .modules
                    |> List.filter (\module_ -> module_.name == moduleName)
                    -- if exists, return what you got:
                    |> List.head
                    |> Maybe.map (\_ -> ( moduleName, definition ))
            )


languageForModule : Module -> Language
languageForModule module_ =
    if module_.isNative then
        JavaScript
    else
        Elm


selectedPackages : Selection -> Index -> List Package
selectedPackages selection index =
    index
        |> List.filter
            (\package ->
                selection.packages
                    |> List.member (Selection.packageIdentifier package)
            )


definitionsWithModuleName : List Module -> List ( ModuleName, Definition )
definitionsWithModuleName modules =
    modules
        |> List.concatMap
            (\module_ ->
                module_.definitions
                    |> List.map (\definition -> ( module_.name, definition ))
            )
