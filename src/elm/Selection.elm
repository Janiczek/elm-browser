module Selection exposing (..)

import Types exposing (..)


identifier : Package -> String
identifier { author, name, version } =
    author ++ "/" ++ name ++ "@" ++ version


isPackageSelected : Package -> Selection -> Bool
isPackageSelected package selection =
    case selection of
        NothingSelected ->
            False

        PackageSelected selectedPackage ->
            identifier package == selectedPackage

        PackageAndModuleSelected selectedPackage _ ->
            identifier package == selectedPackage

        AllSelected selectedPackage _ _ ->
            identifier package == selectedPackage


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


isDefinitionSelected : Definition -> Selection -> Bool
isDefinitionSelected definition selection =
    case selection of
        NothingSelected ->
            False

        PackageSelected _ ->
            False

        PackageAndModuleSelected _ _ ->
            False

        AllSelected _ _ selectedDefinition ->
            definition == selectedDefinition
