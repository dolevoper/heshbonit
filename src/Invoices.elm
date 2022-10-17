port module Invoices exposing (InvoiceData, Invoices, create, defaultBase, empty, fromJson, get, invoicesReceiver, isEmpty, nextInvoiceNum, toList)

import Date exposing (Date)
import Invoices.Status as Status exposing (Status)
import Json.Decode as D exposing (Decoder, Value)
import Json.Encode as E
import MaybeList
import String exposing (fromList)


port invoicesReceiver : (Value -> msg) -> Sub msg


port createInvoice : Value -> Cmd msg


type alias InvoiceData =
    { date : Result String Date
    , amount : Float
    , description : String
    , status : Status
    }


type Invoices
    = Invoices Int (List InvoiceData)


defaultBase : Int
defaultBase =
    40001


empty : Int -> Invoices
empty b =
    Invoices b []


isEmpty : Invoices -> Bool
isEmpty i =
    case i of
        Invoices _ [] ->
            True

        _ ->
            False


create : InvoiceData -> Invoices -> ( Invoices, Cmd msg )
create invoice invoices =
    case invoices of
        Invoices b existingRecords ->
            ( existingRecords ++ [ invoice ] |> Invoices b
            , createInvoice <| encode (b + List.length existingRecords) invoice
              -- { id = String.fromInt <| b + List.length existingRecords
              -- , description = invoice.description
              -- , date = Result.map Date.toDataString invoice.date |> Result.withDefault ""
              -- , amount = invoice.amount
              -- , status = Status.encoder invoice.status
              -- }
            )


base : Invoices -> Int
base invoices =
    case invoices of
        Invoices b _ ->
            b


nextInvoiceNum : Invoices -> Int
nextInvoiceNum invoices =
    case invoices of
        Invoices b i ->
            b + List.length i


records : Invoices -> List InvoiceData
records invoices =
    case invoices of
        Invoices _ r ->
            r


toList : (Int -> InvoiceData -> a) -> Invoices -> List a
toList fn invoices =
    let
        basedFn : Int -> InvoiceData -> a
        basedFn i data =
            fn (i + base invoices) data
    in
    List.indexedMap basedFn <| records invoices


get : Int -> Invoices -> Maybe InvoiceData
get num invoices =
    List.drop (num - base invoices) (records invoices) |> List.head


type alias ServerInvoice =
    { id : String
    , date : String
    , amount : Float
    , description : String
    , status : Status
    }


type alias ProcesedServerInvoice =
    { id : Int, date : Result String Date, description : String, amount : Float, status : Status }


decoder : Decoder (List ServerInvoice)
decoder =
    D.list <|
        D.map5 ServerInvoice
            (D.field "id" D.string)
            (D.field "date" D.string)
            (D.field "amount" D.float)
            (D.field "description" D.string)
            (D.field "status" Status.decoder)


encode : Int -> InvoiceData -> Value
encode id data =
    E.object
        [ ( "id", E.string <| String.fromInt id )
        , ( "date", E.string <| (Result.map Date.toDataString data.date |> Result.withDefault "") )
        , ( "amount", E.float data.amount )
        , ( "description", E.string data.description )
        , ( "status", Status.encoder data.status )
        ]


fromJson : Value -> Result String Invoices
fromJson v =
    let
        postProcessJson : ServerInvoice -> Maybe ProcesedServerInvoice
        postProcessJson i =
            String.toInt i.id |> Maybe.map (\a -> { id = a, date = Date.fromDataString i.date, description = i.description, amount = i.amount, status = i.status })

        foo : ProcesedServerInvoice -> ( Int, Result String Invoices ) -> ( Int, Result String Invoices )
        foo i ( prevId, res ) =
            if i.id /= prevId + 1 then
                ( i.id, Err "נמצאו מזהי קבלות לא עוקבים" )

            else
                ( i.id, Result.map (Tuple.first << create { date = i.date, description = i.description, amount = i.amount, status = i.status }) res )

        fromList : List ProcesedServerInvoice -> Result String Invoices
        fromList l =
            case List.head l of
                Nothing ->
                    Ok <| empty defaultBase

                Just { id } ->
                    List.foldl foo ( id - 1, Ok <| empty id ) l |> Tuple.second
    in
    case D.decodeValue decoder v of
        Err err ->
            Err (D.errorToString err)

        Ok l ->
            case l |> List.map postProcessJson |> MaybeList.fromListMaybe of
                Nothing ->
                    Err "חוסר תאימות במזהי קבלות"

                Just ppl ->
                    fromList ppl
