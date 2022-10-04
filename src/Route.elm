module Route exposing (Route(..), createInvoice, fromUrl, home, invoice, uid)

import Url exposing (Url)
import Url.Builder
import Url.Parser exposing ((</>), Parser, int, map, oneOf, parse, s, string)


type Route
    = Home String
    | Invoice String Int
    | CreateInvoice String


parser : Parser (Route -> a) a
parser =
    oneOf
        [ map Home string
        , map Invoice (string </> s "invoice" </> int)
        , map CreateInvoice (string </> s "createInvoice")
        ]


fromUrl : Url -> Maybe Route
fromUrl =
    parse parser


home : String -> String
home u =
    Url.Builder.absolute [ u ] []


invoice : String -> Int -> String
invoice u invoiceId =
    Url.Builder.absolute [ u, "invoice", String.fromInt invoiceId ] []


createInvoice : String -> String
createInvoice u =
    Url.Builder.absolute [ u, "createInvoice" ] []


uid : Url -> Maybe String
uid url =
    String.split "/" url.path |> List.drop 1 |> List.head
