module Selection exposing (..)

import EveryDict as EDict
import EverySet as ESet exposing (EverySet)
import Types exposing (..)


packageId : Package -> PackageOnlyId
packageId { author, name } =
    PackageOnlyId (author ++ "/" ++ name)


moduleId : Named a -> ModuleOnlyId
moduleId { name } =
    ModuleOnlyId name


definitionId : String -> CommonDefinition a -> DefinitionOnlyId
definitionId moduleName { name } =
    DefinitionOnlyId (moduleName ++ "." ++ name)


isPackageSelected : Selection -> Package -> Bool
isPackageSelected selection package =
    selection.packages
        |> ESet.member (packageId package)


isModuleIdSelected : Selection -> ModuleOnlyId -> Bool
isModuleIdSelected selection moduleId =
    selection.module_ == Just moduleId


isModuleSelected : Selection -> Module -> Bool
isModuleSelected selection module_ =
    isModuleIdSelected selection (ModuleOnlyId module_.name)


isDefinitionSelected : DefinitionOnlyId -> CommonDefinition a -> Selection -> Bool
isDefinitionSelected definitionId definitionOrConstructor selection =
    selection.definition
        |> Maybe.map (\selectedDefinition -> selectedDefinition == definitionId)
        |> Maybe.withDefault False


modulesForPackages : EverySet PackageOnlyId -> Index -> EverySet ModuleOnlyId
modulesForPackages packages index =
    index.packages
        |> EDict.filter (\packageId _ -> ESet.member packageId packages)
        |> EDict.values
        |> List.map .modules
        |> List.concatMap (ESet.toList)
        |> ESet.fromList


empty : Selection
empty =
    { packages = ESet.empty
    , module_ = Nothing
    , definition = Nothing
    }
