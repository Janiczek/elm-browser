module Editor exposing (Config, Model, Msg, init, setContent, update, view)

import Array exposing (Array)
import Html as H exposing (Attribute, Html)
import Html.Attributes as HA
import Html.Events as HE
import Json.Decode as JD exposing (Decoder)


type alias Model =
    { lines : Array String
    , position : Position
    , hover : Hover
    }


type Hover
    = NoHover
    | HoverLine Int
    | HoverChar Position


type alias Config =
    { isDisabled : Bool }


type alias Position =
    { line : Int
    , column : Int
    }


type Msg
    = MoveUp
    | MoveDown
    | MoveLeft
    | MoveRight
    | NewLine
    | InsertChar Char
    | RemoveCharBefore
    | RemoveCharAfter
    | Hover Hover
    | GoToHoveredPosition


init : String -> Model
init content =
    { lines = stringToLines content
    , position = Position 0 0
    , hover = NoHover
    }


stringToLines : String -> Array String
stringToLines content =
    content
        |> String.lines
        |> Array.fromList


setContent : String -> Model -> Model
setContent content model =
    { model | lines = stringToLines content }
        |> sanitizeHover
        |> sanitizePosition


keyDecoder : Decoder Msg
keyDecoder =
    JD.field "key" JD.string
        |> JD.andThen keyToMsg


keyToMsg : String -> Decoder Msg
keyToMsg string =
    case String.uncons string of
        Just ( char, "" ) ->
            JD.succeed (InsertChar char)

        _ ->
            case string of
                "ArrowUp" ->
                    JD.succeed MoveUp

                "ArrowDown" ->
                    JD.succeed MoveDown

                "ArrowLeft" ->
                    JD.succeed MoveLeft

                "ArrowRight" ->
                    JD.succeed MoveRight

                "Backspace" ->
                    JD.succeed RemoveCharBefore

                "Delete" ->
                    JD.succeed RemoveCharAfter

                "Enter" ->
                    JD.succeed NewLine

                _ ->
                    JD.fail "This key does nothing"


{-| Returns the changed source code as the second element of the tuple.
-}
update : Msg -> Model -> ( Model, Maybe String )
update msg model =
    case msg of
        MoveUp ->
            { model | position = moveUp model.position model.lines }
                |> withNoSource

        MoveDown ->
            { model | position = moveDown model.position model.lines }
                |> withNoSource

        MoveLeft ->
            { model | position = moveLeft model.position model.lines }
                |> withNoSource

        MoveRight ->
            { model | position = moveRight model.position model.lines }
                |> withNoSource

        NewLine ->
            newLine model
                |> sanitizeHover
                |> withSource

        InsertChar char ->
            insertChar char model
                |> withSource

        RemoveCharBefore ->
            removeCharBefore model
                |> sanitizeHover
                |> withSource

        RemoveCharAfter ->
            removeCharAfter model
                |> sanitizeHover
                |> withSource

        Hover hover ->
            { model | hover = hover }
                |> sanitizeHover
                |> withNoSource

        GoToHoveredPosition ->
            { model
                | position =
                    case model.hover of
                        NoHover ->
                            model.position

                        HoverLine line ->
                            { line = line
                            , column = lastColumn model.lines line
                            }

                        HoverChar position ->
                            position
            }
                |> withNoSource


withNoSource : Model -> ( Model, Maybe String )
withNoSource model =
    ( model, Nothing )


withSource : Model -> ( Model, Maybe String )
withSource model =
    ( model
    , Just
        (model.lines
            |> Array.toList
            |> String.join "\n"
        )
    )


sanitizePosition : Model -> Model
sanitizePosition model =
    { model
        | position =
            let
                sanitizedLine =
                    clamp 0 (lastLine model.lines) model.position.line

                sanitizedColumn =
                    clamp 0 (lastColumn model.lines sanitizedLine) model.position.column
            in
            { line = sanitizedLine
            , column = sanitizedColumn
            }
    }


sanitizeHover : Model -> Model
sanitizeHover model =
    { model
        | hover =
            case model.hover of
                NoHover ->
                    model.hover

                HoverLine line ->
                    HoverLine (clamp 0 (lastLine model.lines) line)

                HoverChar { line, column } ->
                    let
                        sanitizedLine =
                            clamp 0 (lastLine model.lines) line

                        sanitizedColumn =
                            clamp 0 (lastColumn model.lines sanitizedLine) column
                    in
                    HoverChar
                        { line = sanitizedLine
                        , column = sanitizedColumn
                        }
    }


newLine : Model -> Model
newLine ({ position, lines } as model) =
    let
        { line, column } =
            position

        linesList : List String
        linesList =
            Array.toList lines

        line_ : Int
        line_ =
            line + 1

        contentUntilCursor : List String
        contentUntilCursor =
            linesList
                |> List.take line_
                |> List.indexedMap
                    (\i content ->
                        if i == line then
                            String.left column content

                        else
                            content
                    )

        restOfLineAfterCursor : String
        restOfLineAfterCursor =
            String.dropLeft column (lineContent lines line)

        restOfLines : List String
        restOfLines =
            List.drop line_ linesList

        newLines : Array String
        newLines =
            (contentUntilCursor
                ++ [ restOfLineAfterCursor ]
                ++ restOfLines
            )
                |> Array.fromList

        newPosition : Position
        newPosition =
            { line = line_
            , column = 0
            }
    in
    { model
        | lines = newLines
        , position = newPosition
    }


insertChar : Char -> Model -> Model
insertChar char ({ position, lines } as model) =
    let
        { line, column } =
            position

        lineWithCharAdded : String -> String
        lineWithCharAdded content =
            String.left column content
                ++ String.fromChar char
                ++ String.dropLeft column content

        newLines : Array String
        newLines =
            lines
                |> Array.indexedMap
                    (\i content ->
                        if i == line then
                            lineWithCharAdded content

                        else
                            content
                    )

        newPosition : Position
        newPosition =
            { line = line
            , column = column + 1
            }
    in
    { model
        | lines = newLines
        , position = newPosition
    }


removeCharBefore : Model -> Model
removeCharBefore ({ position, lines } as model) =
    if isStartOfDocument position then
        model

    else
        let
            { line, column } =
                position

            lineIsEmpty : Bool
            lineIsEmpty =
                lineContent lines line
                    |> String.isEmpty

            removeCharFromLine : ( Int, String ) -> List String
            removeCharFromLine ( lineNum, content ) =
                if lineNum == line - 1 then
                    if isFirstColumn column then
                        [ content ++ lineContent lines line ]

                    else
                        [ content ]

                else if lineNum == line then
                    if isFirstColumn column then
                        []

                    else
                        [ String.left (column - 1) content
                            ++ String.dropLeft column content
                        ]

                else
                    [ content ]

            newLines : Array String
            newLines =
                lines
                    |> Array.toIndexedList
                    |> List.concatMap removeCharFromLine
                    |> Array.fromList
        in
        { model
            | lines = newLines
            , position = moveLeft position lines
        }


removeCharAfter : Model -> Model
removeCharAfter ({ position, lines } as model) =
    if isEndOfDocument lines position then
        model

    else
        let
            { line, column } =
                position

            isOnLastColumn : Bool
            isOnLastColumn =
                isLastColumn lines line column

            removeCharFromLine : ( Int, String ) -> List String
            removeCharFromLine ( lineNum, content ) =
                if lineNum == line then
                    if isOnLastColumn then
                        [ content ++ lineContent lines (line + 1) ]

                    else
                        [ String.left column content
                            ++ String.dropLeft (column + 1) content
                        ]

                else if lineNum == line + 1 then
                    if isOnLastColumn then
                        []

                    else
                        [ content ]

                else
                    [ content ]

            newLines : Array String
            newLines =
                lines
                    |> Array.toIndexedList
                    |> List.concatMap removeCharFromLine
                    |> Array.fromList
        in
        { model
            | lines = newLines
            , position = position
        }


moveUp : Position -> Array String -> Position
moveUp { line, column } lines =
    if isFirstLine line then
        startOfDocument

    else
        let
            line_ : Int
            line_ =
                previousLine line
        in
        { line = line_
        , column = clampColumn lines line_ column
        }


moveDown : Position -> Array String -> Position
moveDown { line, column } lines =
    if isLastLine lines line then
        endOfDocument lines

    else
        let
            line_ : Int
            line_ =
                nextLine lines line
        in
        { line = line_
        , column = clampColumn lines line_ column
        }


moveLeft : Position -> Array String -> Position
moveLeft ({ line, column } as position) lines =
    if isStartOfDocument position then
        position

    else if isFirstColumn column then
        let
            line_ : Int
            line_ =
                previousLine line
        in
        { line = line_
        , column = lastColumn lines line_
        }

    else
        { line = line
        , column = column - 1
        }


moveRight : Position -> Array String -> Position
moveRight ({ line, column } as position) lines =
    if isEndOfDocument lines position then
        position

    else if isLastColumn lines line column then
        { line = nextLine lines line
        , column = 0
        }

    else
        { line = line
        , column = column + 1
        }


startOfDocument : Position
startOfDocument =
    { line = 0
    , column = 0
    }


endOfDocument : Array String -> Position
endOfDocument lines =
    { line = lastLine lines
    , column = lastColumn lines (lastLine lines)
    }


isStartOfDocument : Position -> Bool
isStartOfDocument { line, column } =
    isFirstLine line
        && isFirstColumn column


isEndOfDocument : Array String -> Position -> Bool
isEndOfDocument lines { line, column } =
    isLastLine lines line
        && isLastColumn lines line column


isFirstLine : Int -> Bool
isFirstLine line =
    line == 0


isLastLine : Array String -> Int -> Bool
isLastLine lines line =
    line == lastLine lines


isFirstColumn : Int -> Bool
isFirstColumn column =
    column == 0


isLastColumn : Array String -> Int -> Int -> Bool
isLastColumn lines line column =
    column == lastColumn lines line


lastLine : Array String -> Int
lastLine lines =
    Array.length lines - 1


previousLine : Int -> Int
previousLine line =
    (line - 1)
        |> max 0


nextLine : Array String -> Int -> Int
nextLine lines line =
    (line + 1)
        |> min (maxLine lines)


maxLine : Array String -> Int
maxLine lines =
    Array.length lines - 1


lastColumn : Array String -> Int -> Int
lastColumn lines line =
    lineLength lines line


clampColumn : Array String -> Int -> Int -> Int
clampColumn lines line column =
    column
        |> clamp 0 (lineLength lines line)


lineContent : Array String -> Int -> String
lineContent lines lineNum =
    lines
        |> Array.get lineNum
        |> Maybe.withDefault ""


lineLength : Array String -> Int -> Int
lineLength lines lineNum =
    lineContent lines lineNum
        |> String.length


view : Config -> Model -> Html Msg
view ({ isDisabled } as config) model =
    H.div
        ([ HA.style "display" "flex"
         , HA.style "flex-direction" "row"
         , HA.style "font-family" "monospace"
         , HA.style "font-size" (String.fromFloat fontSize ++ "px")
         , HA.style "line-height" (String.fromFloat lineHeight ++ "px")
         , HA.style "white-space" "pre"
         , HA.style "flex" "1"
         , HA.tabindex 0
         , HA.class "editor"
         ]
            ++ (if isDisabled then
                    []

                else
                    [ HE.on "keydown" keyDecoder ]
               )
        )
        [ viewLineNumbers config model
        , viewContent config model
        ]


viewLineNumbers : Config -> Model -> Html Msg
viewLineNumbers { isDisabled } model =
    H.div
        [ HA.style "width" "2em"
        , HA.style "text-align" "center"
        , HA.style "color" "#888"
        , HA.style "display" "flex"
        , HA.style "flex-direction" "column"
        ]
        (if isDisabled then
            []

         else
            List.range 1 (Array.length model.lines)
                |> List.map viewLineNumber
        )


viewLineNumber : Int -> Html Msg
viewLineNumber n =
    H.span [] [ H.text (String.fromInt n) ]


viewContent : Config -> Model -> Html Msg
viewContent ({ isDisabled } as config) model =
    H.div
        ([ HA.style "position" "relative"
         , HA.style "flex" "1"
         , HA.style "background-color" "#f0f0f0"
         , HA.style "user-select" "none"
         ]
            ++ (if isDisabled then
                    []

                else
                    [ HE.onClick GoToHoveredPosition
                    , HE.onMouseOut (Hover NoHover)
                    ]
               )
        )
        [ viewLines config model.position model.hover model.lines ]


viewLines : Config -> Position -> Hover -> Array String -> Html Msg
viewLines config position hover lines =
    H.div []
        (lines
            |> Array.indexedMap (viewLine config position hover lines)
            |> Array.toList
        )


viewLine : Config -> Position -> Hover -> Array String -> Int -> String -> Html Msg
viewLine ({ isDisabled } as config) position hover lines line content =
    H.div
        ([ HA.style "position" "absolute"
         , HA.style "left" "0"
         , HA.style "right" "0"
         , HA.style "height" (String.fromFloat lineHeight ++ "px")
         , HA.style "top" (String.fromFloat (toFloat line * lineHeight) ++ "px")
         ]
            ++ (if isDisabled then
                    []

                else
                    [ HE.onMouseOver (Hover (HoverLine line)) ]
               )
        )
        (if position.line == line && isLastColumn lines line position.column then
            viewChars config position hover lines line content
                ++ [ viewCursor config position nbsp ]

         else
            viewChars config position hover lines line content
        )


viewChars : Config -> Position -> Hover -> Array String -> Int -> String -> List (Html Msg)
viewChars config position hover lines line content =
    content
        |> String.toList
        |> List.indexedMap (viewChar config position hover lines line)


viewChar : Config -> Position -> Hover -> Array String -> Int -> Int -> Char -> Html Msg
viewChar ({ isDisabled } as config) position hover lines line column char =
    if position.line == line && position.column == column then
        viewCursor config position (String.fromChar char)

    else
        H.span
            (if isDisabled then
                []

             else
                [ onHover { line = line, column = column } ]
            )
            [ H.text (String.fromChar char) ]


nbsp : String
nbsp =
    "\u{00A0}"


viewCursor : Config -> Position -> String -> Html Msg
viewCursor { isDisabled } position char =
    H.span
        (if isDisabled then
            []

         else
            [ HA.style "background-color" "orange"
            , onHover position
            ]
        )
        [ H.text char ]


onHover : Position -> Attribute Msg
onHover position =
    HE.custom "mouseover"
        (JD.succeed
            { message = Hover (HoverChar position)
            , stopPropagation = True
            , preventDefault = True
            }
        )


fontSize : Float
fontSize =
    14


lineHeight : Float
lineHeight =
    fontSize * 1.25
