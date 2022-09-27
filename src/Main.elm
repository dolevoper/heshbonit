module Main exposing (main)

import Browser
import Browser.Navigation exposing (Key, load, pushUrl)
import Date exposing (Date, date, toDataString, toShortString)
import Dict exposing (Dict)
import Html exposing (Html, a, article, br, button, h1, h2, h3, h4, main_, p, span, table, td, text, time, tr)
import Html.Attributes exposing (datetime, href)
import Html.Events exposing (onClick)
import Route as Route exposing (Route)
import Url exposing (Url)
import Url.Builder


type alias InvoiceData =
    { date : Result String Date
    , amount : Float
    , description : String
    }


type alias Invoices =
    Dict Int InvoiceData


type Model
    = Home Key Invoices
    | Invoice Key Invoices Int
    | NotFound Key Invoices


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url


fromUrl : Key -> Invoices -> Url -> Model
fromUrl navKey invoices url =
    case Route.fromUrl url of
        Nothing ->
            NotFound navKey invoices

        Just route ->
            case route of
                Route.Home ->
                    Home navKey invoices

                Route.Invoice num ->
                    Invoice navKey invoices num


init : () -> Url -> Key -> ( Model, Cmd Msg )
init _ url key =
    let
        invoices =
            Dict.fromList
                [ ( 40001
                  , { date = date { day = 25, month = 9, year = 2022 }
                    , amount = 150
                    , description = "שיעור"
                    }
                  )
                , ( 40002
                  , { date = date { day = 25, month = 9, year = 2022 }
                    , amount = 150
                    , description = "שיעור"
                    }
                  )
                ]
    in
    ( fromUrl key invoices url
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        navKey =
            case model of
                Home key _ ->
                    key

                Invoice key _ _ ->
                    key

                NotFound key _ ->
                    key

        invoices =
            case model of
                Home _ i ->
                    i

                Invoice _ i _ ->
                    i

                NotFound _ i ->
                    i
    in
    case ( model, msg ) of
        ( _, LinkClicked urlRequest ) ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, pushUrl navKey <| Url.toString url )

                Browser.External href ->
                    ( model, load href )

        ( _, UrlChanged url ) ->
            ( fromUrl navKey invoices url
            , Cmd.none
            )



-- _ ->
--     ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


view : Model -> Browser.Document Msg
view model =
    { title = "חשבונית"
    , body = [ viewMain model ]
    }


viewMain : Model -> Html Msg
viewMain model =
    case model of
        Home _ invoices ->
            viewHome invoices

        Invoice _ invoices num ->
            viewInvoice num <| Dict.get num invoices

        NotFound _ _ ->
            viewNotFound "הדף שחיפשת לא קיים."


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
                , td [] [ a [ href <| Url.Builder.absolute [ "invoice", String.fromInt num ] [] ] [ text "👁️\u{200D}🗨️" ] ]
                ]
                :: res
    in
    main_ []
        [ h1 [] [ text "קבלות" ]
        , table [] <| Dict.foldl invoiceRow [] invoices
        ]


viewInvoice : Int -> Maybe InvoiceData -> Html Msg
viewInvoice num maybeInvoice =
    case maybeInvoice of
        Nothing ->
            viewNotFound ("אופס, לא מצאתי חשבונית עם מספר " ++ String.fromInt num)

        Just invoice ->
            main_ []
                [ h1 [] [ text "אדווה דולב", a [ href <| Url.Builder.absolute [] [] ] [ text "❌" ] ]
                , h2 [] [ "עוסק פטור 201637691" |> text ]
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


viewNotFound : String -> Html Msg
viewNotFound msg =
    main_ [] [ p [] [ text msg, br [] [], a [ href <| Url.Builder.absolute [] [] ] [ text "חזרה לדף הראשי" ] ] ]


main : Program () Model Msg
main =
    Browser.application { init = init, update = update, subscriptions = subscriptions, onUrlChange = UrlChanged, onUrlRequest = LinkClicked, view = view }
