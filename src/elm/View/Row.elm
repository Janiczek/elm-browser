module View.Row exposing (package, module_, definition)

import Html as H exposing (Html)
import Html.Attributes as HA
import Html.Events as HE
import Selection
import Types exposing (..)
import View.Icon exposing (..)


package : Selection -> PackageOnlyId -> Package -> Html Msg
package selection packageId package =
    row
        (PackageId packageId)
        (Selection.isPackageSelected selection package)
        (packageRow package)


module_ : Selection -> ModuleOnlyId -> Module -> Html Msg
module_ selection moduleId module_ =
    row
        (ModuleId moduleId)
        (Selection.isModuleSelected selection module_)
        (moduleRow module_)


definition : Selection -> DefinitionOnlyId -> Definition -> Html Msg
definition selection definitionId definition =
    row
        (DefinitionId definitionId)
        (Selection.isDefinitionSelected definitionId definition selection)
        (definitionRow definition)


packageRow : Package -> Html Msg
packageRow { author, name, version, dependencyType, containsNativeModules, containsEffectModules } =
    H.div
        [ HA.class "identifier" ]
        [ H.span
            [ HA.classList
                [ ( "identifier__content", True )
                , ( "identifier__content--user-package", dependencyType == UserPackage )
                , ( "identifier__content--dep-of-dep", dependencyType == DependencyOfDependency )
                ]
            ]
            [ H.text author
            , divider "/"
            , H.text name
            ]
        , H.span
            [ HA.class "identifier__metadata" ]
            [ nativeIcon containsNativeModules
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


row : Id -> Bool -> Html Msg -> Html Msg
row identifier isSelected content =
    -- TODO Ctrl+click for multiple select (and deselect) ... SelectAnother
    -- TODO Shift+click for range select
    H.tr
        [ HE.onClick
            (if isSelected then
                Deselect identifier
             else
                SelectOne identifier
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
