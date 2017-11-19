module View.Icon exposing (..)

import Html exposing (Html)
import Types exposing (..)
import View.Icon.Common exposing (..)


portModuleIcon : Bool -> Html Msg
portModuleIcon condition =
    iconFa "comments" condition "Port module"


notExposedIcon : Bool -> Html Msg
notExposedIcon condition =
    iconFa "eye-slash" condition "Not exposed"


nativeIcon : Bool -> Html Msg
nativeIcon condition =
    iconMfizz "javascript-alt" condition "Native (JS)"


effectIcon : Bool -> Html Msg
effectIcon condition =
    iconFa "rocket" condition "Effect manager"


filterIcon : FilterType -> String
filterIcon filterType =
    case filterType of
        UserPackages ->
            "icon-user"

        DirectDeps ->
            "icon-flow-line"

        DepsOfDeps ->
            "icon-flow-tree"

        ExposedModules ->
            "icon-eye"

        EffectModules ->
            "icon--fa fa-rocket"

        NativeModules ->
            "icon--mfizz icon-javascript-alt"

        PortModules ->
            "icon--fa fa-comments"

        ExposedDefinitions ->
            "icon-eye"
