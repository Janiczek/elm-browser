module View.Icon exposing (..)

import Html exposing (Html)
import Types exposing (..)
import View.Icon.Common exposing (..)


userPackageIcon : Bool -> Html Msg
userPackageIcon condition =
    icon "user" condition "User package"


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
