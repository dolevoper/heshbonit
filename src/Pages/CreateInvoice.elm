module Pages.CreateInvoice exposing (Model, Msg, init, mapMsg, update, view)

import Date
import Forms exposing (NumericInputType(..), numericInput)
import Html
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (href, required, type_, value)
import Html.Styled.Events exposing (onInput, onSubmit)
import Invoices exposing (InvoiceData, Invoices)
import Route
import Task
import Time exposing (Posix, Zone)


type alias Model =
    { uid : String
    , description : String
    , amount : String
    , date : String
    }


type Msg
    = Description String
    | Amount String
    | Date String
    | Submit Model


init : String -> ( Model, Cmd Msg )
init uid =
    let
        toDate : Zone -> Posix -> String
        toDate zone posix =
            String.join "-" <|
                List.map (String.fromInt >> String.padLeft 2 '0')
                    [ Time.toYear zone posix
                    , Time.toMonth zone posix |> month
                    , Time.toDay zone posix
                    ]

        month : Time.Month -> Int
        month m =
            case m of
                Time.Jan ->
                    1

                Time.Feb ->
                    2

                Time.Mar ->
                    3

                Time.Apr ->
                    4

                Time.May ->
                    5

                Time.Jun ->
                    6

                Time.Jul ->
                    7

                Time.Aug ->
                    8

                Time.Sep ->
                    9

                Time.Oct ->
                    10

                Time.Nov ->
                    11

                Time.Dec ->
                    12
    in
    ( Model uid "" "" "", Task.perform Date <| Task.map2 toDate Time.here Time.now )


update : Msg -> Model -> Model
update msg model =
    case msg of
        Description str ->
            { model | description = str }

        Amount str ->
            { model | amount = str }

        Date str ->
            { model | date = str }

        Submit _ ->
            model


view : Maybe Invoices -> Model -> Html Msg
view invoices model =
    let
        invoiceNum : String
        invoiceNum =
            invoices |> Maybe.map (Invoices.nextInvoiceNum >> String.fromInt) |> Maybe.withDefault "טוען..."
    in
    main_ []
        [ a [ href <| Route.home model.uid ] [ text "❌" ]
        , h4 [] [ text ("קבלה מס' " ++ invoiceNum) ]
        , form [ onSubmit <| Submit model ]
            [ label []
                [ span [] [ text "עבור" ]
                , textarea [ required True, value model.description, onInput Description ] []
                ]
            , label []
                [ span [] [ text "סה\"כ" ]
                , numericInput FloatingPointNumericInput [ required True, value model.amount, onInput Amount ] []
                ]
            , label []
                [ span [] [ text "תאריך" ]
                , input [ required True, type_ "date", value model.date, onInput Date ] []
                ]
            , button [ type_ "submit" ] [ text "שמור" ]
            ]
        ]


mapMsg : (Msg -> msg) -> (InvoiceData -> msg) -> Msg -> msg
mapMsg toInternalMsg toSubmitMsg msg =
    case msg of
        Submit model ->
            case String.toFloat model.amount of
                Nothing ->
                    toInternalMsg msg

                Just amount ->
                    toSubmitMsg { description = model.description, amount = amount, date = Date.fromDataString model.date }

        _ ->
            toInternalMsg msg
