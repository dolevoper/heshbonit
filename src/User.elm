port module User exposing (User, fromJson, userLoggedIn)

import Json.Decode as Json exposing (Decoder)


port userLoggedIn : (Json.Value -> msg) -> Sub msg


type alias User =
    { displayName : String
    , email : String
    , photoUrl : String
    }


decoder : Decoder User
decoder =
    Json.map3 User
        (Json.field "displayName" Json.string)
        (Json.field "email" Json.string)
        (Json.field "photoURL" Json.string)


fromJson : Json.Value -> Result String User
fromJson =
    Json.decodeValue decoder >> Result.mapError Json.errorToString
