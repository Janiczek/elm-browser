module View.Footer exposing (footer, filterTooltip)

import Html as H exposing (Html)
import Html.Attributes as HA
import Types exposing (..)


footer : Model -> Html Msg
footer model =
    H.footer [ HA.class "toolbar toolbar-footer" ]
        [ H.h1 [ HA.class "title footer__progress" ]
            (footerMessage model)
        ]


footerMessage : Model -> List (Html Msg)
footerMessage model =
    let
        ok =
            [ allOk, H.text "Ready." ]

        defaultFooterMsg =
            if model.project == Nothing then
                ok
            else
                model.project
                    |> Maybe.andThen .index
                    |> Maybe.map (\_ -> ok)
                    |> Maybe.withDefault [ spinner, H.text "Indexing your project" ]
    in
        model.footerMsg
            |> Maybe.map (\( icon, msg ) -> [ icon, H.text msg ])
            |> Maybe.withDefault defaultFooterMsg


spinner : Html Msg
spinner =
    H.span [ HA.class "icon footer__icon spinner" ] []


allOk : Html Msg
allOk =
    H.span [ HA.class "icon footer__icon icon-check" ] []


filterTooltip : FilterType -> String
filterTooltip filterType =
    case filterType of
        UserPackages ->
            "User packages"

        DirectDeps ->
            "Direct dependencies of user packages"

        DepsOfDeps ->
            "Dependencies of dependencies"

        ExposedModules ->
            "Exposed modules"

        EffectModules ->
            "Effect modules"

        NativeModules ->
            "Native modules"

        PortModules ->
            "Port modules"

        ExposedDefinitions ->
            "Exposed definitions"
