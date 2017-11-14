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
        , footer model
        ]


content : Model -> Html Msg
content model =
    H.div [ HA.class "window-content" ]
        [ maybeTable model.project
        ]


footer : Model -> Html Msg
footer model =
    H.footer [ HA.class "toolbar toolbar-footer" ]
        [ H.h1 [ HA.class "title footer__progress" ]
            [ iconForCurrentState model
            , H.text "Maybe we're indexing, maybe not! TODO!"
            ]
        ]


iconForCurrentState : Model -> Html Msg
iconForCurrentState model =
    -- or allOk
    spinner


spinner : Html Msg
spinner =
    H.span [ HA.class "icon footer__icon spinner" ] []


allOk : Html Msg
allOk =
    H.span [ HA.class "icon footer__icon icon-check" ] []


maybeTable : Maybe Project -> Html Msg
maybeTable maybeProject =
    maybeProject
        |> Maybe.map table
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


table : Project -> Html Msg
table project =
    project.index
        |> Maybe.map (tableWithContent project.selection)
        -- TODO ↓ progressbar for the indexing? or at least tell the user that we are indexing!
        |> Maybe.withDefault (tableWithContent NothingSelected [])


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
        (moduleIdentifier module_)


definitions : Index -> Selection -> Html Msg
definitions index selection =
    -- TODO constructors of `type Msg = ...` as entries!!
    index
        |> List.concatMap .modules
        |> List.concatMap
            (\module_ ->
                module_.definitions
                    |> List.map (\definition -> ( module_.name, definition ))
            )
        |> List.map (\( moduleName, def ) -> definition selection moduleName def)
        |> innerTable


definition : Selection -> ModuleName -> Definition -> Html Msg
definition selection moduleName definition =
    row
        (Selection.isDefinitionSelected moduleName definition selection)
        (definitionIdentifier definition)


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
                [ ( "row", True )
                , ( "row--active", isSelected )
                ]
            ]
            [ content ]
        ]


packageIdentifier : Package -> Html Msg
packageIdentifier { author, name, version, isUserPackage } =
    -- TODO package with native modules icon
    -- TODO package with effect managers icon
    let
        divider str =
            H.span
                [ HA.class "package__identifier__divider" ]
                [ H.text str ]
    in
        H.div [ HA.class "package__identifier" ]
            [ H.span [ HA.class "package__identifier__content" ]
                [ H.text author
                , divider "/"
                , H.text name
                , if isUserPackage then
                    icon "user"
                  else
                    H.text ""
                ]
            , H.span [ HA.class "package__identifier__version" ]
                [ divider "@"
                , H.text version
                ]
            ]


moduleIdentifier : Module -> Html Msg
moduleIdentifier { name, isExposed } =
    -- TODO native module icon
    -- TODO effect manager icon
    H.span []
        [ H.text name
        , if isExposed then
            H.text ""
          else
            icon "mute"
        ]


definitionIdentifier : Definition -> Html Msg
definitionIdentifier { name, isExposed } =
    H.span []
        [ H.text name
        , if isExposed then
            H.text ""
          else
            icon "mute"
        ]


icon : String -> Html Msg
icon type_ =
    -- TODO yes, yes, I know, @krisajenkins...
    H.span [ HA.class <| "row__icon icon icon-" ++ type_ ] []
