module Invoices exposing (Invoices, InvoiceData, defaultBase, create, empty, toList, get)

import Date exposing (Date)


type alias InvoiceData =
    { date : Result String Date
    , amount : Float
    , description : String
    }


type Invoices
    = Invoices Int (List InvoiceData)

defaultBase = 40001

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
get num invoices = List.drop (num - (base invoices)) (records invoices) |> List.head

