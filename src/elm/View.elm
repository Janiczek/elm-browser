module View exposing (view)

import Html as H exposing (Html)
import Html.Attributes as HA
import Html.Events as HE
import Index
import Selection
import Types exposing (..)
import View.Column exposing (..)
import View.Footer exposing (..)
import View.SourceCode exposing (..)


view : Model -> Html Msg
view model =
    H.div [ HA.class "window" ]
        [ content model
        , footer model
        ]


content : Model -> Html Msg
content model =
    H.div [ HA.class "window-content" ]
        [ maybeTable model.project
        ]


maybeTable : Maybe Project -> Html Msg
maybeTable maybeProject =
    maybeProject
        |> Maybe.map project
        |> Maybe.withDefault noProject


empty : String -> Html Msg
empty message =
    H.div
        [ HA.class "empty-dialog" ]
        [ H.img
            [ HA.src "../resources/tangram_bw.png"
            , HA.alt "Elm tangram logo"
            , HA.class "elm-logo"
            ]
            []
        , H.div
            [ HA.class "empty-dialog__message" ]
            [ H.text message ]
        , H.button
            [ HE.onClick AskForProject
            , HA.class "btn btn-large btn-default"
            ]
            [ H.text "Open project" ]
        ]


noProject : Html Msg
noProject =
    empty "No project open"


project : Project -> Html Msg
project project =
    project.index
        |> Maybe.map (\index -> projectWithContent project.selection index)
        |> Maybe.withDefault (projectWithContent Selection.empty Index.empty)


projectWithContent : Selection -> Index -> Html Msg
projectWithContent selection index =
    H.div
        [ HA.class "main-table" ]
        [ columns selection index
        , sourceCode selection index
        ]
