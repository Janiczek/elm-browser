module View exposing (view)

import Html as H exposing (Html)
import Html.Attributes as HA
import Html.Events as HE
import Selection
import Types exposing (..)


view : Model -> Html Msg
view model =
    H.div [ HA.class "window" ]
        [ content model
        ]


content : Model -> Html Msg
content model =
    H.div [ HA.class "window-content" ]
        [ maybeTable model.project
        ]


maybeTable : Maybe Project -> Html Msg
maybeTable maybeProject =
    maybeProject
        |> Maybe.map table
        |> Maybe.withDefault noProject


empty : String -> Html Msg
empty message =
    H.div
        [ HA.class "empty-dialog" ]
        [ H.div
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


table : Project -> Html Msg
table project =
    project.index
        |> Maybe.map (tableWithContent project.selection)
        |> Maybe.withDefault emptyTable


tableWithContent : Selection -> Index -> Html Msg
tableWithContent selection index =
    H.div [ HA.class "top-table" ]
        [ H.div [ HA.class "top-table__headings" ]
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


emptyTable : Html Msg
emptyTable =
    -- TODO test! didn't see this one yet.
    empty "No suitable files found"


packages : Index -> Selection -> Html Msg
packages index selection =
    index
        |> List.map (package selection)
        |> innerTable


package : Selection -> Package -> Html Msg
package selection package =
    row
        (Selection.isPackageSelected package selection)
        (packageIdentifier package)


modules : Index -> Selection -> Html Msg
modules index selection =
    index
        |> List.concatMap .modules
        |> List.map (module_ selection)
        |> innerTable


module_ : Selection -> Module -> Html Msg
module_ selection module_ =
    row
        (Selection.isModuleSelected module_ selection)
        (H.text module_.name)


definitions : Index -> Selection -> Html Msg
definitions index selection =
    -- TODO actual data
    index
        |> List.concatMap .modules
        |> List.concatMap .definitions
        |> List.map (definition selection)
        |> innerTable


definition : Selection -> Definition -> Html Msg
definition selection definition =
    row
        (Selection.isDefinitionSelected definition selection)
        (H.text definition)


innerTable : List (Html Msg) -> Html Msg
innerTable elements =
    H.div [ HA.class "inner-table" ]
        [ H.table
            [ HA.class "table-striped" ]
            [ H.tbody [] elements ]
        ]


row : Bool -> Html Msg -> Html Msg
row isSelected content =
    H.tr []
        [ H.td
            [ HA.classList
                -- TODO css
                [ ( "row", True )
                , ( "row--active", isSelected )
                ]
            ]
            [ content ]
        ]


packageIdentifier : Package -> Html Msg
packageIdentifier { author, name, version, isUserPackage } =
    let
        divider str =
            H.span
                [ HA.class "package__identifier__divider" ]
                [ H.text str ]
    in
        H.span []
            [ H.text author
            , divider "/"
            , H.text name
            , divider "@"
            , H.text version
            , if isUserPackage then
                H.span [ HA.class "row__icon icon icon-user" ] []
              else
                H.text ""
            ]
