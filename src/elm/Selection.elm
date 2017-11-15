module Selection exposing (..)

import Types exposing (..)


packageIdentifier : Package -> Identifier
packageIdentifier { author, name } =
    author ++ "/" ++ name


definitionIdentifier : ModuleName -> CommonDefinition a -> Identifier
definitionIdentifier moduleName { name } =
    moduleName ++ "." ++ name


isPackageSelected : Package -> Selection -> Bool
isPackageSelected package selection =
    selection.packages
        |> List.member (packageIdentifier package)


isModuleSelected : Module -> Selection -> Bool
isModuleSelected module_ selection =
    selection.modules
        |> List.member module_.name


isDefinitionSelected : ModuleName -> CommonDefinition a -> Selection -> Bool
isDefinitionSelected moduleName definitionOrConstructor selection =
    selection.definition
        |> Maybe.map (\selectedDefinition -> selectedDefinition == definitionIdentifier moduleName definitionOrConstructor)
        |> Maybe.withDefault False
