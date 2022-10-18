port module Main exposing (main)

import AccountData exposing (AccountData, accountDataReceiver, setAccountData)
import Browser
import Browser.Navigation exposing (Key, load, pushUrl)
import Css exposing (absolute, alignItems, backgroundColor, border3, borderRadius, color, column, displayFlex, flexDirection, flexGrow, height, left, listStyle, marginBottom, none, num, padding, pct, position, px, relative, rgb, solid)
import DesignTokens exposing (elevation)
import Html.Styled as Styled exposing (..)
import Html.Styled.Attributes exposing (attribute, css, href, src)
import Html.Styled.Events exposing (onClick)
import Invoices as Invoices exposing (InvoiceData, invoicesReceiver)
import Json.Decode
import NotFound
import Pages.CreateAccount
import Pages.CreateClient
import Pages.CreateInvoice
import Pages.Home
import Pages.Invoice
import Route
import Session exposing (Session)
import Url exposing (Url)
import User exposing (User, userLoggedIn)


port signOut : () -> Cmd msg


port registerAccount : String -> Cmd msg


port firebaseError : (String -> msg) -> Sub msg


type Model
    = Home Session
    | Invoice Session Pages.Invoice.Model
    | CreateInvoice Session Pages.CreateInvoice.Model
    | CreateAccount Session Model Pages.CreateAccount.Model
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

        CreateAccount s _ _ ->
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
    | ReceviedAccountData Json.Decode.Value
    | ReceivedInvoices Json.Decode.Value
    | UserLoggedIn Json.Decode.Value
    | SignOut
    | FirebaseError String
    | NewInvoice InvoiceData
    | CreateInvoiceMsg Pages.CreateInvoice.Msg
    | CreateAccountMsg Pages.CreateAccount.Msg
    | CreateClientMsg Pages.CreateClient.Msg
    | InvoiceMsg Pages.Invoice.Msg
    | AccountCreated AccountData


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
                    registerAccount uid

                ( _, Nothing ) ->
                    Cmd.batch <| registerAccount uid :: extraCommands

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

                CreateAccount _ pm im ->
                    CreateAccount s pm im

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

        ( _, ReceviedAccountData v ) ->
            case AccountData.fromJson v of
                Err str ->
                    ( Error currentSession str, Cmd.none )

                Ok Nothing ->
                    ( CreateAccount currentSession model Pages.CreateAccount.init, Cmd.none )

                Ok userData ->
                    ( setSession { currentSession | accountData = userData } model, Cmd.none )

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
            case User.fromJson value of
                Err err ->
                    ( Error currentSession err, Cmd.none )

                Ok user ->
                    ( setSession { currentSession | user = Just user } model, Cmd.none )

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

        ( Invoice s m, InvoiceMsg msg_ ) ->
            Pages.Invoice.update msg_ m |> Tuple.mapFirst (Invoice s)

        ( CreateAccount _ pm m, CreateAccountMsg msg_ ) ->
            ( CreateAccount currentSession pm <| Pages.CreateAccount.update msg_ m, Cmd.none )

        ( CreateAccount _ pm _, AccountCreated userData ) ->
            ( setSession { currentSession | accountData = Just userData } pm, setAccountData userData )

        ( _, CreateInvoiceMsg _ ) ->
            ( model, Cmd.none )

        ( _, CreateClientMsg _ ) ->
            ( model, Cmd.none )

        ( _, NewInvoice _ ) ->
            ( model, Cmd.none )

        ( _, InvoiceMsg _ ) ->
            ( model, Cmd.none )

        ( _, CreateAccountMsg _ ) ->
            ( model, Cmd.none )

        ( _, AccountCreated _ ) ->
            ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ accountDataReceiver ReceviedAccountData
        , invoicesReceiver ReceivedInvoices
        , firebaseError FirebaseError
        , userLoggedIn UserLoggedIn
        ]


view : Model -> Browser.Document Msg
view model =
    { title = "חשבונית"
    , body = [ viewHeader <| .user <| session model, viewMain model ] |> List.map toUnstyled
    }


viewHeader : Maybe User -> Html Msg
viewHeader user =
    let
        accountDetails : Html Msg
        accountDetails =
            case user of
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
    case model of
        Home s ->
            Pages.Home.view s

        Invoice s m ->
            Pages.Invoice.view s m |> Styled.map InvoiceMsg

        CreateInvoice { invoices } m ->
            Pages.CreateInvoice.view invoices m |> Styled.map handleCreateInvoiceMsg

        CreateClient _ m ->
            Pages.CreateClient.view m |> Styled.map CreateClientMsg

        CreateAccount _ _ m ->
            Pages.CreateAccount.view m |> Styled.map (Pages.CreateAccount.mapMsg CreateAccountMsg AccountCreated)

        NotFound { uid } ->
            main_ [] <| NotFound.view uid "הדף שחיפשת לא קיים."

        Error _ str ->
            main_ [] [ p [] [ text str ] ]


main : Program () Model Msg
main =
    Browser.application { init = init, update = update, subscriptions = subscriptions, onUrlChange = UrlChanged, onUrlRequest = LinkClicked, view = view }
