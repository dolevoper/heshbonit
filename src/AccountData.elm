port module AccountData exposing (AccountData, fromJson, setAccountData, accountDataReceiver)

import Json.Decode as Json


port accountDataReceiver : (Json.Value -> msg) -> Sub msg


port setAccountData : AccountData -> Cmd msg


type alias AccountData =
    { name : String
    , id : String
    }


decoder : Json.Decoder (Maybe AccountData)
decoder =
    Json.maybe <|
        Json.map2 AccountData
            (Json.field "name" Json.string)
            (Json.field "id" Json.string)


fromJson : Json.Value -> Result String (Maybe AccountData)
fromJson =
    Json.decodeValue decoder >> Result.mapError Json.errorToString
