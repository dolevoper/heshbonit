module Date exposing (Date, date, fromDataString, toDataString, toShortString, view)

import Html.Styled exposing (Html, span, text, time)
import Html.Styled.Attributes exposing (datetime)
import MaybeList


type alias DateData =
    { day : Int, month : Int, year : Int }


type Date
    = Date DateData


isLeapYear : Int -> Bool
isLeapYear year =
    (remainderBy 4 year == 0) && (not (remainderBy 100 year == 0) || (remainderBy 400 year == 0))


numberOfDays : DateData -> Result String Int
numberOfDays d =
    case ( d.month, isLeapYear d.year ) of
        ( 1, _ ) ->
            Ok 31

        ( 2, False ) ->
            Ok 28

        ( 2, True ) ->
            Ok 29

        ( 3, _ ) ->
            Ok 31

        ( 4, _ ) ->
            Ok 30

        ( 5, _ ) ->
            Ok 31

        ( 6, _ ) ->
            Ok 30

        ( 7, _ ) ->
            Ok 31

        ( 8, _ ) ->
            Ok 31

        ( 9, _ ) ->
            Ok 30

        ( 10, _ ) ->
            Ok 31

        ( 11, _ ) ->
            Ok 30

        ( 12, _ ) ->
            Ok 31

        _ ->
            Err ("Invalid month number: " ++ String.fromInt d.month)


date : DateData -> Result String Date
date d =
    let
        build : Int -> Result String Date
        build maxNumberOfDays =
            if d.day < 1 || d.day > maxNumberOfDays then
                Err ("Invalid day number: " ++ String.fromInt d.day)

            else
                Date { day = d.day, month = d.month, year = d.year } |> Ok
    in
    numberOfDays d |> Result.andThen build


fromDataString : String -> Result String Date
fromDataString str =
    let
        parse : Maybe (List Int) -> Result String Date
        parse l =
            case l of
                Just [ y, m, d ] ->
                    date { day = d, month = m, year = y }

                Just _ ->
                    Err "Too many parts"

                Nothing ->
                    Err "All parts should be integers"
    in
    str |> String.split "-" |> List.map String.toInt |> MaybeList.fromListMaybe |> parse


toShortString : Date -> String
toShortString d =
    case d of
        Date { day, month, year } ->
            List.map String.fromInt [ day, month, year ] |> String.join "/"


toDataString : Date -> String
toDataString d =
    case d of
        Date { day, month, year } ->
            List.map String.fromInt [ year, month, day ] |> String.join "-"


view : Result String Date -> Html msg
view rd =
    case rd of
        Ok d ->
            time [ toDataString d |> datetime ] [ toShortString d |> text ]

        Err _ ->
            span [] [ text "INVALID DATE" ]
