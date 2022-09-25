module Main exposing (main)

import Browser
import Html exposing (Html, main_, article, text, h1, h2, h3, h4, p, time, table, tr, td, button, span)
import Html.Attributes exposing (datetime)
import Date exposing (Date, date, toDataString, toShortString)

type alias Invoice =
    { num : Int
    , business : { name : String, id : String }
    , date :  Result String Date
    , amount : Float
    , description : String
    }

type alias Model = List Invoice

init : Model
init =
    [ { num = 40001
    , business = { name = "אדווה דולב", id = "201637691" }
    , date = date { day = 25, month = 9, year = 2022 }
    , amount = 150
    , description = "שיעור"
    }
    , { num = 40002
    , business = { name = "אדווה דולב", id = "201637691" }
    , date = date { day = 25, month = 9, year = 2022 }
    , amount = 150
    , description = "שיעור"
    }
    ]

type Msg = Increment | Decrement

update : Msg -> Model -> Model
update msg model =
    case msg of
        Increment ->
            model
        
        Decrement ->
            model

view : Model -> Html Msg
view model =
    let
        invoiceRow : Invoice -> Html Msg
        invoiceRow invoice = tr []
            [ td [] [ "#" ++ String.fromInt invoice.num |> text ]
            , td [] [ viewDate invoice.date ]
            , td [] [ text invoice.description ]
            , td [] [ String.fromFloat invoice.amount ++ "₪" |> text ]
            , td [] [ button [] [ text "👁️‍🗨️" ] ]
            ]
    in
    main_ []
        [ h1 [] [ text "קבלות" ]
        , table [] <| List.map invoiceRow model
        ]

viewInvoice : Invoice -> Html Msg
viewInvoice invoice =
    article []
        [ h1 [] [ text invoice.business.name ]
        , h2 [] [ "עוסק פטור " ++ invoice.business.id |> text ]
        , h3 [] [ "קבלה מס' " ++ String.fromInt invoice.num |> text]
        , p [] [ h4 [] [ text "עבור" ], text invoice.description ]
        , p [] [ "סה\"כ: " ++ String.fromFloat invoice.amount ++ "₪" |> text ]
        , viewDate invoice.date
        ]

viewDate : Result String Date -> Html Msg
viewDate rd =
    case rd of
        Ok d -> time [ toDataString d |> datetime ] [ toShortString d |> text ]
        Err _ -> span [] [ text "INVALID DATE" ]

main : Program () Model Msg
main =
    Browser.sandbox { init = init, update = update, view = view }
