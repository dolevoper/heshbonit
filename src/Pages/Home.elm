module Pages.Home exposing (view)

import Date
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (href)
import Invoices exposing (InvoiceData)
import Route
import Session exposing (Session)


view : Session -> Html msg
view session =
    let
        invoiceRow : Int -> InvoiceData -> Html msg
        invoiceRow num invoice =
            tr []
                [ td [] [ "#" ++ String.fromInt num |> text ]
                , td [] [ Date.view invoice.date ]
                , td [] [ text invoice.description ]
                , td [] [ String.fromFloat invoice.amount ++ "₪" |> text ]
                , td [] [ a [ href <| Route.invoice session.uid num ] [ text "👁️\u{200D}🗨️" ] ]
                ]
    in
    main_ []
        [ h2 [] [ text "קבלות" ]
        , a [ href <| Route.createInvoice session.uid ] [ text "➕" ]
        , case ( session.invoices, Maybe.map Invoices.isEmpty session.invoices ) of
            ( Just _, Just True ) ->
                p [] [ text "לא נוצרו קבלות עדיין." ]

            ( Just i, _ ) ->
                table [] <| Invoices.toList invoiceRow i

            ( Nothing, _ ) ->
                p [] [ text "טוען..." ]
        ]
