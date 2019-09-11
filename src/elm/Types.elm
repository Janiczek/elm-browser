module Types exposing (..)

import AssocList as Dict exposing (Dict)
import AssocSet as Set exposing (Set)
import Editor
import Elm.Syntax.Range exposing (Location, Range)
import Html exposing (Html)
import Json.Encode as JE


type Msg
    = MsgForElm MsgForElm
    | LogError String
      -- user actions
    | CreateProjectPressed
    | OpenProjectPressed
    | SaveChange DefinitionId SourceCode
      -- selection
    | SelectPackage PackageId
    | SelectModule ModuleId
    | SelectDefinition DefinitionId
      -- deselection
    | DeselectPackage
    | DeselectModule
    | DeselectDefinition
      -- other
    | SetFilter FilterType Bool
      -- app actions
    | ShowFooterMsg ( Html Msg, String )
    | HideFooterMsg
    | ShowColumnTitle Column String
    | HideColumnTitle Column
      -- components
    | EditorMsg Editor.Msg


type MsgForElectron
    = ErrorLogRequested String
    | ChangeTitle String
    | ReplaceInFile ReplaceInFileData
    | CreateProject
    | OpenProject
    | ListFilesForIndex String


type MsgForElm
    = ProjectClosed
    | ProjectCreated String
    | ProjectOpened String
    | FilesForIndex (List ( String, String ))


type alias ReplaceInFileData =
    { filepath : String
    , from : Location
    , to : Location
    , replacement : String
    }


type alias Model =
    { project : Maybe Project
    , isCompiling : Bool
    , footerMsg : Maybe ( Html Msg, String )
    , columnTitles : ColumnTitles
    , editor : Editor.Model
    }


type alias ColumnTitles =
    { packages : Maybe String
    , modules : Maybe String
    , definitions : Maybe String
    }


type alias Project =
    { rootPath : String
    , index : Maybe Index
    , selection : Selection
    , filterConfig : FilterConfig
    , changes : Dict DefinitionId SourceCode
    }


type alias FilterConfig =
    { packages : PackagesFilterConfig
    , modules : ModulesFilterConfig
    , definitions : DefinitionsFilterConfig
    }


type Column
    = Packages
    | Modules
    | Definitions


type FilterType
    = -- packages
      UserPackages
    | DirectDeps
    | DepsOfDeps
      -- modules
    | ExposedModules
    | EffectModules
    | PortModules
      -- definitions
    | ExposedDefinitions


type alias PackagesFilterConfig =
    { user : Bool
    , directDeps : Bool
    , depsOfDeps : Bool
    }


type alias ModulesFilterConfig =
    { exposed : Bool
    , effect : Bool
    , port_ : Bool
    }


type alias DefinitionsFilterConfig =
    { exposed : Bool
    }


type Selection
    = NothingSelected
    | PackageSelected PackageId
    | ModuleSelected ModuleId
    | PackageAndModuleSelected PackageId ModuleId
    | ModuleAndDefinitionSelected ModuleId DefinitionId
    | AllSelected PackageId ModuleId DefinitionId


type alias Index =
    { packages : Dict PackageId Package
    , modules : Dict ModuleId Module
    , definitions : Dict DefinitionId Definition
    }


type alias Package =
    { name : String
    , version : String
    , dependencyType : DependencyType
    , modules : Set ModuleId
    }


type alias Module =
    { name : String
    , path : String
    , isExposed : Bool
    , isEffect : Bool
    , isPort : Bool
    , definitions : Set DefinitionId
    }


type alias Definition =
    { name : String
    , qualifiedName : String
    , kind : DefinitionKind
    , isExposed : Bool
    , sourceCode : SourceCode
    , range : Range
    }


type SourceCode
    = SourceCode String


type alias Named a =
    { a | name : String }


type alias CommonDefinition a =
    Named { a | isExposed : Bool }


type DependencyType
    = UserPackage
    | DirectDependency
    | DependencyOfDependency


type PackageId
    = PackageId String


type ModuleId
    = ModuleId String


type DefinitionId
    = DefinitionId String


type DefinitionKind
    = Constant
    | Function
    | Type
    | TypeAlias


type alias PortData =
    { tag : String
    , data : JE.Value
    }
