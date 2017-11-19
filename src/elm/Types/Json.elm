module Types.Json exposing (..)

import Types exposing (..)


type alias JsonIndex =
    List JsonPackage


type alias JsonPackage =
    { author : String
    , name : String
    , version : String
    , isUserPackage : Bool
    , isDirectDependency : Bool
    , containsEffectModules : Bool
    , containsNativeModules : Bool
    , modules : List JsonModule
    }


type alias JsonModule =
    { name : String
    , isExposed : Bool
    , isEffect : Bool
    , isNative : Bool
    , isPort : Bool
    , definitions : List Definition
    , language : Language
    }
