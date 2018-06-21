module View.SourceCode exposing (sourceCode)

import Editor
import EveryDict as EDict exposing (EveryDict)
import Html as H exposing (Html)
import Html.Attributes as HA
import Html.Events as HE
import Selection
import Types exposing (..)


sourceCode : Editor.Model -> Selection -> EveryDict DefinitionId SourceCode -> Html Msg
sourceCode editor selection changes =
    let
        selectedId : Maybe DefinitionId
        selectedId =
            Selection.selectedDefinitionId selection

        changedCode : Maybe SourceCode
        changedCode =
            selectedId
                |> Maybe.andThen (\id -> EDict.get id changes)

        config : Editor.Config
        config =
            { isDisabled = selectedId == Nothing }
    in
    H.div
        [ HA.class "bottom-table" ]
        [ Editor.view config editor
            |> H.map EditorMsg
        , Maybe.map2
            (\newCode id ->
                H.button
                    [ HE.onClick (SaveChange id newCode) ]
                    [ H.text "Save" ]
            )
            changedCode
            selectedId
            |> Maybe.withDefault (H.text "")
        ]
