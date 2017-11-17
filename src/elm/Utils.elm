module Utils exposing (..)

import EveryDict as EDict exposing (EveryDict)
import EverySet as ESet exposing (EverySet)
import Json.Decode as JD exposing (Decoder)


dictKeysToSet : EveryDict k v -> EverySet k
dictKeysToSet dict =
    dict
        |> EDict.keys
        |> ESet.fromList


dictValuesToSet : EveryDict k v -> EverySet v
dictValuesToSet dict =
    dict
        |> EDict.values
        |> ESet.fromList


dictGetVals : EveryDict k v -> EverySet k -> List v
dictGetVals dict wantedKeys =
    dict
        |> EDict.filter (\k v -> ESet.member k wantedKeys)
        |> EDict.values


dictGetKv : EveryDict k v -> EverySet k -> List ( k, v )
dictGetKv dict wantedKeys =
    dict
        |> EDict.filter (\k v -> ESet.member k wantedKeys)
        |> EDict.toList


everySetDecoder : Decoder a -> Decoder (EverySet a)
everySetDecoder decoder =
    JD.list decoder
        |> JD.map ESet.fromList
