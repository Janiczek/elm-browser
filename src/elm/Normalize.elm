module Normalize exposing (toIndex)

import Elm.Parser
import Elm.Processing
import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.Exposing exposing (Exposing(..))
import Elm.Syntax.File exposing (File)
import Elm.Syntax.Module
import Elm.Syntax.Ranged exposing (Ranged)
import Elm.Writer
import EveryDict as EDict exposing (EveryDict)
import EverySet as ESet exposing (EverySet)
import Json.Decode as JD exposing (Decoder)
import Regex exposing (Regex)
import Selection
import Types exposing (..)


type alias ElmPackageJson =
    { name : String
    , dependencies : List String
    , version : String
    , exposedModules : List String
    }


type alias RawElmPackage =
    { path : String
    , isMain : Bool
    , data : ElmPackageJson
    , elmFiles : List ( String, String )
    }


toIndex : String -> List ( String, String ) -> Index
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

        elmFiles : List ( String, String, File )
        elmFiles =
            files
                |> List.filter (\( path, _ ) -> isElmModule path && not (isTestPath path))
                |> List.filterMap
                    (\( path, source ) ->
                        parse source
                            |> Maybe.map (\file -> ( path, source, file ))
                    )

        modules : List Module
        modules =
            toModules allPackages elmFiles

        definitions : List Definition
        definitions =
            toDefinitions (elmFiles |> List.map (\( _, _, file ) -> file))

        packagesDict : EveryDict PackageId Package
        packagesDict =
            packages
                |> List.map (\package -> ( PackageId package.name, package ))
                |> EDict.fromList

        modulesDict : EveryDict ModuleId Module
        modulesDict =
            modules
                |> List.map (\module_ -> ( ModuleId module_.name, module_ ))
                |> EDict.fromList

        definitionsDict : EveryDict DefinitionId Definition
        definitionsDict =
            definitions
                |> List.map (\definition -> ( DefinitionId definition.qualifiedName, definition ))
                |> EDict.fromList
    in
    { packages = packagesDict
    , modules = modulesDict
    , definitions = definitionsDict
    }


toPackage : RawElmPackage -> RawElmPackage -> Package
toPackage mainPackage { data, isMain, elmFiles } =
    { name = data.name
    , version = data.version
    , modules =
        elmFiles
            |> List.map (Tuple.second >> sourceCodeToModuleName >> ModuleId)
            |> ESet.fromList
    , dependencyType =
        if isMain then
            UserPackage
        else if mainPackage.data.dependencies |> List.member data.name then
            DirectDependency
        else
            DependencyOfDependency
    }


parse : String -> Maybe File
parse source =
    source
        |> Elm.Parser.parse
        |> Result.toMaybe
        |> Maybe.map (Elm.Processing.process Elm.Processing.init)


elmPackageJsonDecoder : Decoder ElmPackageJson
elmPackageJsonDecoder =
    JD.map4 ElmPackageJson
        (JD.field "repository" (JD.string |> JD.andThen repositoryToName))
        (JD.field "dependencies" dependenciesDecoder)
        (JD.field "version" JD.string)
        (JD.field "exposed-modules" (JD.list JD.string))


dependenciesDecoder : Decoder (List String)
dependenciesDecoder =
    JD.keyValuePairs JD.string
        |> JD.map (List.map Tuple.first)


repositoryNameRegex : Regex
repositoryNameRegex =
    Regex.regex "([^/]+/[^/]+)\\.git$"


moduleNameRegex : Regex
moduleNameRegex =
    Regex.regex "module ([^ ]+)"


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


isElmPackageJson : String -> Bool
isElmPackageJson path =
    path
        |> String.endsWith "elm-package.json"


isElmModule : String -> Bool
isElmModule path =
    path
        |> String.endsWith ".elm"


isTestPath : String -> Bool
isTestPath path =
    (path |> String.contains "/tests/")
        || (path |> String.contains "/test/")


isDependencyPath : String -> Bool
isDependencyPath path =
    path
        |> String.contains "/elm-stuff/"


toRawPackages : String -> List ( String, String ) -> List RawElmPackage
toRawPackages rootPath files =
    files
        |> List.filter (\( path, _ ) -> isElmPackageJson path && not (isTestPath path))
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
                                                not (isDependencyPath path)
                                             else
                                                path |> String.contains data.name
                                            )
                                                && not (isTestPath path)
                                                && isElmModule path
                                        )
                            }
                        )
            )


firstWord : String -> String
firstWord string =
    string
        |> String.words
        |> List.head
        |> Maybe.withDefault ""


toModules : List RawElmPackage -> List ( String, String, File ) -> List Module
toModules packages files =
    files
        |> List.filter (\( path, _, _ ) -> isElmModule path && not (isTestPath path))
        |> List.map
            (\( path, source, file ) ->
                let
                    moduleFlag : String
                    moduleFlag =
                        firstWord source

                    name : String
                    name =
                        sourceCodeToModuleName source

                    package : Maybe RawElmPackage
                    package =
                        packages
                            |> List.filter
                                (\package ->
                                    package.elmFiles
                                        |> List.map Tuple.first
                                        |> List.member path
                                )
                            |> List.head

                    isExposed : Bool
                    isExposed =
                        package
                            |> Maybe.map (\{ data } -> data.exposedModules |> List.member name)
                            |> Maybe.withDefault False
                in
                { name = name
                , path = path
                , isExposed = isExposed
                , isEffect = firstWord source == "effect"
                , isPort = firstWord source == "port"
                , definitions = findDefinitionNames name file
                }
            )


findDefinitionNames : String -> File -> EverySet DefinitionId
findDefinitionNames moduleName file =
    file
        |> .declarations
        |> List.filterMap declarationName
        |> List.map (Selection.definitionId moduleName)
        |> ESet.fromList


declarationName : Ranged Declaration -> Maybe String
declarationName rangedDeclaration =
    case Elm.Syntax.Ranged.value rangedDeclaration of
        FuncDecl func ->
            if func.declaration.operatorDefinition then
                Just <| "(" ++ func.declaration.name.value ++ ")"
            else
                Just func.declaration.name.value

        AliasDecl typeAlias ->
            Just typeAlias.name

        TypeDecl typeDecl ->
            Just typeDecl.name

        PortDeclaration portDecl ->
            Just portDecl.name.value

        InfixDeclaration infix ->
            Just infix.operator

        Destructuring pattern expression ->
            -- what the heck even is this
            Nothing


toDefinitions : List File -> List Definition
toDefinitions files =
    files
        |> List.concatMap
            (\file ->
                file.declarations
                    |> List.map (\declaration -> ( file, declaration ))
            )
        |> List.filterMap
            (\( file, ( range, declaration ) as rangedDeclaration ) ->
                let
                    name : Maybe String
                    name =
                        declarationName rangedDeclaration

                    moduleName : Maybe String
                    moduleName =
                        file.moduleDefinition
                            |> Elm.Syntax.Module.moduleName
                            |> Maybe.map (String.join ".")

                    qualifiedName : Maybe String
                    qualifiedName =
                        Maybe.map2 Selection.definitionQualifiedName
                            moduleName
                            name

                    kind : Maybe DefinitionKind
                    kind =
                        case declaration of
                            FuncDecl func ->
                                if List.isEmpty func.declaration.arguments then
                                    Just Constant
                                else
                                    Just Function

                            AliasDecl typeAlias ->
                                Just TypeAlias

                            TypeDecl typeDecl ->
                                Just Type

                            PortDeclaration portDecl ->
                                Nothing

                            InfixDeclaration infix ->
                                Nothing

                            Destructuring pattern expression ->
                                Nothing

                    isExposed : Bool
                    isExposed =
                        name
                            |> Maybe.map (moduleExposesFunction file)
                            |> Maybe.withDefault False

                    sourceCode : SourceCode
                    sourceCode =
                        rangedDeclaration
                            |> Elm.Writer.writeDeclaration
                            |> Elm.Writer.write
                            |> SourceCode
                in
                Maybe.map3
                    (\name qualifiedName kind ->
                        { name = name
                        , qualifiedName = qualifiedName
                        , kind = kind
                        , isExposed = isExposed
                        , sourceCode = sourceCode
                        , range = range
                        }
                    )
                    name
                    qualifiedName
                    kind
            )


moduleExposesFunction : File -> String -> Bool
moduleExposesFunction file name =
    file.moduleDefinition
        |> Elm.Syntax.Module.exposingList
        |> exposingMap Elm.Syntax.Ranged.value
        |> Elm.Syntax.Exposing.exposesFunction name


exposingMap : (a -> b) -> Exposing a -> Exposing b
exposingMap fn exp =
    case exp of
        All range ->
            All range

        Explicit list ->
            Explicit (List.map fn list)
