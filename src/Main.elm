module Main exposing (main)

import Browser
import Browser.Navigation exposing (Key, load, pushUrl)
import Date exposing (Date, date, toDataString, toShortString)
import Html exposing (Html, a, article, br, h1, h2, h3, h4, main_, p, span, table, td, text, time, tr)
import Html.Attributes exposing (datetime, href)
import Invoices as Invoices exposing (InvoiceData, Invoices, invoicesReceiver)
import Json.Decode
import Route
import Url exposing (Url)
import Url.Builder


type Model
    = Home Key (Maybe Invoices)
    | Invoice Key (Maybe Invoices) Int
    | NotFound Key (Maybe Invoices)


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url
    | ReceivedInvoices Json.Decode.Value


fromUrl : Key -> Maybe Invoices -> Url -> Model
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
    ( fromUrl key Nothing url
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

        setInvoices : Maybe Invoices -> Model -> Model
        setInvoices i m =
            case m of
                Home k _ ->
                    Home k i

                Invoice k _ n ->
                    Invoice k i n

                NotFound k _ ->
                    NotFound k i
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

        ( _, ReceivedInvoices v ) ->
            case Invoices.fromJson v of
                Err _ ->
                    ( model, Cmd.none )

                Ok i ->
                    ( setInvoices (Just i) model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    invoicesReceiver ReceivedInvoices


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
            viewInvoice num invoices

        NotFound _ _ ->
            main_ [] <| viewNotFound "הדף שחיפשת לא קיים."


viewHome : Maybe Invoices -> Html Msg
viewHome invoices =
    let
        invoiceRow : Int -> InvoiceData -> Html Msg
        invoiceRow num invoice =
            tr []
                [ td [] [ "#" ++ String.fromInt num |> text ]
                , td [] [ viewDate invoice.date ]
                , td [] [ text invoice.description ]
                , td [] [ String.fromFloat invoice.amount ++ "₪" |> text ]
                , td [] [ a [ href <| Url.Builder.absolute [ "invoice", String.fromInt num ] [] ] [ text "👁️\u{200D}🗨️" ] ]
                ]
    in
    main_ []
        [ h1 [] [ text "קבלות" ]
        , case invoices of
            Just i ->
                table [] <| Invoices.toList invoiceRow i

            Nothing ->
                p [] [ text "טוען..." ]
        ]


viewInvoice : Int -> Maybe Invoices -> Html Msg
viewInvoice num invoices =
    let
        maybeInvoice =
            Maybe.andThen (Invoices.get num) invoices
    in
    main_ [] <|
        [ h1 [] [ text "אדווה דולב", a [ href <| Url.Builder.absolute [] [] ] [ text "❌" ] ]
        , h2 [] [ "עוסק פטור 201637691" |> text ]
        , h3 [] [ "קבלה מס' " ++ String.fromInt num |> text ]
        ]
            ++ (case ( invoices, maybeInvoice ) of
                    ( Nothing, _ ) ->
                        [ p [] [ text "טוען..." ] ]

                    ( Just _, Nothing ) ->
                        viewNotFound ("אופס, לא מצאתי חשבונית עם מספר " ++ String.fromInt num)

                    ( _, Just invoice ) ->
                        [ p [] [ h4 [] [ text "עבור" ], text invoice.description ]
                        , p [] [ "סה\"כ: " ++ String.fromFloat invoice.amount ++ "₪" |> text ]
                        , viewDate invoice.date
                        ]
               )


viewDate : Result String Date -> Html Msg
viewDate rd =
    case rd of
        Ok d ->
            time [ toDataString d |> datetime ] [ toShortString d |> text ]

        Err str ->
            span [] [ text "INVALID DATE" ]


viewNotFound : String -> List (Html Msg)
viewNotFound msg =
    [ p [] [ text msg, br [] [], a [ href <| Url.Builder.absolute [] [] ] [ text "חזרה לדף הראשי" ] ] ]


main : Program () Model Msg
main =
    Browser.application { init = init, update = update, subscriptions = subscriptions, onUrlChange = UrlChanged, onUrlRequest = LinkClicked, view = view }
