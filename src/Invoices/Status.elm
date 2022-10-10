module Invoices.Status exposing (Status(..), decoder, encoder)

import Json.Decode as D exposing (Decoder, Value)
import Json.Encode as E


type Status
    = New
    | Created


const : String -> Decoder ()
const str =
    D.string
        |> D.andThen
            (\s ->
                if str == s then
                    D.succeed ()

                else
                    D.fail "bla bla"
            )


decoder : Decoder Status
decoder =
    D.oneOf
        [ D.map (always New) <| const "new"
        , D.map (always Created) <| const "created"
        ]


encoder : Status -> Value
encoder s =
    case s of
        New ->
            E.string "new"

        Created ->
            E.string "created"
