module Route exposing (Route(..), fromUrl)

import Url exposing (Url)
import Url.Parser exposing ((</>), Parser, int, map, oneOf, parse, s, top)


type Route
    = Home
    | Invoice Int


parser : Parser (Route -> a) a
parser =
    oneOf
        [ map Home top
        , map Invoice (s "invoice" </> int)
        ]


fromUrl : Url -> Maybe Route
fromUrl =
    parse parser
