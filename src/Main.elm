port module Main exposing (main)

import Browser
import Browser.Navigation exposing (Key, load, pushUrl)
import Css exposing (absolute, alignItems, backgroundColor, border3, borderRadius, color, column, displayFlex, flexDirection, flexGrow, height, left, listStyle, marginBottom, none, num, padding, pct, position, px, relative, rgb, solid)
import Date exposing (Date, toDataString, toShortString)
import DesignTokens exposing (elevation)
import Html.Styled as Styled exposing (..)
import Html.Styled.Attributes exposing (attribute, css, datetime, href, src)
import Html.Styled.Events exposing (onClick)
import Invoices as Invoices exposing (InvoiceData, Invoices, invoicesReceiver)
import Invoices.Status as Status
import Json.Decode
import LoggedInUser exposing (LoggedInUser, userLoggedIn)
import Pages.CreateInvoice
import Pages.CreateUser
import Route
import Url exposing (Url)
import UserData exposing (UserData, setUserData, userDataReceiver)
import Pages.CreateClient


port signOut : () -> Cmd msg


port registerUser : String -> Cmd msg


port downloadInvoice : Int -> Cmd msg


port firebaseError : (String -> msg) -> Sub msg


type alias Session =
    { navKey : Key
    , uid : String
    , userData : Maybe UserData
    , invoices : Maybe Invoices
    , loggedInUser : Maybe LoggedInUser
    }


type Model
    = Home Session
    | Invoice Session Int
    | CreateInvoice Session Pages.CreateInvoice.Model
    | CreateUser Session Model Pages.CreateUser.Model
    | CreateClient Session Pages.CreateClient.Model
    | NotFound Session
    | Error Session String


session : Model -> Session
session model =
    case model of
        Home s ->
            s

        Invoice s _ ->
            s

        CreateInvoice s _ ->
            s

        CreateUser s _ _ ->
            s

        CreateClient s _ ->
            s

        NotFound s ->
            s

        Error s _ ->
            s


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url
    | ReceviedUserData Json.Decode.Value
    | ReceivedInvoices Json.Decode.Value
    | UserLoggedIn Json.Decode.Value
    | SignOut
    | FirebaseError String
    | NewInvoice InvoiceData
    | CreateInvoiceMsg Pages.CreateInvoice.Msg
    | CreateUserMsg Pages.CreateUser.Msg
    | CreateClientMsg Pages.CreateClient.Msg
    | UserCreated UserData
    | DownloadInvoice


handleCreateInvoiceMsg : Pages.CreateInvoice.Msg -> Msg
handleCreateInvoiceMsg =
    Pages.CreateInvoice.mapMsg CreateInvoiceMsg NewInvoice


fromUrl : Session -> Url -> ( Model, Cmd Msg )
fromUrl s url =
    let
        buildCommands : String -> List (Cmd Msg) -> Cmd Msg
        buildCommands uid extraCommands =
            case ( extraCommands, s.invoices ) of
                ( [], Nothing ) ->
                    registerUser uid

                ( _, Nothing ) ->
                    Cmd.batch <| registerUser uid :: extraCommands

                ( [], _ ) ->
                    Cmd.none

                ( [ cmd ], _ ) ->
                    cmd

                ( _, _ ) ->
                    Cmd.batch extraCommands
    in
    case Route.fromUrl url of
        Nothing ->
            ( NotFound s, Cmd.none )

        Just route ->
            case route of
                Route.Home uid ->
                    ( Home s, buildCommands uid [] )

                Route.Invoice uid num ->
                    ( Invoice s num, buildCommands uid [] )

                Route.CreateInvoice uid ->
                    Tuple.mapBoth
                        (CreateInvoice s)
                        (Cmd.map handleCreateInvoiceMsg >> List.singleton >> buildCommands uid)
                        (Pages.CreateInvoice.init uid)

                Route.CreateClient uid ->
                    ( CreateClient s <| Pages.CreateClient.init uid, buildCommands uid [] )


init : () -> Url -> Key -> ( Model, Cmd Msg )
init _ url key =
    let
        emptySession : Session
        emptySession =
            Session key (Maybe.withDefault "" <| Route.uidFromUrl url) Nothing Nothing Nothing
    in
    fromUrl emptySession url


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        currentSession : Session
        currentSession =
            session model

        setSession : Session -> Model -> Model
        setSession s m =
            case m of
                Home _ ->
                    Home s

                Invoice _ n ->
                    Invoice s n

                CreateInvoice _ f ->
                    CreateInvoice s f

                CreateUser _ pm im ->
                    CreateUser s pm im

                CreateClient _ f ->
                    CreateClient s f

                NotFound _ ->
                    NotFound s

                Error _ err ->
                    Error s err
    in
    case ( model, msg ) of
        ( _, LinkClicked urlRequest ) ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, pushUrl currentSession.navKey <| Url.toString url )

                Browser.External href ->
                    ( model, load href )

        ( _, UrlChanged url ) ->
            fromUrl currentSession url

        ( _, ReceviedUserData v ) ->
            case UserData.fromJson v of
                Err str ->
                    ( Error currentSession str, Cmd.none )

                Ok Nothing ->
                    ( CreateUser currentSession model Pages.CreateUser.init, Cmd.none )

                Ok userData ->
                    ( setSession { currentSession | userData = userData } model, Cmd.none )

        ( _, ReceivedInvoices v ) ->
            case Invoices.fromJson v of
                Err str ->
                    ( Error currentSession str, Cmd.none )

                Ok i ->
                    ( setSession { currentSession | invoices = Just i } model, Cmd.none )

        ( _, SignOut ) ->
            ( model, signOut () )

        ( _, FirebaseError err ) ->
            ( Error currentSession err, Cmd.none )

        ( _, UserLoggedIn value ) ->
            case LoggedInUser.fromJson value of
                Err err ->
                    ( Error currentSession err, Cmd.none )

                Ok loggedInUser ->
                    ( setSession { currentSession | loggedInUser = Just loggedInUser } model, Cmd.none )

        ( CreateInvoice s m, CreateInvoiceMsg msg_ ) ->
            ( CreateInvoice s <| Pages.CreateInvoice.update msg_ m, Cmd.none )

        ( CreateClient s m, CreateClientMsg msg_ ) ->
            ( CreateClient s <| Pages.CreateClient.update msg_ m, Cmd.none )

        ( CreateInvoice _ _, NewInvoice m ) ->
            case currentSession.invoices of
                Nothing ->
                    ( model, Cmd.none )

                Just i ->
                    Invoices.create m i
                        |> Tuple.mapBoth
                            (\ni -> setSession { currentSession | invoices = Just ni } model)
                            (List.singleton >> (++) [ pushUrl currentSession.navKey <| Route.home currentSession.uid ] >> Cmd.batch)

        ( Invoice _ num, DownloadInvoice ) ->
            ( model, downloadInvoice num )

        ( CreateUser _ pm m, CreateUserMsg msg_ ) ->
            ( CreateUser currentSession pm <| Pages.CreateUser.update msg_ m, Cmd.none )

        ( CreateUser _ pm _, UserCreated userData ) ->
            ( setSession { currentSession | userData = Just userData } pm, setUserData userData )

        ( _, CreateInvoiceMsg _ ) ->
            ( model, Cmd.none )

        ( _, CreateClientMsg _ ) ->
            ( model, Cmd.none )

        ( _, NewInvoice _ ) ->
            ( model, Cmd.none )

        ( _, DownloadInvoice ) ->
            ( model, Cmd.none )

        ( _, CreateUserMsg _ ) ->
            ( model, Cmd.none )

        ( _, UserCreated _ ) ->
            ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ userDataReceiver ReceviedUserData
        , invoicesReceiver ReceivedInvoices
        , firebaseError FirebaseError
        , userLoggedIn UserLoggedIn
        ]


view : Model -> Browser.Document Msg
view model =
    { title = "חשבונית"
    , body = [ viewHeader <| .loggedInUser <| session model, viewMain model ] |> List.map toUnstyled
    }


viewHeader : Maybe LoggedInUser -> Html Msg
viewHeader loggedInUser =
    let
        accountDetails : Html Msg
        accountDetails =
            case loggedInUser of
                Nothing ->
                    section [] [ span [] [ text "טוען..." ] ]

                Just data ->
                    details [ css [ position relative ] ]
                        [ summary [ css [ listStyle none, borderRadius (pct 50), border3 (px 2) solid (rgb 0 0 0), padding (px 1) ] ]
                            [ img
                                [ src data.photoUrl
                                , attribute "referrerpolicy" "no-referrer"
                                , css [ borderRadius (pct 50), height (Css.em 2) ]
                                ]
                                []
                            ]
                        , ul [ css [ position absolute, left (px 0), elevation.medium, borderRadius (px 2), padding (Css.em 1), backgroundColor (rgb 255 255 255), listStyle none ] ]
                            [ li [ css [ displayFlex, flexDirection column, alignItems Css.center, marginBottom (Css.em 1) ] ]
                                [ b [] [ text data.displayName ]
                                , span [ css [ color (rgb 140 140 140) ] ] [ text data.email ]
                                ]
                            , li [] [ button [ onClick SignOut ] [ text "התנתק" ] ]
                            ]
                        ]
    in
    header [ css [ displayFlex, alignItems Css.center, padding (Css.em 1), elevation.medium ] ]
        [ h1 [ css [ flexGrow (num 1) ] ] [ text "חשבונית" ]
        , accountDetails
        ]


viewMain : Model -> Html Msg
viewMain model =
    let
        loading : Html Msg
        loading =
            main_ [] [ p [] [ text "טוען..." ] ]

        handleUserData : (UserData -> Html Msg) -> Maybe UserData -> Html Msg
        handleUserData v =
            Maybe.withDefault loading << Maybe.map v
    in
    case model of
        Home { uid, invoices } ->
            viewHome uid invoices

        Invoice { uid, invoices, userData } num ->
            handleUserData (viewInvoice uid num invoices) userData

        CreateInvoice { invoices } m ->
            Pages.CreateInvoice.view invoices m |> Styled.map handleCreateInvoiceMsg

        CreateClient _ m ->
            Pages.CreateClient.view m |> Styled.map CreateClientMsg

        CreateUser _ _ m ->
            Pages.CreateUser.view m |> Styled.map (Pages.CreateUser.mapMsg CreateUserMsg UserCreated)

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


viewInvoice : String -> Int -> Maybe Invoices -> UserData -> Html Msg
viewInvoice uid num invoices userData =
    let
        maybeInvoice =
            Maybe.andThen (Invoices.get num) invoices
    in
    main_ [] <|
        [ h2 [] [ text userData.name, a [ href <| Route.home uid ] [ text "❌" ] ]
        , h3 [] [ "עוסק פטור " ++ userData.id |> text ]
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
                        ]
                            ++ (if invoice.status == Status.Created then
                                    [ button [ onClick DownloadInvoice ] [ text "⬇️" ]
                                    ]

                                else
                                    []
                               )
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
