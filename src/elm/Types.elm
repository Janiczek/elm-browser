module Types exposing (..)

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
    | SelectOne Column Identifier
    | SelectAnother Column Identifier
    | Deselect Column Identifier


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
    }


type Column
    = PackageColumn
    | ModuleColumn
    | DefinitionColumn


type alias Selection =
    { packages : List Identifier
    , modules : List Identifier
    , definition : Maybe Identifier
    }


type Language
    = Elm
    | JavaScript


type alias Index =
    List Package


type alias Package =
    { author : String
    , name : String
    , version : String
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
