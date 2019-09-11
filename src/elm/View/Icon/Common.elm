module View.Icon.Common exposing (icon, iconFa, iconMfizz)

import Html as H exposing (Html)
import Html.Attributes as HA
import Html.Events as HE
import Types exposing (..)


icon : String -> Bool -> String -> Html Msg
icon type_ condition tooltip =
    genericIcon "icon-" type_ condition tooltip


iconFa : String -> Bool -> String -> Html Msg
iconFa type_ condition tooltip =
    genericIcon "icon--fa fa-" type_ condition tooltip


iconMfizz : String -> Bool -> String -> Html Msg
iconMfizz type_ condition tooltip =
    genericIcon "icon--mfizz icon-" type_ condition tooltip


genericIcon : String -> String -> Bool -> String -> Html Msg
genericIcon classPrefix type_ condition tooltip =
    -- TODO yes, yes, String icons, I know, @krisajenkins...
    if condition then
        let
            iconString =
                "icon " ++ classPrefix ++ type_
        in
        H.span
            [ HA.class <| "row__icon " ++ iconString
            , HE.onMouseEnter (ShowFooterMsg ( H.span [ HA.class <| "footer__icon " ++ iconString ] [], tooltip ))
            , HE.onMouseLeave HideFooterMsg
            ]
            []

    else
        H.text ""
