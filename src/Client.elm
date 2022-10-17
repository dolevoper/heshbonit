module Client exposing (Client, fromJson)

import Json.Decode as D exposing (Decoder, Value)


type alias Client =
    { email : String
    , name : String
    , id : Maybe String
    , address : Maybe String
    , phone : Maybe String
    }


decoder : Decoder Client
decoder =
    D.map5 Client
        (D.field "email" D.string)
        (D.field "name" D.string)
        (D.maybe <| D.field "id" D.string)
        (D.maybe <| D.field "address" D.string)
        (D.maybe <| D.field "phone" D.string)


fromJson : Value -> Result String Client
fromJson =
    D.decodeValue decoder >> Result.mapError D.errorToString
