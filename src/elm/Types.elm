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


type MsgForElm
    = ProjectPathChosen Path
    | NoProjectPathChosen


type alias Model =
    { project : Maybe Project
    }


type alias Project =
    { rootPath : Path
    }


type alias Path =
    String


type alias PortData =
    { tag : String
    , data : JE.Value
    }
