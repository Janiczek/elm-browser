module Selection exposing (..)

import EveryDict as EDict
import EverySet as ESet exposing (EverySet)
import Types exposing (..)


selectedPackageId : Selection -> Maybe PackageId
selectedPackageId selection =
    case selection of
        NothingSelected ->
            Nothing

        PackageSelected id ->
            Just id

        ModuleSelected _ ->
            Nothing

        PackageAndModuleSelected id _ ->
            Just id

        ModuleAndDefinitionSelected _ _ ->
            Nothing

        AllSelected id _ _ ->
            Just id


selectedModuleId : Selection -> Maybe ModuleId
selectedModuleId selection =
    case selection of
        NothingSelected ->
            Nothing

        PackageSelected _ ->
            Nothing

        ModuleSelected id ->
            Just id

        PackageAndModuleSelected _ id ->
            Just id

        ModuleAndDefinitionSelected id _ ->
            Just id

        AllSelected _ id _ ->
            Just id


selectedDefinitionId : Selection -> Maybe DefinitionId
selectedDefinitionId selection =
    case selection of
        NothingSelected ->
            Nothing

        PackageSelected _ ->
            Nothing

        ModuleSelected _ ->
            Nothing

        PackageAndModuleSelected _ _ ->
            Nothing

        ModuleAndDefinitionSelected _ id ->
            Just id

        AllSelected _ _ id ->
            Just id


isPackageSelected : PackageId -> Selection -> Bool
isPackageSelected packageId selection =
    selection
        |> selectedPackageId
        |> Maybe.map ((==) packageId)
        |> Maybe.withDefault False


isModuleSelected : ModuleId -> Selection -> Bool
isModuleSelected moduleId selection =
    selection
        |> selectedModuleId
        |> Maybe.map ((==) moduleId)
        |> Maybe.withDefault False


isDefinitionSelected : DefinitionId -> Selection -> Bool
isDefinitionSelected definitionId selection =
    selection
        |> selectedDefinitionId
        |> Maybe.map ((==) definitionId)
        |> Maybe.withDefault False


modulesForPackages : EverySet PackageId -> Index -> EverySet ModuleId
modulesForPackages packages index =
    index.packages
        |> EDict.filter (\packageId _ -> ESet.member packageId packages)
        |> EDict.values
        |> List.map .modules
        |> List.concatMap ESet.toList
        |> ESet.fromList


packageId : Named a -> PackageId
packageId { name } =
    PackageId name


moduleId : Named a -> ModuleId
moduleId { name } =
    ModuleId name


definitionId : String -> String -> DefinitionId
definitionId moduleName definition =
    definitionQualifiedName moduleName definition
        |> DefinitionId


definitionQualifiedName : String -> String -> String
definitionQualifiedName moduleName name =
    moduleName ++ "." ++ name
