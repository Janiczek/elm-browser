module Types exposing (..)

import Json.Encode as JE
import Html exposing (Html)


type Msg
    = AskForProject
    | CloseProject
    | ShowFooterMsg ( Html Msg, String )
    | HideFooterMsg
    | MsgForElm MsgForElm
    | LogError String
    | SelectOne Column Identifier
    | SelectAnother Column Identifier
    | Deselect Column Identifier


type MsgForElectron
    = ChooseProjectPath
    | ErrorLogRequested String
    | CreateIndex
    | ChangeTitle String
    | SetEditorModel { sourceCode : String, language : Language }


type MsgForElm
    = ProjectPathChosen String
    | NoProjectPathChosen
    | ProjectClosed
    | IndexCreated Index


type alias Model =
    { project : Maybe Project
    , footerMsg : Maybe ( Html Msg, String )
    }


type alias Project =
    { rootPath : String

    -- TODO RemoteData ↓
    , index : Maybe Index
    , selection : Selection
    }


type Column
    = PackageColumn
    | ModuleColumn
    | DefinitionColumn


type Language
    = Elm
    | JavaScript


type alias Selection =
    { packages : List Identifier
    , modules : List Identifier
    , definitions : List Identifier
    }


type alias Index =
    List Package


type alias Package =
    { author : Author
    , name : PackageName
    , version : Version
    , isUserPackage : Bool
    , containsEffectModules : Bool
    , containsNativeModules : Bool
    , modules : List Module
    }


type alias Module =
    { name : ModuleName
    , isExposed : Bool
    , isEffect : Bool
    , isNative : Bool
    , isPort : Bool
    , definitions : List Definition
    }


type alias CommonDefinition a =
    { a
        | name : DefinitionName
        , isExposed : Bool
    }


type alias Author =
    String


type alias PackageName =
    String


type alias Version =
    String


type alias ModuleName =
    String


type alias Definition =
    { name : DefinitionName
    , kind : DefinitionKind
    , isExposed : Bool
    , sourceCode : String
    }


type DefinitionKind
    = Constant { type_ : DefinitionType }
    | Function { type_ : DefinitionType }
    | Type { constructors : List TypeConstructor }
    | TypeAlias


type alias TypeConstructor =
    { name : DefinitionName
    , isExposed : Bool
    , type_ : DefinitionType
    }


type alias DefinitionName =
    String


type alias DefinitionType =
    String


type alias Identifier =
    String


type alias PortData =
    { tag : String
    , data : JE.Value
    }
