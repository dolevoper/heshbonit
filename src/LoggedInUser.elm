port module LoggedInUser exposing (LoggedInUser, fromJson, userLoggedIn)

import Json.Decode as Json exposing (Decoder)


port userLoggedIn : (Json.Value -> msg) -> Sub msg


type alias LoggedInUser =
    { displayName : String
    , email : String
    , photoUrl : String
    }


decoder : Decoder LoggedInUser
decoder =
    Json.map3 LoggedInUser
        (Json.field "displayName" Json.string)
        (Json.field "email" Json.string)
        (Json.field "photoURL" Json.string)


fromJson : Json.Value -> Result String LoggedInUser
fromJson =
    Json.decodeValue decoder >> Result.mapError Json.errorToString
