module Main exposing (main)

import Browser
import Date exposing (Date, date, toDataString, toShortString)
import Dict exposing (Dict)
import Html exposing (Html, article, button, h1, h2, h3, h4, main_, p, span, table, td, text, time, tr)
import Html.Attributes exposing (datetime)
import Html.Events exposing (onClick)


type alias InvoiceData =
    { business : { name : String, id : String }
    , date : Result String Date
    , amount : Float
    , description : String
    }


type alias Invoices =
    Dict Int InvoiceData


type Model
    = Home Invoices
    | Invoice Invoices Int


init : Model
init =
    Home <|
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
    = ShowInvoice Int
    | CloseInvoice


update : Msg -> Model -> Model
update msg model =
    case (model, msg) of
        (Home invoices, ShowInvoice num) ->
            Invoice invoices num
        (Invoice invoices _, CloseInvoice) ->
            Home invoices
        _ -> model


view : Model -> Html Msg
view model =
    case model of
        Home invoices ->
            viewHome invoices

        Invoice invoices num ->
            viewInvoice num <| Dict.get num invoices


viewHome : Invoices -> Html Msg
viewHome invoices =
    let
        invoiceRow : Int -> InvoiceData -> List (Html Msg) -> List (Html Msg)
        invoiceRow num invoice res =
            tr []
                [ td [] [ "#" ++ String.fromInt num |> text ]
                , td [] [ viewDate invoice.date ]
                , td [] [ text invoice.description ]
                , td [] [ String.fromFloat invoice.amount ++ "₪" |> text ]
                , td [] [ button [ onClick <| ShowInvoice num ] [ text "👁️\u{200D}🗨️" ] ]
                ]
                :: res
    in
    main_ []
        [ h1 [] [ text "קבלות" ]
        , table [] <| Dict.foldr invoiceRow [] invoices
        ]


viewInvoice : Int -> Maybe InvoiceData -> Html Msg
viewInvoice num maybeInvoice =
    case maybeInvoice of
        Nothing ->
            p [] [ text ("אופס, לא מצאתי חשבונית עם מספר " ++ String.fromInt num) ]

        Just invoice ->
            article []
                [ h1 [] [ text invoice.business.name, button [ onClick CloseInvoice ] [ text "❌" ] ]
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
