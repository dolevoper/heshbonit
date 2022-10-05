port module UserData exposing (UserData, fromJson, userDataReceiver)

import Json.Decode as Json


port userDataReceiver : (Json.Value -> msg) -> Sub msg


type alias UserModel =
    { name : String
    , id : String
    }


type UserData
    = UserData (Maybe UserModel)


decoder : Json.Decoder (Maybe UserModel)
decoder =
    Json.maybe <|
        Json.map2 UserModel
            (Json.field "name" Json.string)
            (Json.field "id" Json.string)


fromJson : Json.Value -> Result String UserData
fromJson =
    Json.decodeValue decoder >> Result.map UserData >> Result.mapError Json.errorToString
