module Forms exposing (NumericInputType(..), numericInput)

import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (attribute, pattern)


type NumericInputType
    = IntegerNumericInput
    | FloatingPointNumericInput


numericInput : NumericInputType -> List (Attribute msg) -> List (Html msg) -> Html msg
numericInput nitype attrs content =
    let
        p : String
        p =
            case nitype of
                IntegerNumericInput ->
                    "\\d*"

                FloatingPointNumericInput ->
                    "(\\d+\\.)?\\d*"
    in
    input (attrs ++ [ attribute "inputmode" "numeric", pattern p ]) content
