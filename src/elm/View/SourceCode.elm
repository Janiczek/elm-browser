module View.SourceCode exposing (sourceCode)

import Html as H exposing (Html)
import Html.Attributes as HA
import Html.Events as HE
import Index
import Json.Decode as JD exposing (Decoder)
import Types exposing (..)


sourceCode : Selection -> Index -> Html Msg
sourceCode selection index =
    let
        sourceCode =
            index
                |> Index.sourceCode selection
                |> Maybe.withDefault ""

        language =
            index
                |> Index.language selection
                |> Maybe.withDefault Elm
                |> languageToMode
    in
        H.div
            [ HA.class "bottom-table" ]
            [ H.node "ace-widget"
                [ HE.on "editor-content" (JD.succeed EditorChanged)
                , HA.attribute "value" sourceCode
                , HA.attribute "mode" language
                ]
                []
            ]


languageToMode : Language -> String
languageToMode language =
    "ace/mode/"
        ++ case language of
            Elm ->
                "elm"

            JavaScript ->
                "javascript"
