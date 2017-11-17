module Tests exposing (..)

import Utils
import EveryDict as EDict
import Selection
import EverySet as ESet
import Expect exposing (Expectation)
import Test exposing (..)
import View.Column
import Fuzzers


suite : Test
suite =
    concat
        [ describe "View.Column"
            [ describe "packages"
                [ fuzz (Fuzzers.indexAndSelection Fuzzers.index { packages = True, module_ = True, definition = True })
                    "all always visible"
                  <|
                    \( index, selection ) ->
                        let
                            allPackages =
                                index.packages
                                    |> EDict.keys
                        in
                            View.Column.packages index selection
                                |> List.map Tuple.first
                                |> Expect.equal allPackages
                ]
            , describe "modules"
                [ fuzz (Fuzzers.indexAndSelection Fuzzers.indexWithModules { packages = True, module_ = True, definition = True })
                    "not empty if modules exist"
                  <|
                    \( index, selection ) ->
                        View.Column.modules index selection
                            |> Expect.notEqual []
                , fuzz Fuzzers.indexAndSelectionWithPackageSelected
                    "displays exactly all modules of all selected packages"
                  <|
                    \( index, selection ) ->
                        let
                            modulesOfAllSelectedPackages =
                                selection.packages
                                    |> Utils.dictGetVals index.packages
                                    |> List.map .modules
                                    |> List.foldl ESet.union ESet.empty
                        in
                            View.Column.modules index selection
                                |> List.map Tuple.first
                                |> ESet.fromList
                                |> Expect.equal modulesOfAllSelectedPackages
                ]
            , describe "definitions"
                [ fuzz (Fuzzers.indexAndSelection Fuzzers.index { packages = True, module_ = False, definition = True })
                    "empty when a module is not selected"
                  <|
                    \( index, selection ) ->
                        View.Column.definitions index selection
                            |> List.map Tuple.first
                            |> Expect.equal []
                ]
            ]
        , describe "Selection"
            [ describe "modulesForPackages"
                [ fuzz (Fuzzers.indexAndSelection Fuzzers.index { packages = True, module_ = True, definition = True })
                    "has all the modules from the selected packages"
                  <|
                    \( index, selection ) ->
                        let
                            selectedPackages =
                                index.packages
                                    |> EDict.filter (\k v -> ESet.member k selection.packages)

                            modulesFromSelectedPackages =
                                selectedPackages
                                    |> EDict.values
                                    |> List.map .modules
                                    |> List.foldl ESet.union ESet.empty
                        in
                            Selection.modulesForPackages selection.packages index
                                |> ESet.diff modulesFromSelectedPackages
                                |> Expect.equal ESet.empty
                ]
            ]
        ]
