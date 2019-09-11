module View exposing (view)

import AssocList as Dict exposing (Dict)
import Browser
import Editor
import FilterConfig
import Html as H exposing (Html)
import Html.Attributes as HA
import Html.Events as HE
import Index
import Types exposing (..)
import View.Column exposing (..)
import View.Footer exposing (..)
import View.SourceCode exposing (..)


view : Model -> Browser.Document Msg
view model =
    { title = "elm-browser"
    , body =
        [ H.div [ HA.class "window" ]
            [ content model
            , footer model
            ]
        ]
    }


content : Model -> Html Msg
content model =
    H.div [ HA.class "window-content" ]
        [ if model.isCompiling then
            empty "Compiling"

          else
            maybeTable model.columnTitles model.editor model.project
        ]


maybeTable : ColumnTitles -> Editor.Model -> Maybe Project -> Html Msg
maybeTable columnTitles editor maybeProject =
    maybeProject
        |> Maybe.map (project columnTitles editor)
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
            [ HE.onClick CreateProjectPressed
            , HA.class "btn btn-large btn-default button--create-new-project"
            ]
            [ H.text "Create new project" ]
        , H.button
            [ HE.onClick OpenProjectPressed
            , HA.class "btn btn-large btn-default button--open-project"
            ]
            [ H.text "Open a project" ]
        ]


noProject : Html Msg
noProject =
    empty "No project open"


project : ColumnTitles -> Editor.Model -> Project -> Html Msg
project columnTitles editor project_ =
    project_.index
        |> Maybe.map (\index -> projectWithContent columnTitles editor project_.selection index project_.filterConfig project_.changes)
        |> Maybe.withDefault (projectWithContent columnTitles editor NothingSelected Index.empty FilterConfig.empty Dict.empty)


projectWithContent :
    ColumnTitles
    -> Editor.Model
    -> Selection
    -> Index
    -> FilterConfig
    -> Dict DefinitionId SourceCode
    -> Html Msg
projectWithContent columnTitles editor selection index filterConfig changes =
    H.div
        [ HA.class "main-table" ]
        [ columns columnTitles selection index filterConfig changes
        , sourceCode editor selection changes
        ]
