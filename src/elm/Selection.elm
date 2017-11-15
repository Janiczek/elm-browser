module Selection exposing (..)

import Types exposing (..)


packageIdentifier : Package -> Identifier
packageIdentifier { author, name } =
    author ++ "/" ++ name


definitionIdentifier : ModuleName -> CommonDefinition a -> Identifier
definitionIdentifier moduleName { name } =
    moduleName ++ "." ++ name


isPackageSelected : Selection -> Package -> Bool
isPackageSelected selection package =
    selection.packages
        |> List.member (packageIdentifier package)


isModuleSelected : Selection -> Module -> Bool
isModuleSelected selection module_ =
    selection.modules
        |> List.member module_.name


isDefinitionSelected : ModuleName -> CommonDefinition a -> Selection -> Bool
isDefinitionSelected moduleName definitionOrConstructor selection =
    selection.definition
        |> Maybe.map (\selectedDefinition -> selectedDefinition == definitionIdentifier moduleName definitionOrConstructor)
        |> Maybe.withDefault False


modulesForPackages : List Identifier -> Index -> List Identifier
modulesForPackages packages index =
    index
        |> List.filter
            (\package ->
                packages
                    |> List.member (packageIdentifier package)
            )
        |> List.concatMap .modules
        |> List.map .name
