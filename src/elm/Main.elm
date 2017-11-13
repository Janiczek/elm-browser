port module Main exposing (main)

import Ports
import Html as H exposing (Html)
import Html.Events as HE
import Types exposing (..)


main : Program Never Model Msg
main =
    H.program
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
                    ( { model | project = Just { rootPath = path } }
                    , Cmd.none
                    )

                NoProjectPathChosen ->
                    ( model, Cmd.none )

        LogError err ->
            ( model
            , Ports.sendMsgForElectron (ErrorLogRequested err)
            )


subscriptions : Model -> Sub Msg
subscriptions model =
    Ports.getMsgForElm MsgForElm LogError


view : Model -> Html Msg
view model =
    H.div []
        [ viewMaybeProject model.project
        , viewDebug model
        ]


viewMaybeProject : Maybe Project -> Html Msg
viewMaybeProject maybeProject =
    maybeProject
        |> Maybe.map viewProject
        |> Maybe.withDefault viewNoProject


viewNoProject : Html Msg
viewNoProject =
    H.div []
        [ H.text "No project open"
        , H.button
            [ HE.onClick AskForProject ]
            [ H.text "Open project" ]
        ]


viewProject : Project -> Html Msg
viewProject project =
    H.div []
        [ H.text <| "Open project: " ++ project.rootPath
        , H.button
            [ HE.onClick CloseProject ]
            [ H.text "Close project" ]
        ]


viewDebug : Model -> Html Msg
viewDebug model =
    model
        |> toString
        |> H.text
