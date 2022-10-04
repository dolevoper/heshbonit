port module Main exposing (main)

import Browser
import Browser.Navigation exposing (Key, load, pushUrl)
import Date exposing (Date, toDataString, toShortString)
import Html exposing (Html, a, br, button, h1, h2, h3, h4, header, main_, p, span, table, td, text, time, tr)
import Html.Attributes exposing (datetime, href)
import Html.Events exposing (onClick)
import Invoices as Invoices exposing (InvoiceData, Invoices, invoicesReceiver)
import Json.Decode
import Pages.CreateInvoice
import Route
import Task exposing (Task)
import Time
import Url exposing (Url)
import Url.Builder


port signOut : () -> Cmd msg


port firebaseError : (String -> msg) -> Sub msg


type Model
    = Home Key (Maybe Invoices)
    | Invoice Key (Maybe Invoices) Int
    | CreateInvoice Key (Maybe Invoices) Pages.CreateInvoice.Model
    | NotFound Key (Maybe Invoices)
    | Error Key String


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url
    | ReceivedInvoices Json.Decode.Value
    | SignOut
    | FirebaseError String
    | NewInvoice InvoiceData
    | CreateInvoiceMsg Pages.CreateInvoice.Msg


handleCreateInvoiceMsg : Pages.CreateInvoice.Msg -> Msg
handleCreateInvoiceMsg =
    Pages.CreateInvoice.mapMsg CreateInvoiceMsg NewInvoice


fromUrl : Key -> Maybe Invoices -> Url -> ( Model, Cmd Msg )
fromUrl navKey invoices url =
    case Route.fromUrl url of
        Nothing ->
            ( NotFound navKey invoices, Cmd.none )

        Just route ->
            case route of
                Route.Home ->
                    ( Home navKey invoices, Cmd.none )

                Route.Invoice num ->
                    ( Invoice navKey invoices num, Cmd.none )

                Route.CreateInvoice ->
                    Tuple.mapBoth
                        (CreateInvoice navKey invoices)
                        (Cmd.map <| handleCreateInvoiceMsg)
                        Pages.CreateInvoice.init


init : () -> Url -> Key -> ( Model, Cmd Msg )
init _ url key =
    fromUrl key Nothing url


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        navKey =
            case model of
                Home key _ ->
                    key

                Invoice key _ _ ->
                    key

                CreateInvoice key _ _ ->
                    key

                NotFound key _ ->
                    key

                Error key _ ->
                    key

        invoices =
            case model of
                Home _ i ->
                    i

                Invoice _ i _ ->
                    i

                CreateInvoice _ i _ ->
                    i

                NotFound _ i ->
                    i

                Error _ _ ->
                    Nothing

        setInvoices : Maybe Invoices -> Model -> Model
        setInvoices i m =
            case m of
                Home k _ ->
                    Home k i

                Invoice k _ n ->
                    Invoice k i n

                CreateInvoice k _ f ->
                    CreateInvoice k i f

                NotFound k _ ->
                    NotFound k i

                Error _ _ ->
                    m
    in
    case ( model, msg ) of
        ( _, LinkClicked urlRequest ) ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, pushUrl navKey <| Url.toString url )

                Browser.External href ->
                    ( model, load href )

        ( _, UrlChanged url ) ->
            fromUrl navKey invoices url

        ( _, ReceivedInvoices v ) ->
            case Invoices.fromJson v of
                Err str ->
                    ( Error navKey str, Cmd.none )

                Ok i ->
                    ( setInvoices (Just i) model, Cmd.none )

        ( _, SignOut ) ->
            ( model, signOut () )

        ( _, FirebaseError err ) ->
            ( Error navKey err, Cmd.none )

        ( CreateInvoice _ _ m, CreateInvoiceMsg msg_ ) ->
            ( CreateInvoice navKey invoices <| Pages.CreateInvoice.update msg_ m, Cmd.none )

        ( CreateInvoice _ _ _, NewInvoice m ) ->
            case invoices of
                Nothing ->
                    ( model, Cmd.none )

                Just i ->
                    Invoices.create m i
                        |> Tuple.mapBoth
                            (\ni -> setInvoices (Just ni) model)
                            (\cmd -> Cmd.batch [ cmd, pushUrl navKey "/" ])

        ( _, CreateInvoiceMsg _ ) ->
            ( model, Cmd.none )

        ( _, NewInvoice _ ) ->
            ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ invoicesReceiver ReceivedInvoices
        , firebaseError FirebaseError
        ]


view : Model -> Browser.Document Msg
view model =
    { title = "חשבונית"
    , body = [ viewHeader, viewMain model ]
    }


viewHeader : Html Msg
viewHeader =
    header []
        [ h1 [] [ text "חשבונית" ]
        , button [ onClick SignOut ] [ text "התנתק" ]
        ]


viewMain : Model -> Html Msg
viewMain model =
    case model of
        Home _ invoices ->
            viewHome invoices

        Invoice _ invoices num ->
            viewInvoice num invoices

        CreateInvoice _ invoices m ->
            Pages.CreateInvoice.view invoices m |> Html.map handleCreateInvoiceMsg

        NotFound _ _ ->
            main_ [] <| viewNotFound "הדף שחיפשת לא קיים."

        Error _ str ->
            main_ [] [ p [] [ text str ] ]


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
        [ h2 [] [ text "קבלות" ]
        , a [ href <| Url.Builder.absolute [ "createInvoice" ] [] ] [ text "➕" ]
        , case ( invoices, Maybe.map Invoices.isEmpty invoices ) of
            ( Just _, Just True ) ->
                p [] [ text "לא נוצרו קבלות עדיין." ]

            ( Just i, _ ) ->
                table [] <| Invoices.toList invoiceRow i

            ( Nothing, _ ) ->
                p [] [ text "טוען..." ]
        ]


viewInvoice : Int -> Maybe Invoices -> Html Msg
viewInvoice num invoices =
    let
        maybeInvoice =
            Maybe.andThen (Invoices.get num) invoices
    in
    main_ [] <|
        [ h2 [] [ text "אדווה דולב", a [ href <| Url.Builder.absolute [] [] ] [ text "❌" ] ]
        , h3 [] [ "עוסק פטור 201637691" |> text ]
        , h4 [] [ "קבלה מס' " ++ String.fromInt num |> text ]
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

        Err _ ->
            span [] [ text "INVALID DATE" ]


viewNotFound : String -> List (Html Msg)
viewNotFound msg =
    [ p [] [ text msg, br [] [], a [ href <| Url.Builder.absolute [] [] ] [ text "חזרה לדף הראשי" ] ] ]


main : Program () Model Msg
main =
    Browser.application { init = init, update = update, subscriptions = subscriptions, onUrlChange = UrlChanged, onUrlRequest = LinkClicked, view = view }
