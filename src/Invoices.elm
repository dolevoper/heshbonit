port module Invoices exposing (InvoiceData, Invoices, create, defaultBase, empty, fromJson, get, invoicesReceiver, isEmpty, nextInvoiceNum, toList)

import Date exposing (Date)
import Json.Decode as Json
import MaybeList
import String exposing (fromList)


port invoicesReceiver : (Json.Value -> msg) -> Sub msg


type alias InvoiceData =
    { date : Result String Date
    , amount : Float
    , description : String
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
    }


type alias ProcesedServerInvoice =
    { id : Int, date : Result String Date, description : String, amount : Float }


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
    let
        postProcessJson : ServerInvoice -> Maybe ProcesedServerInvoice
        postProcessJson i =
            String.toInt i.id |> Maybe.map (\a -> { id = a, date = Date.fromDataString i.date, description = i.description, amount = i.amount })

        foo : ProcesedServerInvoice -> ( Int, Result String Invoices ) -> ( Int, Result String Invoices )
        foo i ( prevId, res ) =
            if i.id /= prevId + 1 then
                ( i.id, Err "נמצאו מזהי קבלות לא עוקבים" )

            else
                ( i.id, Result.map (create { date = i.date, description = i.description, amount = i.amount }) res )

        fromList : List ProcesedServerInvoice -> Result String Invoices
        fromList l =
            case List.head l of
                Nothing ->
                    Ok <| empty defaultBase

                Just { id } ->
                    List.foldl foo ( id - 1, Ok <| empty id ) l |> Tuple.second
    in
    case Json.decodeValue decoder v of
        Err err ->
            Err (Json.errorToString err)

        Ok l ->
            case l |> List.map postProcessJson |> MaybeList.fromListMaybe of
                Nothing ->
                    Err "חוסר תאימות במזהי קבלות"

                Just ppl ->
                    fromList ppl
