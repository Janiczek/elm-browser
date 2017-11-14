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
            (footerMessage model)
        ]


footerMessage : Model -> List (Html Msg)
footerMessage model =
    let
        ok =
            [ allOk, H.text "Ready." ]
    in
        if model.project == Nothing then
            ok
        else
            model.project
                |> Maybe.andThen .index
                |> Maybe.map (\_ -> ok)
                |> Maybe.withDefault [ spinner, H.text "Indexing your project" ]


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
        |> Maybe.withDefault (tableWithContent (Selection [] [] []) [])


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
        PackageColumn
        (Selection.packageIdentifier package)
        (Selection.isPackageSelected package selection)
        (packageIdentifier package)


modules : Index -> Selection -> Html Msg
modules index selection =
    (if List.isEmpty selection.packages then
        index
     else
        index
            |> List.filter (isInSelectedPackages selection)
    )
        |> List.concatMap .modules
        |> List.map (module_ selection)
        |> innerTable


module_ : Selection -> Module -> Html Msg
module_ selection module_ =
    row
        ModuleColumn
        module_.name
        (Selection.isModuleSelected module_ selection)
        (moduleIdentifier module_)


isInSelectedPackages : Selection -> Package -> Bool
isInSelectedPackages selection package =
    selection.packages
        |> List.member (Selection.packageIdentifier package)


definitions : Index -> Selection -> Html Msg
definitions index selection =
    (if List.isEmpty selection.modules then
        []
     else
        index
            |> List.concatMap .modules
            |> List.filter (isInSelectedModules selection)
    )
        |> List.concatMap
            (\module_ ->
                module_.definitions
                    |> List.map (\definition -> ( module_.name, definition ))
            )
        |> List.concatMap (\( moduleName, def ) -> definition selection moduleName def)
        |> innerTable


isInSelectedModules : Selection -> Module -> Bool
isInSelectedModules selection module_ =
    selection.modules
        |> List.member module_.name


definition : Selection -> ModuleName -> Definition -> List (Html Msg)
definition selection moduleName definition =
    case definition.kind of
        Type { constructors } ->
            let
                typeRow =
                    row
                        DefinitionColumn
                        (Selection.definitionIdentifier moduleName definition)
                        (Selection.isDefinitionSelected moduleName definition selection)
                        (definitionIdentifier definition)

                constructorRows =
                    constructors
                        |> List.map
                            (\constructor ->
                                row
                                    DefinitionColumn
                                    (Selection.definitionIdentifier moduleName constructor)
                                    (Selection.isDefinitionSelected moduleName constructor selection)
                                    (definitionIdentifier constructor)
                            )
            in
                typeRow :: constructorRows

        _ ->
            [ row
                DefinitionColumn
                (Selection.definitionIdentifier moduleName definition)
                (Selection.isDefinitionSelected moduleName definition selection)
                (definitionIdentifier definition)
            ]


innerTable : List (Html Msg) -> Html Msg
innerTable elements =
    H.div [ HA.class "inner-table" ]
        [ H.table
            [ HA.class "table-striped" ]
            [ H.tbody [] elements ]
        ]


row : Column -> Identifier -> Bool -> Html Msg -> Html Msg
row column identifier isSelected content =
    -- TODO Ctrl+click for multiple select (and deselect) ... SelectAnother
    -- TODO Shift+click for range select
    H.tr
        [ HE.onClick
            (if isSelected then
                Deselect column identifier
             else
                SelectOne column identifier
            )
        ]
        [ H.td
            [ HA.classList
                [ ( "row", True )
                , ( "row--active", isSelected )
                ]
            ]
            [ content ]
        ]


packageIdentifier : Package -> Html Msg
packageIdentifier { author, name, version, isUserPackage, containsNativeModules, containsEffectModules } =
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
                , userPackageIcon isUserPackage
                , nativeIcon containsNativeModules
                , effectIcon containsEffectModules
                ]
            , H.span [ HA.class "package__identifier__version" ]
                [ divider "@"
                , H.text version
                ]
            ]


moduleIdentifier : Module -> Html Msg
moduleIdentifier { name, isExposed, isNative, isEffect, isPort } =
    H.span []
        [ H.text name
        , notExposedIcon (not isExposed)
        , nativeIcon isNative
        , effectIcon isEffect
        , portModuleIcon isPort
        ]


definitionIdentifier : CommonDefinition a -> Html Msg
definitionIdentifier { name, isExposed } =
    H.span []
        [ H.text name
        , notExposedIcon (not isExposed)
        ]


userPackageIcon : Bool -> Html Msg
userPackageIcon condition =
    icon "user" condition "User package"


portModuleIcon : Bool -> Html Msg
portModuleIcon condition =
    iconFa "comments" condition "Port module"


notExposedIcon : Bool -> Html Msg
notExposedIcon condition =
    iconFa "eye-slash" condition "Not exposed"


nativeIcon : Bool -> Html Msg
nativeIcon condition =
    iconMfizz "javascript-alt" condition "Native (JS)"


effectIcon : Bool -> Html Msg
effectIcon condition =
    iconFa "rocket" condition "Effect manager"


icon : String -> Bool -> String -> Html Msg
icon type_ condition tooltip =
    -- TODO yes, yes, String icons, I know, @krisajenkins...
    if condition then
        H.span
            [ HA.attribute "data-balloon" tooltip
            , HA.attribute "data-balloon-pos" "down"
            ]
            [ H.span [ HA.class <| "row__icon icon icon-" ++ type_ ] [] ]
    else
        nothing


iconFa : String -> Bool -> String -> Html Msg
iconFa type_ condition tooltip =
    if condition then
        H.span
            [ HA.attribute "data-balloon" tooltip
            , HA.attribute "data-balloon-pos" "down"
            ]
            [ H.span [ HA.class <| "row__icon icon icon--fa fa-" ++ type_ ] [] ]
    else
        nothing


iconMfizz : String -> Bool -> String -> Html Msg
iconMfizz type_ condition tooltip =
    if condition then
        H.span
            [ HA.attribute "data-balloon" tooltip
            , HA.attribute "data-balloon-pos" "down"
            ]
            [ H.span [ HA.class <| "row__icon icon icon--mfizz icon-" ++ type_ ] [] ]
    else
        nothing


nothing : Html Msg
nothing =
    H.text ""
