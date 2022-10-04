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
import Url exposing (Url)


port signOut : () -> Cmd msg


port firebaseError : (String -> msg) -> Sub msg


type Model
    = Home Key String (Maybe Invoices)
    | Invoice Key String (Maybe Invoices) Int
    | CreateInvoice Key String (Maybe Invoices) Pages.CreateInvoice.Model
    | NotFound Key (Maybe String) (Maybe Invoices)
    | Error Key String String


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
            ( NotFound navKey (Route.uid url) invoices, Cmd.none )

        Just route ->
            case route of
                Route.Home uid ->
                    ( Home navKey uid invoices, Cmd.none )

                Route.Invoice uid num ->
                    ( Invoice navKey uid invoices num, Cmd.none )

                Route.CreateInvoice uid ->
                    Tuple.mapBoth
                        (CreateInvoice navKey uid invoices)
                        (Cmd.map <| handleCreateInvoiceMsg)
                        (Pages.CreateInvoice.init uid)


init : () -> Url -> Key -> ( Model, Cmd Msg )
init _ url key =
    fromUrl key Nothing url


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        navKey =
            case model of
                Home key _ _ ->
                    key

                Invoice key _ _ _ ->
                    key

                CreateInvoice key _ _ _ ->
                    key

                NotFound key _ _ ->
                    key

                Error key _ _ ->
                    key

        uid =
            case model of
                Home _ u _ ->
                    u

                Invoice _ u _ _ ->
                    u

                CreateInvoice _ u _ _ ->
                    u

                NotFound _ u _ ->
                    Maybe.withDefault "" u

                Error _ u _ ->
                    u

        invoices =
            case model of
                Home _ _ i ->
                    i

                Invoice _ _ i _ ->
                    i

                CreateInvoice _ _ i _ ->
                    i

                NotFound _ _ i ->
                    i

                Error _ _ _ ->
                    Nothing

        setInvoices : Maybe Invoices -> Model -> Model
        setInvoices i m =
            case m of
                Home k u _ ->
                    Home k u i

                Invoice k u _ n ->
                    Invoice k u i n

                CreateInvoice k u _ f ->
                    CreateInvoice k u i f

                NotFound k u _ ->
                    NotFound k u i

                Error _ _ _ ->
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
                    ( Error navKey uid str, Cmd.none )

                Ok i ->
                    ( setInvoices (Just i) model, Cmd.none )

        ( _, SignOut ) ->
            ( model, signOut () )

        ( _, FirebaseError err ) ->
            ( Error navKey uid err, Cmd.none )

        ( CreateInvoice _ _ _ m, CreateInvoiceMsg msg_ ) ->
            ( CreateInvoice navKey uid invoices <| Pages.CreateInvoice.update msg_ m, Cmd.none )

        ( CreateInvoice _ _ _ _, NewInvoice m ) ->
            case invoices of
                Nothing ->
                    ( model, Cmd.none )

                Just i ->
                    Invoices.create m i
                        |> Tuple.mapBoth
                            (\ni -> setInvoices (Just ni) model)
                            (\cmd -> Cmd.batch [ cmd, pushUrl navKey <| Route.home uid ])

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
        Home _ uid invoices ->
            viewHome uid invoices

        Invoice _ uid invoices num ->
            viewInvoice uid num invoices

        CreateInvoice _ _ invoices m ->
            Pages.CreateInvoice.view invoices m |> Html.map handleCreateInvoiceMsg

        NotFound _ uid _ ->
            main_ [] <| viewNotFound uid "הדף שחיפשת לא קיים."

        Error _ _ str ->
            main_ [] [ p [] [ text str ] ]


viewHome : String -> Maybe Invoices -> Html Msg
viewHome uid invoices =
    let
        invoiceRow : Int -> InvoiceData -> Html Msg
        invoiceRow num invoice =
            tr []
                [ td [] [ "#" ++ String.fromInt num |> text ]
                , td [] [ viewDate invoice.date ]
                , td [] [ text invoice.description ]
                , td [] [ String.fromFloat invoice.amount ++ "₪" |> text ]
                , td [] [ a [ href <| Route.invoice uid num ] [ text "👁️\u{200D}🗨️" ] ]
                ]
    in
    main_ []
        [ h2 [] [ text "קבלות" ]
        , a [ href <| Route.createInvoice uid ] [ text "➕" ]
        , case ( invoices, Maybe.map Invoices.isEmpty invoices ) of
            ( Just _, Just True ) ->
                p [] [ text "לא נוצרו קבלות עדיין." ]

            ( Just i, _ ) ->
                table [] <| Invoices.toList invoiceRow i

            ( Nothing, _ ) ->
                p [] [ text "טוען..." ]
        ]


viewInvoice : String -> Int -> Maybe Invoices -> Html Msg
viewInvoice uid num invoices =
    let
        maybeInvoice =
            Maybe.andThen (Invoices.get num) invoices
    in
    main_ [] <|
        [ h2 [] [ text "אדווה דולב", a [ href <| Route.home uid ] [ text "❌" ] ]
        , h3 [] [ "עוסק פטור 201637691" |> text ]
        , h4 [] [ "קבלה מס' " ++ String.fromInt num |> text ]
        ]
            ++ (case ( invoices, maybeInvoice ) of
                    ( Nothing, _ ) ->
                        [ p [] [ text "טוען..." ] ]

                    ( Just _, Nothing ) ->
                        viewNotFound (Just uid) ("אופס, לא מצאתי חשבונית עם מספר " ++ String.fromInt num)

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


viewNotFound : Maybe String -> String -> List (Html Msg)
viewNotFound uid msg =
    [ p [] [ text msg, br [] [], a [ href <| Route.home <| Maybe.withDefault "" uid ] [ text "חזרה לדף הראשי" ] ] ]


main : Program () Model Msg
main =
    Browser.application { init = init, update = update, subscriptions = subscriptions, onUrlChange = UrlChanged, onUrlRequest = LinkClicked, view = view }
