module View.Column exposing (columns)

import Html as H exposing (Html)
import Html.Attributes as HA
import Index
import Selection
import Types exposing (..)
import View.Row as Row


columns : Selection -> Index -> Html Msg
columns selection index =
    H.div
        [ HA.class "top-table" ]
        [ H.div
            [ HA.class "top-table__headings" ]
            [ H.div [ HA.class "top-table__heading" ] [ H.text "Packages" ]
            , H.div [ HA.class "top-table__heading" ] [ H.text "Modules" ]
            , H.div [ HA.class "top-table__heading" ] [ H.text "Definitions" ]
            ]
        , H.div [ HA.class "top-table__content" ]
            [ packages index selection
            , modules index selection
            , definitions index selection
            ]
        ]


packages : Index -> Selection -> Html Msg
packages index selection =
    index
        |> List.map (Row.package selection)
        |> innerTable


modules : Index -> Selection -> Html Msg
modules index selection =
    (if List.isEmpty selection.packages then
        index
     else
        index
            |> List.filter (Selection.isPackageSelected selection)
    )
        |> List.concatMap .modules
        |> List.map (Row.module_ selection)
        |> innerTable


definitions : Index -> Selection -> Html Msg
definitions index selection =
    (if
        let
            modules =
                Selection.modulesForPackages selection.packages index
        in
            selection.modules
                |> List.filter (\module_ -> modules |> List.member module_)
                |> List.isEmpty
     then
        []
     else
        index
            |> List.concatMap .modules
            |> List.filter (Selection.isModuleSelected selection)
    )
        |> Index.definitionsWithModuleName
        |> List.map (\( moduleName, def ) -> Row.definition selection moduleName def)
        |> innerTable


innerTable : List (Html Msg) -> Html Msg
innerTable elements =
    H.div [ HA.class "inner-table" ]
        [ H.table
            [ HA.class "table-striped" ]
            [ H.tbody [] elements ]
        ]
