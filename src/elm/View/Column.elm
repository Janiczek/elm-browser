module View.Column exposing (..)

import EveryDict as EDict exposing (EveryDict)
import EverySet as ESet
import Html as H exposing (Html)
import Html.Attributes as HA
import Html.Events as HE
import Index
import Selection
import Types exposing (..)
import Utils
import View.Footer as Footer
import View.Icon as Icon
import View.Row as Row


columns : Selection -> Index -> FilterConfig -> EveryDict DefinitionId SourceCode -> Html Msg
columns selection index filterConfig changes =
    H.div
        [ HA.class "top-table" ]
        [ H.div
            [ HA.class "top-table__headings" ]
            [ packagesHeader filterConfig.packages
            , modulesHeader filterConfig.modules
            , definitionsHeader filterConfig.definitions
            ]
        , H.div [ HA.class "top-table__content" ]
            [ packagesColumn index selection filterConfig.packages
            , modulesColumn index selection filterConfig.modules
            , definitionsColumn index selection filterConfig.definitions changes
            ]
        ]


filterButton : FilterType -> Bool -> Html Msg
filterButton filterType isActive =
    let
        filterIcon =
            Icon.filterIcon filterType
    in
    H.button
        [ HA.classList
            [ ( "filter__button", True )
            , ( "btn", True )
            , ( "btn-mini", True )
            , ( "btn-default", True )
            , ( "active", isActive )
            ]
        , HE.onMouseEnter
            (ShowFooterMsg
                ( H.span [ HA.class <| "footer__icon icon " ++ filterIcon ] []
                , Footer.filterTooltip filterType
                )
            )
        , HE.onMouseLeave HideFooterMsg
        , HE.onClick (SetFilter filterType (not isActive))
        ]
        [ H.span [ HA.class <| "icon " ++ filterIcon ] [] ]


packages : Index -> PackagesFilterConfig -> List ( PackageId, Package )
packages index { user, directDeps, depsOfDeps } =
    let
        showAll =
            not (user || directDeps || depsOfDeps)
    in
    index.packages
        |> EDict.toList
        |> List.filter
            (\( _, { dependencyType } ) ->
                showAll
                    || (case dependencyType of
                            UserPackage ->
                                user

                            DirectDependency ->
                                directDeps || showAll

                            DependencyOfDependency ->
                                depsOfDeps
                       )
            )
        |> List.sortBy
            (\( PackageId id, { dependencyType } ) ->
                ( case dependencyType of
                    UserPackage ->
                        1

                    DirectDependency ->
                        2

                    DependencyOfDependency ->
                        3
                , id
                )
            )


packagesHeader : PackagesFilterConfig -> Html Msg
packagesHeader { user, directDeps, depsOfDeps } =
    H.div
        [ HA.class "top-table__heading" ]
        [ H.span
            [ HA.class "top-table__heading__label" ]
            [ H.text "Packages"
            ]
        , H.div
            [ HA.class "top-table__heading__filters btn-group" ]
            [ filterButton UserPackages user
            , filterButton DirectDeps directDeps
            , filterButton DepsOfDeps depsOfDeps
            ]
        ]


modulesHeader : ModulesFilterConfig -> Html Msg
modulesHeader { exposed, effect, native, port_ } =
    H.div
        [ HA.class "top-table__heading" ]
        [ H.span
            [ HA.class "top-table__heading__label" ]
            [ H.text "Modules"
            ]
        , H.div
            [ HA.class "top-table__heading__filters btn-group" ]
            [ filterButton ExposedModules exposed
            , filterButton EffectModules effect
            , filterButton NativeModules native
            , filterButton PortModules port_
            ]
        ]


definitionsHeader : DefinitionsFilterConfig -> Html Msg
definitionsHeader { exposed } =
    H.div
        [ HA.class "top-table__heading" ]
        [ H.span
            [ HA.class "top-table__heading__label" ]
            [ H.text "Definitions"
            ]
        , H.div
            [ HA.class "top-table__heading__filters btn-group" ]
            [ filterButton ExposedDefinitions exposed ]
        ]


packagesColumn : Index -> Selection -> PackagesFilterConfig -> Html Msg
packagesColumn index selection packagesFilterConfig =
    packages index packagesFilterConfig
        |> List.map (\( packageId, package ) -> Row.package selection packageId package)
        |> innerTable


modules : Index -> Selection -> ModulesFilterConfig -> List ( ModuleId, Module )
modules index selection { exposed, effect, native, port_ } =
    let
        showAll =
            not (exposed || effect || native || port_)
    in
    (case packagesForModulesColumn index selection of
        AllPackages ->
            index.packages |> Utils.dictKeysToSet

        SelectedPackages ->
            selection
                |> Selection.selectedPackageId
                |> Maybe.map ESet.singleton
                |> Maybe.withDefault ESet.empty
    )
        |> flip Selection.modulesForPackages index
        |> Utils.dictGetKv index.modules
        |> List.filter
            (\( _, module_ ) ->
                showAll
                    || List.all (\f -> f module_)
                        [ \{ isExposed } ->
                            if exposed then
                                isExposed
                            else
                                True
                        , \{ isEffect } ->
                            if effect then
                                isEffect
                            else
                                True
                        , \{ isNative } ->
                            if native then
                                isNative
                            else
                                True
                        , \{ isPort } ->
                            if port_ then
                                isPort
                            else
                                True
                        ]
            )
        |> List.sortBy (\( ModuleId id, _ ) -> id)


modulesColumn : Index -> Selection -> ModulesFilterConfig -> Html Msg
modulesColumn index selection modulesFilterConfig =
    modules index selection modulesFilterConfig
        |> List.map (\( moduleId, module_ ) -> Row.module_ selection moduleId module_)
        |> innerTable


definitionsColumn : Index -> Selection -> DefinitionsFilterConfig -> EveryDict DefinitionId SourceCode -> Html Msg
definitionsColumn index selection definitionsFilterConfig changes =
    Index.shownDefinitions index selection definitionsFilterConfig
        |> List.map (\( definitionId, definition ) -> Row.definition selection changes definitionId definition)
        |> innerTable


type PackagesToShowModulesFrom
    = AllPackages
    | SelectedPackages


packagesForModulesColumn : Index -> Selection -> PackagesToShowModulesFrom
packagesForModulesColumn index selection =
    if Selection.selectedPackageId selection == Nothing then
        AllPackages
    else
        SelectedPackages


innerTable : List (Html Msg) -> Html Msg
innerTable elements =
    H.div
        [ HA.class "inner-table" ]
        [ H.table
            [ HA.class "table-striped" ]
            [ H.tbody [] elements ]
        ]
