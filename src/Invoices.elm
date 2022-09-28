port module Invoices exposing (InvoiceData, Invoices, create, defaultBase, empty, fromJson, get, invoicesReceiver, toList)

import Date exposing (Date)
import Json.Decode as Json


port invoicesReceiver : (Json.Value -> msg) -> Sub msg


type alias InvoiceData =
    { date : Result String Date
    , amount : Float
    , description : String
    }


type Invoices
    = Invoices Int (List InvoiceData)


defaultBase =
    40001


empty : Int -> Invoices
empty b =
    Invoices b []


create : InvoiceData -> Invoices -> Invoices
create invoice invoices =
    case invoices of
        Invoices b existingRecords ->
            existingRecords ++ [ invoice ] |> Invoices b


base : Invoices -> Int
base invoices =
    case invoices of
        Invoices b _ ->
            b


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
    }


decoder : Json.Decoder (List ServerInvoice)
decoder =
    Json.list <|
        Json.map4 ServerInvoice
            (Json.field "id" Json.string)
            (Json.field "date" Json.string)
            (Json.field "amount" Json.float)
            (Json.field "description" Json.string)


fromJson : Json.Value -> Result String Invoices
fromJson v =
    -- TODO: add validation
    case Json.decodeValue decoder v of
        Err err ->
            Err (Json.errorToString err)

        Ok l ->
            l |> List.map (\a -> { date = Date.fromDataString a.date, description = a.description, amount = a.amount }) |> Invoices defaultBase |> Ok
