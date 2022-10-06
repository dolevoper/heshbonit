port module UserData exposing (UserData, fromJson, setUserData, userDataReceiver)

import Json.Decode as Json


port userDataReceiver : (Json.Value -> msg) -> Sub msg


port setUserData : UserData -> Cmd msg


type alias UserData =
    { name : String
    , id : String
    }


decoder : Json.Decoder (Maybe UserData)
decoder =
    Json.maybe <|
        Json.map2 UserData
            (Json.field "name" Json.string)
            (Json.field "id" Json.string)


fromJson : Json.Value -> Result String (Maybe UserData)
fromJson =
    Json.decodeValue decoder >> Result.mapError Json.errorToString
