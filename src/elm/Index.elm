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
    JD.field "constructors" (JD.list typeConstructor)
        |> JD.map (\constructors -> Type { constructors = constructors })


typeAlias : Decoder DefinitionKind
typeAlias =
    JD.succeed TypeAlias


typeConstructor : Decoder TypeConstructor
typeConstructor =
    JD.map3 TypeConstructor
        (JD.field "name" JD.string)
        (JD.field "isExposed" JD.bool)
        (JD.field "type" JD.string)


sourceCode : Selection -> Index -> Maybe String
sourceCode selection index =
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
                    |> List.map (\( _, definition ) -> definition.sourceCode)
                    |> List.head
            )


language : Selection -> Index -> Maybe Language
language selection index =
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
                    |> List.map (\( moduleName, _ ) -> moduleName)
                    |> List.head
                    |> Maybe.andThen
                        (\moduleName ->
                            index
                                |> List.concatMap .modules
                                |> List.filter (\module_ -> module_.name == moduleName)
                                |> List.map languageForModule
                                |> List.head
                        )
            )


languageForModule : Module -> Language
languageForModule module_ =
    if module_.isNative then
        JavaScript
    else
        Elm


definitionsWithModuleName : List Module -> List ( ModuleName, Definition )
definitionsWithModuleName modules =
    modules
        |> List.concatMap
            (\module_ ->
                module_.definitions
                    |> List.map (\definition -> ( module_.name, definition ))
            )
