module Normalize exposing (toIndex)

import AssocList as Dict exposing (Dict)
import AssocSet as Set exposing (Set)
import Elm.Module
import Elm.Package
import Elm.Parser
import Elm.Processing
import Elm.Project
import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.Exposing exposing (Exposing(..))
import Elm.Syntax.File exposing (File)
import Elm.Syntax.Module
import Elm.Syntax.Node
import Elm.Syntax.Range exposing (Range)
import Elm.Version
import Elm.Writer
import Json.Decode as JD exposing (Decoder)
import Regex exposing (Regex)
import Selection
import Types exposing (..)


type alias ElmJson =
    { name : String
    , dependencies : List String
    , version : String
    , exposedModules : List String
    }


type alias RawElmPackage =
    { path : String
    , isMain : Bool
    , data : ElmJson
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

        packagesDict : Dict PackageId Package
        packagesDict =
            packages
                |> List.map (\package -> ( PackageId package.name, package ))
                |> Dict.fromList

        modulesDict : Dict ModuleId Module
        modulesDict =
            modules
                |> List.map (\module_ -> ( ModuleId module_.name, module_ ))
                |> Dict.fromList

        definitionsDict : Dict DefinitionId Definition
        definitionsDict =
            definitions
                |> List.map (\definition -> ( DefinitionId definition.qualifiedName, definition ))
                |> Dict.fromList
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
            |> Set.fromList
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


elmJsonDecoder : List String -> Decoder ElmJson
elmJsonDecoder userModules =
    Elm.Project.decoder
        |> JD.map
            (\project ->
                case project of
                    Elm.Project.Application app ->
                        { name = "user/project"
                        , dependencies =
                            List.concat
                                [ app.depsDirect
                                , app.depsIndirect
                                , app.testDepsDirect
                                , app.testDepsIndirect
                                ]
                                |> List.map (Tuple.first >> Elm.Package.toString)
                        , version = "APP"
                        , exposedModules = userModules
                        }

                    Elm.Project.Package package ->
                        { name = Elm.Package.toString package.name
                        , dependencies =
                            List.concat
                                [ package.deps
                                , package.testDeps -- maybe not?
                                ]
                                |> List.map (Tuple.first >> Elm.Package.toString)
                        , version = Elm.Version.toString package.version
                        , exposedModules =
                            case package.exposed of
                                Elm.Project.ExposedList list ->
                                    List.map Elm.Module.toString list

                                Elm.Project.ExposedDict list ->
                                    List.concatMap (Tuple.second >> List.map Elm.Module.toString) list
                        }
            )


dependenciesDecoder : Decoder (List String)
dependenciesDecoder =
    JD.keyValuePairs JD.string
        |> JD.map (List.map Tuple.first)


repositoryNameRegex : Regex
repositoryNameRegex =
    Regex.fromString "([^/]+/[^/]+)\\.git$"
        -- We've checked this is a valid regex and won't return Nothing
        |> Maybe.withDefault Regex.never


moduleNameRegex : Regex
moduleNameRegex =
    Regex.fromString "module ([^ ]+)"
        -- We've checked this is a valid regex and won't return Nothing
        |> Maybe.withDefault Regex.never


{-|

    "https://github.com/author/project.git" --> JD.succeed "author/project"

    "something that doesn't have foo/bar.git at the end" --> JD.fail "..."

-}
repositoryToName : String -> Decoder String
repositoryToName repository =
    repository
        |> Regex.findAtMost 1 repositoryNameRegex
        |> firstSubmatch
        |> Maybe.map JD.succeed
        |> Maybe.withDefault (JD.fail "Couldn't decode the package author and name from the \"repository\" field in elm.json")


sourceCodeToModuleName : String -> String
sourceCodeToModuleName sourceCode =
    sourceCode
        |> String.lines
        |> List.head
        |> Maybe.andThen
            (\firstLine ->
                firstLine
                    |> Regex.findAtMost 1 moduleNameRegex
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


isElmJson : String -> Bool
isElmJson path =
    path
        |> String.endsWith "elm.json"


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
    let
        userModules : List String
        userModules =
            files
                |> List.map Tuple.first
                |> List.filter isElmModule
    in
    files
        |> List.filter
            (\( path, _ ) ->
                isElmJson path
                    && not (isTestPath path)
            )
        |> List.filterMap
            (\( path, source ) ->
                source
                    |> JD.decodeString (elmJsonDecoder userModules)
                    |> Result.toMaybe
                    |> Maybe.map
                        (\data ->
                            let
                                isMain =
                                    path == rootPath ++ "/elm.json"
                            in
                            { path = path
                            , isMain = isMain
                            , data = data
                            , elmFiles =
                                files
                                    |> List.filter
                                        (\( path_, _ ) ->
                                            (if isMain then
                                                not (isDependencyPath path_)

                                             else
                                                String.contains data.name path_
                                            )
                                                && not (isTestPath path_)
                                                && isElmModule path_
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
                                (\package_ ->
                                    package_.elmFiles
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


findDefinitionNames : String -> File -> Set DefinitionId
findDefinitionNames moduleName file =
    file.declarations
        |> List.filterMap (Elm.Syntax.Node.value >> declarationName)
        |> List.map (Selection.definitionId moduleName)
        |> Set.fromList


declarationName : Declaration -> Maybe String
declarationName declaration =
    case declaration of
        FunctionDeclaration func ->
            func.declaration
                |> Elm.Syntax.Node.value
                |> .name
                |> Elm.Syntax.Node.value
                |> Just

        AliasDeclaration typeAlias ->
            typeAlias.name
                |> Elm.Syntax.Node.value
                |> Just

        CustomTypeDeclaration typeDecl ->
            typeDecl.name
                |> Elm.Syntax.Node.value
                |> Just

        PortDeclaration portDecl ->
            portDecl.name
                |> Elm.Syntax.Node.value
                |> Just

        InfixDeclaration infix ->
            infix.operator
                |> Elm.Syntax.Node.value
                |> Just

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
            (\( file, rangedDeclaration ) ->
                let
                    range : Range
                    range =
                        Elm.Syntax.Node.range rangedDeclaration

                    declaration : Declaration
                    declaration =
                        Elm.Syntax.Node.value rangedDeclaration

                    name : Maybe String
                    name =
                        declarationName declaration

                    moduleName : String
                    moduleName =
                        file.moduleDefinition
                            |> Elm.Syntax.Node.value
                            |> Elm.Syntax.Module.moduleName
                            |> String.join "."

                    qualifiedName : Maybe String
                    qualifiedName =
                        name
                            |> Maybe.map (Selection.definitionQualifiedName moduleName)

                    kind : Maybe DefinitionKind
                    kind =
                        case declaration of
                            FunctionDeclaration func ->
                                let
                                    decl =
                                        func.declaration
                                            |> Elm.Syntax.Node.value
                                in
                                if List.isEmpty decl.arguments then
                                    Just Constant

                                else
                                    Just Function

                            AliasDeclaration typeAlias ->
                                Just TypeAlias

                            CustomTypeDeclaration typeDecl ->
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
                    (\name_ qualifiedName_ kind_ ->
                        { name = name_
                        , qualifiedName = qualifiedName_
                        , kind = kind_
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
        |> Elm.Syntax.Node.value
        |> Elm.Syntax.Module.exposingList
        |> Elm.Syntax.Exposing.exposesFunction name
