module Types exposing (..)

import EveryDict exposing (EveryDict)
import EverySet exposing (EverySet)
import Html exposing (Html)
import Json.Encode as JE


type Msg
    = AskForProject
    | CloseProject
    | ShowFooterMsg ( Html Msg, String )
    | HideFooterMsg
    | EditorChanged
    | MsgForElm MsgForElm
    | LogError String
    | SelectOne Id
    | SelectAnother Id
    | Deselect Id
    | SetFilter FilterType Bool


type MsgForElectron
    = ChooseProjectPath
    | ErrorLogRequested String
    | CreateIndex
    | ChangeTitle String
    | FetchEditorValue


type MsgForElm
    = ProjectPathChosen String
    | NoProjectPathChosen
    | ProjectClosed
    | IndexCreated Index
    | EditorValue String


type alias Model =
    { project : Maybe Project
    , footerMsg : Maybe ( Html Msg, String )
    }


type alias Project =
    { rootPath : String

    -- TODO RemoteData ↓
    , index : Maybe Index
    , selection : Selection
    , filterConfig : FilterConfig
    }


type alias FilterConfig =
    { packages : PackagesFilterConfig
    , modules : ModulesFilterConfig
    , definitions : DefinitionsFilterConfig
    }


type FilterType
    = -- packages
      UserPackages
    | DirectDeps
    | DepsOfDeps
      -- modules
    | ExposedModules
    | EffectModules
    | NativeModules
    | PortModules
      -- definitions
    | ExposedDefinitions


type alias PackagesFilterConfig =
    -- TODO maybe effect and native-containing packages? "dangerous?"
    { user : Bool
    , directDeps : Bool
    , depsOfDeps : Bool
    }


type alias ModulesFilterConfig =
    { exposed : Bool
    , effect : Bool
    , native : Bool
    , port_ : Bool
    }


type alias DefinitionsFilterConfig =
    { exposed : Bool
    }


type alias Selection =
    { packages : PackageIds

    -- TODO is there any use for multiple modules selection?
    , module_ : Maybe ModuleOnlyId

    -- TODO maybe later: select more definitions -> diff
    , definition : Maybe DefinitionOnlyId
    }


type alias Index =
    { packages : Packages
    , modules : Modules
    , definitions : Definitions
    }


type alias Package =
    { author : String
    , name : String
    , version : String
    , dependencyType : DependencyType
    , containsEffectModules : Bool
    , containsNativeModules : Bool
    , modules : ModuleIds
    }


type alias Module =
    { name : String
    , isExposed : Bool
    , isEffect : Bool
    , isNative : Bool
    , isPort : Bool
    , definitions : DefinitionIds
    , language : Language
    }


type alias Definition =
    { name : String
    , kind : DefinitionKind
    , isExposed : Bool
    , sourceCode : String
    }


type alias Named a =
    { a | name : String }


type alias Authored a =
    { a | author : String }


type alias CommonDefinition a =
    Named { a | isExposed : Bool }


type DependencyType
    = UserPackage
    | DirectDependency
    | DependencyOfDependency


type Language
    = -- TODO HTML, CSS?
      Elm
    | JavaScript


type alias Packages =
    EveryDict PackageOnlyId Package


type alias Modules =
    EveryDict ModuleOnlyId Module


type alias Definitions =
    EveryDict DefinitionOnlyId Definition


type alias PackageIds =
    EverySet PackageOnlyId


type alias ModuleIds =
    EverySet ModuleOnlyId


type alias DefinitionIds =
    EverySet DefinitionOnlyId


type PackageOnlyId
    = PackageOnlyId String


type ModuleOnlyId
    = ModuleOnlyId String


type DefinitionOnlyId
    = DefinitionOnlyId String


type Id
    = PackageId PackageOnlyId
    | ModuleId ModuleOnlyId
    | DefinitionId DefinitionOnlyId


type DefinitionKind
    = Constant { type_ : String }
    | Function { type_ : String }
    | Type
    | TypeConstructor { type_ : String }
    | TypeAlias


type alias PortData =
    { tag : String
    , data : JE.Value
    }



-- TODO fixities somewhere?
