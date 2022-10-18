module NotFound exposing (view)

import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (href)
import Route


view : String -> String -> List (Html msg)
view uid msg =
    [ p [] [ text msg, br [] [], a [ href <| Route.home <| uid ] [ text "חזרה לדף הראשי" ] ] ]
