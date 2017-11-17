module View.Column exposing (..)

import EveryDict as EDict
import EverySet as ESet exposing (EverySet)
import Html as H exposing (Html)
import Html.Attributes as HA
import Selection
import Types exposing (..)
import Utils
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
            [ packagesColumn index selection
            , modulesColumn index selection
            , definitionsColumn index selection
            ]
        ]


packages : Index -> Selection -> List ( PackageOnlyId, Package )
packages index selection =
    index.packages
        |> EDict.toList


packagesColumn : Index -> Selection -> Html Msg
packagesColumn index selection =
    packages index selection
        |> List.map (\( packageId, package ) -> Row.package selection packageId package)
        |> innerTable


modules : Index -> Selection -> List ( ModuleOnlyId, Module )
modules index selection =
    (case packagesForModulesColumn index selection of
        AllPackages ->
            index.packages |> Utils.dictKeysToSet

        SelectedPackages ->
            selection.packages
    )
        |> (flip Selection.modulesForPackages) index
        |> Utils.dictGetKv index.modules


modulesColumn : Index -> Selection -> Html Msg
modulesColumn index selection =
    modules index selection
        |> List.map (\( moduleId, module_ ) -> Row.module_ selection moduleId module_)
        |> innerTable


definitions : Index -> Selection -> List ( DefinitionOnlyId, Definition )
definitions index selection =
    if canShowDefinitionsFromSelectedModule index selection then
        selection.module_
            |> Maybe.andThen ((flip EDict.get) index.modules)
            |> Maybe.map .definitions
            |> Maybe.withDefault ESet.empty
            |> Utils.dictGetKv index.definitions
    else
        []


definitionsColumn : Index -> Selection -> Html Msg
definitionsColumn index selection =
    definitions index selection
        |> List.map (\( definitionId, definition ) -> Row.definition selection definitionId definition)
        |> innerTable


type PackagesToShowModulesFrom
    = AllPackages
    | SelectedPackages


packagesForModulesColumn : Index -> Selection -> PackagesToShowModulesFrom
packagesForModulesColumn index selection =
    if ESet.isEmpty selection.packages then
        AllPackages
    else
        SelectedPackages


canShowDefinitionsFromSelectedModule : Index -> Selection -> Bool
canShowDefinitionsFromSelectedModule index selection =
    selection.module_
        |> Maybe.map (\module_ -> ESet.isEmpty selection.packages || ESet.member module_ (Selection.modulesForPackages selection.packages index))
        |> Maybe.withDefault True


innerTable : List (Html Msg) -> Html Msg
innerTable elements =
    H.div
        [ HA.class "inner-table" ]
        [ H.table
            [ HA.class "table-striped" ]
            [ H.tbody [] elements ]
        ]
