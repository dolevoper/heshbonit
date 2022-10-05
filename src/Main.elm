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
import UserData exposing (UserData)


port signOut : () -> Cmd msg


port downloadInvoice : Int -> Cmd msg


port firebaseError : (String -> msg) -> Sub msg


type alias Session =
    { navKey : Key
    , uid : String
    , userData : Maybe UserData
    , invoices : Maybe Invoices
    }


type Model
    = Home Session
    | Invoice Session Int
    | CreateInvoice Session Pages.CreateInvoice.Model
    | NotFound Session
    | Error Session String


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url
    | ReceivedInvoices Json.Decode.Value
    | SignOut
    | FirebaseError String
    | NewInvoice InvoiceData
    | CreateInvoiceMsg Pages.CreateInvoice.Msg
    | DownloadInvoice


handleCreateInvoiceMsg : Pages.CreateInvoice.Msg -> Msg
handleCreateInvoiceMsg =
    Pages.CreateInvoice.mapMsg CreateInvoiceMsg NewInvoice


fromUrl : Session -> Url -> ( Model, Cmd Msg )
fromUrl session url =
    let
        buildCommands : String -> List (Cmd Msg) -> Cmd Msg
        buildCommands uid extraCommands =
            case ( extraCommands, session.invoices ) of
                ( [], Nothing ) ->
                    Invoices.registerInvoices uid

                ( _, Nothing ) ->
                    Cmd.batch <| Invoices.registerInvoices uid :: extraCommands

                ( [], _ ) ->
                    Cmd.none

                ( [ cmd ], _ ) ->
                    cmd

                ( _, _ ) ->
                    Cmd.batch extraCommands
    in
    case Route.fromUrl url of
        Nothing ->
            ( NotFound session, Cmd.none )

        Just route ->
            case route of
                Route.Home uid ->
                    ( Home session, buildCommands uid [] )

                Route.Invoice uid num ->
                    ( Invoice session num, buildCommands uid [] )

                Route.CreateInvoice uid ->
                    Tuple.mapBoth
                        (CreateInvoice session)
                        (Cmd.map handleCreateInvoiceMsg >> List.singleton >> buildCommands uid)
                        (Pages.CreateInvoice.init uid)


init : () -> Url -> Key -> ( Model, Cmd Msg )
init _ url key =
    let
        session : Session
        session = Session key (Maybe.withDefault "" <| Route.uidFromUrl url) Nothing Nothing
    in
    fromUrl session url


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        session : Session
        session =
            case model of
                Home s ->
                    s

                Invoice s _ ->
                    s

                CreateInvoice s _ ->
                    s

                NotFound s ->
                    s

                Error s _ ->
                    s

        setSession : Session -> Model -> Model
        setSession s m =
            case m of
                Home _ ->
                    Home s

                Invoice _ n ->
                    Invoice s n

                CreateInvoice _ f ->
                    CreateInvoice s f

                NotFound _ ->
                    NotFound s

                Error _ err ->
                    Error s err
    in
    case ( model, msg ) of
        ( _, LinkClicked urlRequest ) ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, pushUrl session.navKey <| Url.toString url )

                Browser.External href ->
                    ( model, load href )

        ( _, UrlChanged url ) ->
            fromUrl session url

        ( _, ReceivedInvoices v ) ->
            case Invoices.fromJson v of
                Err str ->
                    ( Error session str, Cmd.none )

                Ok i ->
                    ( setSession { session | invoices = Just i } model, Cmd.none )

        ( _, SignOut ) ->
            ( model, signOut () )

        ( _, FirebaseError err ) ->
            ( Error session err, Cmd.none )

        ( CreateInvoice s m, CreateInvoiceMsg msg_ ) ->
            ( CreateInvoice s <| Pages.CreateInvoice.update msg_ m, Cmd.none )

        ( CreateInvoice _ _, NewInvoice m ) ->
            case session.invoices of
                Nothing ->
                    ( model, Cmd.none )

                Just i ->
                    Invoices.create m i
                        |> Tuple.mapBoth
                            (\ni -> setSession { session | invoices = Just ni } model)
                            (List.singleton >> (++) [ pushUrl session.navKey <| Route.home session.uid ] >> Cmd.batch)

        ( Invoice _ num, DownloadInvoice ) ->
            ( model, downloadInvoice num )

        ( _, CreateInvoiceMsg _ ) ->
            ( model, Cmd.none )

        ( _, NewInvoice _ ) ->
            ( model, Cmd.none )

        ( _, DownloadInvoice ) ->
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
        Home { uid, invoices } ->
            viewHome uid invoices

        Invoice { uid, invoices } num ->
            viewInvoice uid num invoices

        CreateInvoice { invoices } m ->
            Pages.CreateInvoice.view invoices m |> Html.map handleCreateInvoiceMsg

        NotFound { uid } ->
            main_ [] <| viewNotFound uid "הדף שחיפשת לא קיים."

        Error _ str ->
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
                        viewNotFound uid ("אופס, לא מצאתי חשבונית עם מספר " ++ String.fromInt num)

                    ( _, Just invoice ) ->
                        [ p [] [ h4 [] [ text "עבור" ], text invoice.description ]
                        , p [] [ "סה\"כ: " ++ String.fromFloat invoice.amount ++ "₪" |> text ]
                        , viewDate invoice.date
                        , button [ onClick DownloadInvoice ] [ text "⬇️" ]
                        ]
               )


viewDate : Result String Date -> Html Msg
viewDate rd =
    case rd of
        Ok d ->
            time [ toDataString d |> datetime ] [ toShortString d |> text ]

        Err _ ->
            span [] [ text "INVALID DATE" ]


viewNotFound : String -> String -> List (Html Msg)
viewNotFound uid msg =
    [ p [] [ text msg, br [] [], a [ href <| Route.home <| uid ] [ text "חזרה לדף הראשי" ] ] ]


main : Program () Model Msg
main =
    Browser.application { init = init, update = update, subscriptions = subscriptions, onUrlChange = UrlChanged, onUrlRequest = LinkClicked, view = view }
