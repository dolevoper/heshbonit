module Route exposing (Route(..), createInvoice, fromUrl, home, invoice, uidFromUrl)

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
home uid =
    Url.Builder.absolute [ uid ] []


invoice : String -> Int -> String
invoice uid invoiceId =
    Url.Builder.absolute [ uid, "invoice", String.fromInt invoiceId ] []


createInvoice : String -> String
createInvoice uid =
    Url.Builder.absolute [ uid, "createInvoice" ] []


uidFromUrl : Url -> Maybe String
uidFromUrl url =
    String.split "/" url.path |> List.drop 1 |> List.head
