module Normalize exposing (toIndex)

import EverySet as ESet
import Json.Decode as JD exposing (Decoder)
import Regex exposing (Regex)
import Types exposing (..)


type alias ElmPackageJson =
    { name : String
    , dependencies : List String
    , version : String
    }


type alias RawElmPackage =
    { path : String
    , isMain : Bool
    , data : ElmPackageJson
    , elmFiles : List String
    }


toIndex : String -> List ( String, String ) -> Maybe Index
toIndex rootPath files =
    let
        allPackages : List RawElmPackage
        allPackages =
            toRawPackages rootPath files

        mainPackage : Maybe RawElmPackage
        mainPackage =
            allPackages
                |> List.filter .isMain
                |> List.head

        packages : List Package
        packages =
            mainPackage
                |> Maybe.map
                    (\main ->
                        allPackages
                            |> List.map (toPackage main)
                    )
                |> Maybe.withDefault []
    in
    Nothing


toPackage : RawElmPackage -> RawElmPackage -> Package
toPackage mainPackage { data, isMain, elmFiles } =
    { name = data.name
    , version = data.version
    , modules =
        elmFiles
            |> List.map (sourceCodeToModuleName >> ModuleId)
            |> ESet.fromList
    , dependencyType =
        if isMain then
            UserPackage
        else if data.dependencies |> List.member data.name then
            DirectDependency
        else
            DependencyOfDependency
    }


elmPackageJsonDecoder : Decoder ElmPackageJson
elmPackageJsonDecoder =
    JD.map3 ElmPackageJson
        (JD.field "repository" (JD.string |> JD.andThen repositoryToName))
        (JD.field "dependencies" dependenciesDecoder)
        (JD.field "version" JD.string)


dependenciesDecoder : Decoder (List String)
dependenciesDecoder =
    JD.keyValuePairs JD.string
        |> JD.map (List.map Tuple.first)


repositoryNameRegex : Regex
repositoryNameRegex =
    Regex.regex "([^/]+/[^/]+)\\.git$"


moduleNameRegex : Regex
moduleNameRegex =
    Regex.regex "module ([^ ]+) "


{-|

    "https://github.com/author/project.git" --> JD.succeed "author/project"
    "something that doesn't have foo/bar.git at the end" --> JD.fail "..."

-}
repositoryToName : String -> Decoder String
repositoryToName repository =
    repository
        |> Regex.find (Regex.AtMost 1) repositoryNameRegex
        |> firstSubmatch
        |> Maybe.map JD.succeed
        |> Maybe.withDefault (JD.fail "Couldn't decode the package author and name from the \"repository\" field in elm-package.json")


sourceCodeToModuleName : String -> String
sourceCodeToModuleName sourceCode =
    sourceCode
        |> String.lines
        |> List.head
        |> Maybe.andThen
            (\firstLine ->
                firstLine
                    |> Regex.find (Regex.AtMost 1) moduleNameRegex
                    |> firstSubmatch
            )
        |> Maybe.withDefault "Error getting module name from the source code"


firstSubmatch : List Regex.Match -> Maybe String
firstSubmatch matches =
    matches
        |> List.head
        |> Maybe.map .submatches
        |> Maybe.andThen List.head
        |> Maybe.andThen identity


toRawPackages : String -> List ( String, String ) -> List RawElmPackage
toRawPackages rootPath files =
    files
        |> List.filter
            (\( path, _ ) ->
                (path |> String.endsWith "elm-package.json")
                    && (path |> String.contains "/tests/" |> not)
            )
        |> List.filterMap
            (\( path, source ) ->
                source
                    |> JD.decodeString elmPackageJsonDecoder
                    |> Result.toMaybe
                    |> Maybe.map
                        (\data ->
                            let
                                isMain =
                                    path == rootPath ++ "/elm-package.json"
                            in
                            { path = path
                            , isMain = isMain
                            , data = data
                            , elmFiles =
                                files
                                    |> List.filter
                                        (\( path, _ ) ->
                                            (if isMain then
                                                path |> String.contains "elm-stuff" |> not
                                             else
                                                path |> String.contains data.name
                                            )
                                                && (path |> String.contains "/tests/" |> not)
                                                && (path |> String.endsWith ".elm")
                                        )
                                    |> List.map Tuple.second
                            }
                        )
            )
