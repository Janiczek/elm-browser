module View.Column exposing (..)

import AssocList as Dict exposing (Dict)
import AssocSet as Set exposing (Set)
import Html as H exposing (Html)
import Html.Attributes as HA
import Html.Events as HE
import Index
import Selection
import Types exposing (..)
import Utils
import View.Icon as Icon
import View.Row as Row


columns : ColumnTitles -> Selection -> Index -> FilterConfig -> Dict DefinitionId SourceCode -> Html Msg
columns columnTitles selection index filterConfig changes =
    H.div
        [ HA.class "top-table" ]
        [ H.div
            [ HA.class "top-table__headings" ]
            [ packagesHeader columnTitles.packages filterConfig.packages
            , modulesHeader columnTitles.modules filterConfig.modules
            , definitionsHeader columnTitles.definitions filterConfig.definitions
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

        column : Column
        column =
            case filterType of
                UserPackages ->
                    Packages

                DirectDeps ->
                    Packages

                DepsOfDeps ->
                    Packages

                ExposedModules ->
                    Modules

                EffectModules ->
                    Modules

                PortModules ->
                    Modules

                ExposedDefinitions ->
                    Definitions

        filterTooltip : String
        filterTooltip =
            case filterType of
                UserPackages ->
                    "User packages"

                DirectDeps ->
                    "Direct deps"

                DepsOfDeps ->
                    "Deps of deps"

                ExposedModules ->
                    "Exposed modules"

                EffectModules ->
                    "Effect modules"

                PortModules ->
                    "Port modules"

                ExposedDefinitions ->
                    "Exposed"
    in
    H.button
        [ HA.classList
            [ ( "filter__button", True )
            , ( "btn", True )
            , ( "btn-mini", True )
            , ( "btn-default", True )
            , ( "active", isActive )
            ]
        , HE.onMouseEnter (ShowColumnTitle column filterTooltip)
        , HE.onMouseLeave (HideColumnTitle column)
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
        |> Dict.toList
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


packagesHeader : Maybe String -> PackagesFilterConfig -> Html Msg
packagesHeader maybeTitle { user, directDeps, depsOfDeps } =
    H.div
        [ HA.class "top-table__heading" ]
        [ H.span
            [ HA.class "top-table__heading__label" ]
            [ maybeTitle
                |> Maybe.withDefault "Packages"
                |> H.text
            ]
        , H.div
            [ HA.class "top-table__heading__filters btn-group" ]
            [ filterButton UserPackages user
            , filterButton DirectDeps directDeps
            , filterButton DepsOfDeps depsOfDeps
            ]
        ]


modulesHeader : Maybe String -> ModulesFilterConfig -> Html Msg
modulesHeader maybeTitle { exposed, effect, port_ } =
    H.div
        [ HA.class "top-table__heading" ]
        [ H.span
            [ HA.class "top-table__heading__label" ]
            [ maybeTitle
                |> Maybe.withDefault "Modules"
                |> H.text
            ]
        , H.div
            [ HA.class "top-table__heading__filters btn-group" ]
            [ filterButton ExposedModules exposed
            , filterButton EffectModules effect
            , filterButton PortModules port_
            ]
        ]


definitionsHeader : Maybe String -> DefinitionsFilterConfig -> Html Msg
definitionsHeader maybeTitle { exposed } =
    H.div
        [ HA.class "top-table__heading" ]
        [ H.span
            [ HA.class "top-table__heading__label" ]
            [ maybeTitle
                |> Maybe.withDefault "Definitions"
                |> H.text
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
modules index selection { exposed, effect, port_ } =
    let
        showAll =
            not (exposed || effect || port_)
    in
    (case packagesForModulesColumn index selection of
        AllPackages ->
            index.packages |> Utils.dictKeysToSet

        SelectedPackages ->
            selection
                |> Selection.selectedPackageId
                |> Maybe.map Set.singleton
                |> Maybe.withDefault Set.empty
    )
        |> (\a -> Selection.modulesForPackages a index)
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


definitionsColumn : Index -> Selection -> DefinitionsFilterConfig -> Dict DefinitionId SourceCode -> Html Msg
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
