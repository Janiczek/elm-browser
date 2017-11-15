module View.Row exposing (package, module_, definition)

import Html as H exposing (Html)
import Html.Attributes as HA
import Html.Events as HE
import Selection
import Types exposing (..)
import View.Icon exposing (..)


package : Selection -> Package -> Html Msg
package selection package =
    row
        PackageColumn
        (Selection.packageIdentifier package)
        (Selection.isPackageSelected selection package)
        (packageRow package)


module_ : Selection -> Module -> Html Msg
module_ selection module_ =
    row
        ModuleColumn
        module_.name
        (Selection.isModuleSelected selection module_)
        (moduleRow module_)


definition : Selection -> ModuleName -> Definition -> Html Msg
definition selection moduleName definition =
    row
        DefinitionColumn
        (Selection.definitionIdentifier moduleName definition)
        (Selection.isDefinitionSelected moduleName definition selection)
        (definitionRow definition)


packageRow : Package -> Html Msg
packageRow { author, name, version, isUserPackage, containsNativeModules, containsEffectModules } =
    H.div
        [ HA.class "identifier" ]
        [ H.span
            [ HA.class "identifier__content" ]
            [ H.text author
            , divider "/"
            , H.text name
            ]
        , H.span
            [ HA.class "identifier__metadata" ]
            [ userPackageIcon isUserPackage
            , nativeIcon containsNativeModules
            , effectIcon containsEffectModules
            , divider "@"
            , H.text version
            ]
        ]


divider : String -> Html Msg
divider str =
    H.span
        [ HA.class "identifier__divider" ]
        [ H.text str ]


moduleRow : Module -> Html Msg
moduleRow { name, isExposed, isNative, isEffect, isPort } =
    H.div
        [ HA.class "identifier" ]
        [ H.span
            [ HA.class "identifier__content" ]
            [ H.text name ]
        , H.span
            [ HA.class "identifier__metadata" ]
            [ notExposedIcon (not isExposed)
            , nativeIcon isNative
            , effectIcon isEffect
            , portModuleIcon isPort
            ]
        ]


definitionRow : CommonDefinition a -> Html Msg
definitionRow { name, isExposed } =
    H.div
        [ HA.class "identifier" ]
        [ H.span
            [ HA.class "identifier__content" ]
            [ H.text name ]
        , H.span
            [ HA.class "identifier__metadata" ]
            [ notExposedIcon (not isExposed) ]
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
