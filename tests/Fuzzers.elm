module Fuzzers exposing (..)

import Fuzz exposing (Fuzzer)
import Index
import Types exposing (..)
import EveryDict as EDict
import Utils
import EverySet as ESet exposing (EverySet)
import Types.Json exposing (..)


smallList : Fuzzer a -> Fuzzer (List a)
smallList f =
    Fuzz.oneOf
        [ Fuzz.constant []
        , Fuzz.map List.singleton f
        , Fuzz.map2 (\a b -> [ a, b ]) f f
        , Fuzz.map3 (\a b c -> [ a, b, c ]) f f f
        ]


smallNonEmptyList : Fuzzer a -> Fuzzer (List a)
smallNonEmptyList f =
    Fuzz.oneOf
        [ Fuzz.map List.singleton f
        , Fuzz.map2 (\a b -> [ a, b ]) f f
        , Fuzz.map3 (\a b c -> [ a, b, c ]) f f f
        ]


maybeOneOf : List a -> Fuzzer (Maybe a)
maybeOneOf xs =
    if List.isEmpty xs then
        Fuzz.constant Nothing
    else
        xs
            |> List.map Fuzz.constant
            |> Fuzz.oneOf
            |> Fuzz.maybe


sublist : List a -> Fuzzer (List a)
sublist xs =
    Fuzz.list Fuzz.bool
        |> Fuzz.andThen
            (\bools ->
                List.map2 (,) xs bools
                    |> List.filter Tuple.second
                    |> List.map Tuple.first
                    |> Fuzz.constant
            )



--


type alias SelectionFuzzerConfig =
    { packages : Bool, module_ : Bool, definition : Bool }


selection : SelectionFuzzerConfig -> Index -> Fuzzer Selection
selection { packages, module_, definition } index =
    let
        packagesFuzzer =
            if packages then
                packagesSelection index
            else
                Fuzz.constant ESet.empty

        moduleFuzzer =
            if module_ then
                moduleSelection index
            else
                Fuzz.constant Nothing

        definitionFuzzer =
            if definition then
                definitionSelection index
            else
                Fuzz.constant Nothing
    in
        Fuzz.map3 (\ps m d -> Selection ps m d)
            packagesFuzzer
            moduleFuzzer
            definitionFuzzer


packagesSelection : Index -> Fuzzer (EverySet PackageOnlyId)
packagesSelection index =
    index.packages
        |> EDict.keys
        |> sublist
        |> Fuzz.map ESet.fromList


onePackage : Index -> Fuzzer (EverySet PackageOnlyId)
onePackage index =
    if EDict.isEmpty index.packages then
        Fuzz.constant ESet.empty
    else
        index.packages
            |> EDict.keys
            |> List.map Fuzz.constant
            |> Fuzz.oneOf
            |> Fuzz.map ESet.singleton


moduleSelection : Index -> Fuzzer (Maybe ModuleOnlyId)
moduleSelection index =
    index.modules
        |> EDict.keys
        |> maybeOneOf


definitionSelection : Index -> Fuzzer (Maybe DefinitionOnlyId)
definitionSelection index =
    index.definitions
        |> EDict.keys
        |> maybeOneOf


indexAndSelection : Fuzzer Index -> SelectionFuzzerConfig -> Fuzzer ( Index, Selection )
indexAndSelection index config =
    index
        |> Fuzz.andThen
            (\index ->
                Fuzz.map2 (,)
                    (Fuzz.constant index)
                    (selection config index)
            )


indexAndSelectionWithPackageSelected : Fuzzer ( Index, Selection )
indexAndSelectionWithPackageSelected =
    let
        selectionWithPackageSelected index =
            onePackage index
                |> Fuzz.andThen
                    (\onePackageId ->
                        Fuzz.map3 (\ps m d -> Selection ps m d)
                            (Fuzz.constant onePackageId)
                            (moduleSelection index)
                            (definitionSelection index)
                    )
    in
        indexWithModules
            |> Fuzz.andThen
                (\index ->
                    Fuzz.map2 (,)
                        (Fuzz.constant index)
                        (selectionWithPackageSelected index)
                )


indexAndSelectionWithModuleSelectedFromSelectedPackages : Fuzzer ( Index, Selection )
indexAndSelectionWithModuleSelectedFromSelectedPackages =
    let
        selectionWithModuleSelectedFromSelectedPackages index =
            onePackage index
                |> Fuzz.andThen
                    (\onePackageId ->
                        Fuzz.map3 (\ps m d -> Selection ps m d)
                            (Fuzz.constant onePackageId)
                            (onePackageId
                                |> Utils.dictGetVals index.packages
                                |> List.map .modules
                                |> List.foldl ESet.union ESet.empty
                                |> ESet.toList
                                |> List.map Fuzz.constant
                                |> Fuzz.oneOf
                                |> Fuzz.map Just
                            )
                            (definitionSelection index)
                    )
    in
        indexWithModules
            |> Fuzz.andThen
                (\index ->
                    Fuzz.map2 (,)
                        (Fuzz.constant index)
                        (selectionWithModuleSelectedFromSelectedPackages index)
                )


index : Fuzzer Index
index =
    smallList jsonPackage
        |> Fuzz.map Index.normalize


indexWithModules : Fuzzer Index
indexWithModules =
    smallNonEmptyList jsonPackageWithModules
        |> Fuzz.map Index.normalize



--


jsonPackage : Fuzzer JsonPackage
jsonPackage =
    Fuzz.map3 (\s b m -> JsonPackage s s s b b b m)
        Fuzz.string
        Fuzz.bool
        (smallList jsonModule_)


jsonPackageWithModules : Fuzzer JsonPackage
jsonPackageWithModules =
    Fuzz.map3 (\s b m -> JsonPackage s s s b b b m)
        Fuzz.string
        Fuzz.bool
        (smallNonEmptyList jsonModule_)


jsonModule_ : Fuzzer JsonModule
jsonModule_ =
    Fuzz.map4 (\s b d l -> JsonModule s b b b b d l)
        Fuzz.string
        Fuzz.bool
        (smallList definition)
        language


language : Fuzzer Language
language =
    Fuzz.oneOf
        [ Fuzz.constant Elm
        , Fuzz.constant JavaScript
        ]


definition : Fuzzer Definition
definition =
    Fuzz.map3 (\s d b -> Definition s d b s)
        Fuzz.string
        definitionKind
        Fuzz.bool


definitionKind : Fuzzer DefinitionKind
definitionKind =
    Fuzz.oneOf
        [ Fuzz.map (\s -> Constant { type_ = s }) Fuzz.string
        , Fuzz.map (\s -> Function { type_ = s }) Fuzz.string
        , Fuzz.constant Type
        , Fuzz.map (\s -> TypeConstructor { type_ = s }) Fuzz.string
        , Fuzz.constant TypeAlias
        ]
