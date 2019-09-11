module Main exposing (main)

import App exposing (..)
import Browser
import Types exposing (..)
import View exposing (view)


main : Program () Model Msg
main =
    Browser.document
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }
