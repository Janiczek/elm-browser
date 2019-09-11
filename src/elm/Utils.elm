module Utils exposing (..)

import AssocList as Dict exposing (Dict)
import AssocSet as Set exposing (Set)
import Json.Decode as JD exposing (Decoder)


dictKeysToSet : Dict k v -> Set k
dictKeysToSet dict =
    dict
        |> Dict.keys
        |> Set.fromList


dictValuesToSet : Dict k v -> Set v
dictValuesToSet dict =
    dict
        |> Dict.values
        |> Set.fromList


dictGetVals : Dict k v -> Set k -> List v
dictGetVals dict wantedKeys =
    dict
        |> Dict.filter (\k v -> Set.member k wantedKeys)
        |> Dict.values


dictGetKv : Dict k v -> Set k -> List ( k, v )
dictGetKv dict wantedKeys =
    dict
        |> Dict.filter (\k v -> Set.member k wantedKeys)
        |> Dict.toList


setDecoder : Decoder a -> Decoder (Set a)
setDecoder decoder =
    JD.list decoder
        |> JD.map Set.fromList
