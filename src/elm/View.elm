module View exposing (view)

import Html as H exposing (Html)
import Html.Attributes as HA
import Html.Events as HE
import Types exposing (..)


view : Model -> Html Msg
view model =
    H.div [ HA.class "window" ]
        [ content model
        ]


content : Model -> Html Msg
content model =
    H.div [ HA.class "window-content" ]
        [ maybePanes model.project
        ]


maybePanes : Maybe Project -> Html Msg
maybePanes maybeProject =
    maybeProject
        |> Maybe.map panes
        |> Maybe.withDefault noProject


noProject : Html Msg
noProject =
    H.div
        [ HA.style
            [ ( "display", "flex" )
            , ( "flex", "1" )
            , ( "justify-content", "center" )
            , ( "align-items", "center" )
            , ( "flex-direction", "column" )
            ]
        ]
        [ H.div
            [ HA.style
                [ ( "color", "#aaa" )
                , ( "font-size", "24px" )
                , ( "margin-bottom", "16px" )
                ]
            ]
            [ H.text "No project open" ]
        , H.button
            [ HE.onClick AskForProject
            , HA.class "btn btn-default"
            ]
            [ H.text "Open project" ]
        ]


panes : Project -> Html Msg
panes project =
    H.div [ HA.class "pane-group" ]
        [ H.div [ HA.class "pane" ] [ H.text "Packages" ]
        , H.div [ HA.class "pane" ] [ H.text "Modules" ]
        , H.div [ HA.class "pane" ] [ H.text "Definitions" ]
        ]
