module Main exposing (main)

import Browser
import Date exposing (Date, date, toDataString, toShortString)
import Dict exposing (Dict)
import Html exposing (Html, article, button, h1, h2, h3, h4, main_, p, span, table, td, text, time, tr)
import Html.Attributes exposing (datetime)


type alias InvoiceData =
    { business : { name : String, id : String }
    , date : Result String Date
    , amount : Float
    , description : String
    }


type alias Invoices =
    Dict Int InvoiceData


type alias Model =
    Invoices


init : Model
init =
    Dict.fromList
        [ ( 40001
          , { business = { name = "אדווה דולב", id = "201637691" }
            , date = date { day = 25, month = 9, year = 2022 }
            , amount = 150
            , description = "שיעור"
            }
          )
        , ( 40002
          , { business = { name = "אדווה דולב", id = "201637691" }
            , date = date { day = 25, month = 9, year = 2022 }
            , amount = 150
            , description = "שיעור"
            }
          )
        ]


type Msg
    = Increment
    | Decrement


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
        invoiceRow : Int -> InvoiceData -> List (Html Msg) -> List (Html Msg)
        invoiceRow num invoice res =
            tr []
                [ td [] [ "#" ++ String.fromInt num |> text ]
                , td [] [ viewDate invoice.date ]
                , td [] [ text invoice.description ]
                , td [] [ String.fromFloat invoice.amount ++ "₪" |> text ]
                , td [] [ button [] [ text "👁️\u{200D}🗨️" ] ]
                ]
                :: res
    in
    main_ []
        [ h1 [] [ text "קבלות" ]
        , table [] <| Dict.foldl invoiceRow [] model
        ]


viewInvoice : Int -> InvoiceData -> Html Msg
viewInvoice num invoice =
    article []
        [ h1 [] [ text invoice.business.name ]
        , h2 [] [ "עוסק פטור " ++ invoice.business.id |> text ]
        , h3 [] [ "קבלה מס' " ++ String.fromInt num |> text ]
        , p [] [ h4 [] [ text "עבור" ], text invoice.description ]
        , p [] [ "סה\"כ: " ++ String.fromFloat invoice.amount ++ "₪" |> text ]
        , viewDate invoice.date
        ]


viewDate : Result String Date -> Html Msg
viewDate rd =
    case rd of
        Ok d ->
            time [ toDataString d |> datetime ] [ toShortString d |> text ]

        Err _ ->
            span [] [ text "INVALID DATE" ]


main : Program () Model Msg
main =
    Browser.sandbox { init = init, update = update, view = view }
