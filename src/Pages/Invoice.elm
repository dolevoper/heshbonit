port module Pages.Invoice exposing (Model, Msg, update, view)

import AccountData exposing (AccountData)
import Date
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (href)
import Html.Styled.Events exposing (onClick)
import Invoices
import Invoices.Status as Status
import NotFound
import Route
import Session exposing (Session)


port downloadInvoice : Int -> Cmd msg


type alias Model =
    Int


type Msg
    = DownloadInvoice


update : Msg -> Model -> ( Model, Cmd msg )
update msg model =
    case msg of
        DownloadInvoice ->
            ( model, downloadInvoice model )


view : Session -> Int -> Html Msg
view session num =
    let
        accountData : (AccountData -> String) -> String
        accountData fn =
            Maybe.map fn session.accountData |> Maybe.withDefault "טוען..."

        maybeInvoice =
            Maybe.andThen (Invoices.get num) session.invoices
    in
    main_ [] <|
        [ h2 [] [ text (accountData .name), a [ href <| Route.home session.uid ] [ text "❌" ] ]
        , h3 [] [ "עוסק פטור " ++ accountData .id |> text ]
        , h4 [] [ "קבלה מס' " ++ String.fromInt num |> text ]
        ]
            ++ (case ( session.invoices, maybeInvoice ) of
                    ( Nothing, _ ) ->
                        [ p [] [ text "טוען..." ] ]

                    ( Just _, Nothing ) ->
                        NotFound.view session.uid ("אופס, לא מצאתי חשבונית עם מספר " ++ String.fromInt num)

                    ( _, Just invoice ) ->
                        [ p [] [ h4 [] [ text "עבור" ], text invoice.description ]
                        , p [] [ "סה\"כ: " ++ String.fromFloat invoice.amount ++ "₪" |> text ]
                        , Date.view invoice.date
                        ]
                            ++ (if invoice.status == Status.Created then
                                    [ button [ onClick DownloadInvoice ] [ text "⬇️" ]
                                    ]

                                else
                                    []
                               )
               )
