module Main exposing (main)

import Html
import Ports
import Types exposing (..)
import View exposing (view)


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


init : ( Model, Cmd Msg )
init =
    ( { project = Nothing }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AskForProject ->
            ( model
            , Ports.sendMsgForElectron ChooseProjectPath
            )

        CloseProject ->
            ( { model | project = Nothing }
            , Cmd.none
            )

        MsgForElm msgForElm ->
            case msgForElm of
                ProjectPathChosen path ->
                    ( { model
                        | project =
                            Just
                                { rootPath = path
                                , index = Nothing
                                , selection = NothingSelected
                                }
                      }
                    , Cmd.batch
                        [ Ports.sendMsgForElectron CreateIndex
                        , Ports.sendMsgForElectron (ChangeTitle (windowTitle (Just path)))
                        ]
                    )

                NoProjectPathChosen ->
                    ( model
                    , Cmd.none
                    )

                ProjectClosed ->
                    ( { model | project = Nothing }
                    , Ports.sendMsgForElectron (ChangeTitle (windowTitle Nothing))
                    )

                IndexCreated index ->
                    ( { model
                        | project =
                            model.project
                                |> Maybe.map
                                    (\project -> { project | index = Just index })
                      }
                    , Cmd.none
                    )

        LogError err ->
            ( model
            , Ports.sendMsgForElectron (ErrorLogRequested err)
            )


subscriptions : Model -> Sub Msg
subscriptions model =
    Ports.getMsgForElm MsgForElm LogError


windowTitle : Maybe String -> String
windowTitle maybePath =
    case maybePath of
        Nothing ->
            "Elm Browser"

        Just path ->
            let
                lastDirectory =
                    path
                        |> String.split "/"
                        |> List.reverse
                        |> List.head
                        |> Maybe.withDefault path
            in
                "Elm Browser - " ++ lastDirectory
