module Selection exposing (..)

import AssocList as Dict exposing (Dict)
import AssocSet as Set exposing (Set)
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
isPackageSelected packageId_ selection =
    selection
        |> selectedPackageId
        |> Maybe.map ((==) packageId_)
        |> Maybe.withDefault False


isModuleSelected : ModuleId -> Selection -> Bool
isModuleSelected moduleId_ selection =
    selection
        |> selectedModuleId
        |> Maybe.map ((==) moduleId_)
        |> Maybe.withDefault False


isDefinitionSelected : DefinitionId -> Selection -> Bool
isDefinitionSelected definitionId_ selection =
    selection
        |> selectedDefinitionId
        |> Maybe.map ((==) definitionId_)
        |> Maybe.withDefault False


modulesForPackages : Set PackageId -> Index -> Set ModuleId
modulesForPackages packages index =
    index.packages
        |> Dict.filter (\packageId_ _ -> Set.member packageId_ packages)
        |> Dict.values
        |> List.map .modules
        |> List.concatMap Set.toList
        |> Set.fromList


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
