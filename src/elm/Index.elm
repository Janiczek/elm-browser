module Index exposing (decoder)

import Json.Decode as JD exposing (Decoder)
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
