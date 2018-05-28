module View.Row exposing (definition, module_, package)

import Html as H exposing (Html)
import Html.Attributes as HA
import Html.Events as HE
import Selection
import Types exposing (..)
import View.Icon exposing (..)


package : Selection -> PackageId -> Package -> Html Msg
package selection packageId package =
    row
        packageId
        SelectPackage
        DeselectPackage
        (Selection.isPackageSelected packageId selection)
        (packageRow package)


module_ : Selection -> ModuleId -> Module -> Html Msg
module_ selection moduleId module_ =
    row
        moduleId
        SelectModule
        DeselectModule
        (Selection.isModuleSelected moduleId selection)
        (moduleRow module_)


definition : Selection -> DefinitionId -> Definition -> Html Msg
definition selection definitionId definition =
    row
        definitionId
        SelectDefinition
        DeselectDefinition
        (Selection.isDefinitionSelected definitionId selection)
        (definitionRow definition)


packageRow : Package -> Html Msg
packageRow { name, version, dependencyType, containsNativeModules, containsEffectModules } =
    H.div
        [ HA.class "identifier" ]
        [ H.span
            [ HA.classList
                [ ( "identifier__content", True )
                , ( "identifier__content--user-package", dependencyType == UserPackage )
                , ( "identifier__content--dep-of-dep", dependencyType == DependencyOfDependency )
                ]
            ]
            [ H.text name ]
        , H.span
            [ HA.class "identifier__metadata" ]
            ([ nativeIcon containsNativeModules
             , effectIcon containsEffectModules
             ]
                ++ (version
                        |> Maybe.map
                            (\v ->
                                [ divider "@"
                                , H.text v
                                ]
                            )
                        |> Maybe.withDefault []
                   )
            )
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


row : id -> (id -> Msg) -> Msg -> Bool -> Html Msg -> Html Msg
row id selectMsg deselectMsg isSelected content =
    H.tr
        [ HE.onClick
            (if isSelected then
                deselectMsg
             else
                selectMsg id
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
