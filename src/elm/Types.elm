module Types exposing (..)

import Json.Encode as JE


type Msg
    = AskForProject
    | CloseProject
    | MsgForElm MsgForElm
    | LogError String


type MsgForElectron
    = ChooseProjectPath
    | ErrorLogRequested String
    | CreateIndex
    | ChangeTitle String


type MsgForElm
    = ProjectPathChosen String
    | NoProjectPathChosen
    | ProjectClosed
    | IndexCreated Index


type alias Model =
    { project : Maybe Project
    }


type alias Project =
    { rootPath : String
    , index : Maybe Index
    , selection : Selection
    }


type Selection
    = NothingSelected
    | PackageSelected String
    | PackageAndModuleSelected String String
    | AllSelected String String String


type alias Index =
    List Package


type alias Package =
    { author : Author
    , name : PackageName
    , version : Version
    , isUserPackage : Bool
    , modules : List Module
    }


type alias Module =
    { name : ModuleName
    , definitions : List Definition
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
    String


type alias PortData =
    { tag : String
    , data : JE.Value
    }
