module View exposing (view)

import Editor
import EveryDict as EDict exposing (EveryDict)
import FilterConfig
import Html as H exposing (Html)
import Html.Attributes as HA
import Html.Events as HE
import Index
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
project columnTitles editor project =
    project.index
        |> Maybe.map (\index -> projectWithContent columnTitles editor project.selection index project.filterConfig project.changes)
        |> Maybe.withDefault (projectWithContent columnTitles editor NothingSelected Index.empty FilterConfig.empty EDict.empty)


projectWithContent :
    ColumnTitles
    -> Editor.Model
    -> Selection
    -> Index
    -> FilterConfig
    -> EveryDict DefinitionId SourceCode
    -> Html Msg
projectWithContent columnTitles editor selection index filterConfig changes =
    H.div
        [ HA.class "main-table" ]
        [ columns columnTitles selection index filterConfig changes
        , sourceCode editor selection changes
        ]
