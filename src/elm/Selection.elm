module Selection exposing (..)

import Types exposing (..)


packageIdentifier : Package -> String
packageIdentifier { author, name, version } =
    author ++ "/" ++ name ++ "@" ++ version


definitionIdentifier : ModuleName -> Definition -> String
definitionIdentifier moduleName { name } =
    moduleName ++ "." ++ name


isPackageSelected : Package -> Selection -> Bool
isPackageSelected package selection =
    case selection of
        NothingSelected ->
            False

        PackageSelected selectedPackage ->
            packageIdentifier package == selectedPackage

        PackageAndModuleSelected selectedPackage _ ->
            packageIdentifier package == selectedPackage

        AllSelected selectedPackage _ _ ->
            packageIdentifier package == selectedPackage


isModuleSelected : Module -> Selection -> Bool
isModuleSelected module_ selection =
    case selection of
        NothingSelected ->
            False

        PackageSelected _ ->
            False

        PackageAndModuleSelected _ selectedModule ->
            module_.name == selectedModule

        AllSelected _ selectedModule _ ->
            module_.name == selectedModule


isDefinitionSelected : ModuleName -> Definition -> Selection -> Bool
isDefinitionSelected moduleName definition selection =
    case selection of
        NothingSelected ->
            False

        PackageSelected _ ->
            False

        PackageAndModuleSelected _ _ ->
            False

        AllSelected _ _ selectedDefinition ->
            definitionIdentifier moduleName definition == selectedDefinition
