module Pages.CreateUser exposing (Model, Msg, init, mapMsg, update, view)

import Forms exposing (NumericInputType(..), numericInput)
import Html exposing (Html, button, form, input, label, main_, span, text)
import Html.Attributes exposing (required, type_, value)
import Html.Events exposing (onInput, onSubmit)
import UserData exposing (UserData)


type alias Model =
    { name : String
    , id : String
    }


type Msg
    = UpdateName String
    | UpdateId String
    | Submit Model


init : Model
init =
    Model "" ""


update : Msg -> Model -> Model
update msg model =
    case msg of
        UpdateName str ->
            { model | name = str }

        UpdateId str ->
            { model | id = str }

        Submit _ ->
            model


view : Model -> Html Msg
view model =
    main_ []
        [ form [ onSubmit <| Submit model ]
            [ label []
                [ span [] [ text "שם העסק" ]
                , input [ value model.name, onInput UpdateName, required True ] []
                ]
            , label []
                [ span [] [ text "ח\"פ" ]
                , numericInput IntegerNumericInput [ value model.id, onInput UpdateId, required True ] []
                ]
            , button [ type_ "submit" ] [ text "שמור" ]
            ]
        ]


mapMsg : (Msg -> msg) -> (UserData -> msg) -> Msg -> msg
mapMsg toInternalMsg toSubmitMsg msg =
    case msg of
        Submit model ->
            toSubmitMsg model

        _ ->
            toInternalMsg msg
