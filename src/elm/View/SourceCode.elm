module View.SourceCode exposing (sourceCode)

import Editor
import Html as H exposing (Html)
import Html.Attributes as HA
import Types exposing (..)


sourceCode : Editor.Model -> Html Msg
sourceCode editor =
    H.div
        [ HA.class "bottom-table" ]
        [ Editor.view editor
            |> H.map EditorMsg
        ]
