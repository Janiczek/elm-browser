module Main exposing (main)

import App exposing (..)
import Html
import View exposing (view)
import Types exposing (..)


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }
