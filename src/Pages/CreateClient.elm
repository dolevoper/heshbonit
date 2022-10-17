module Pages.CreateClient exposing (Model, Msg, init, update, view)

import Forms exposing (NumericInputType(..), numericInput)
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (href, required, type_, value)
import Html.Styled.Events exposing (onInput)
import Route
import Client exposing (Client)
import Html.Styled.Events exposing (onSubmit)


type alias Model =
    { uid : String
    , email : String
    , name : String
    , id : String
    , address : String
    , phone : String
    }


type Msg
    = ChangeEmail String
    | ChangeName String
    | ChangeId String
    | ChangeAddress String
    | ChangePhone String
    | Submit Client


init : String -> Model
init uid =
    Model uid "" "" "" "" ""


update : Msg -> Model -> Model
update msg model =
    case msg of
        ChangeEmail newEmail ->
            { model | email = newEmail }

        ChangeName newName ->
            { model | name = newName }

        ChangeId newId ->
            { model | id = newId }

        ChangeAddress newAddress ->
            { model | address = newAddress }

        ChangePhone newPhone ->
            { model | phone = newPhone }

        Submit _ ->
            model


view : Model -> Html Msg
view model =
    let
        client : Client
        client =
            { email = model.email
            , name = model.name
            , id = if model.id == "" then Nothing else Just model.id
            , address = if model.address == "" then Nothing else Just model.address
            , phone = if model.phone == "" then Nothing else Just model.phone
            }
    in
    main_ []
        [ a [ href <| Route.home model.uid ] [ text "❌" ]
        , h2 [] [ text "לקוח חדש" ]
        , form [ onSubmit <| Submit client ]
            [ label []
                [ span [] [ text "כתובת דואר אלקטרוני" ]
                , input [ type_ "email", value model.email, onInput ChangeEmail, required True ] []
                ]
            , label []
                [ span [] [ text "שם" ]
                , input [ value model.name, onInput ChangeName, required True ] []
                ]
            , label []
                [ span [] [ text "ח\"פ" ]
                , numericInput IntegerNumericInput [ value model.id, onInput ChangeId ] []
                ]
            , label []
                [ span [] [ text "כתובת" ]
                , input [ value model.address, onInput ChangeAddress ] []
                ]
            , label []
                [ span [] [ text "טלפון" ]
                , input [ type_ "tel", value model.phone, onInput ChangePhone ] []
                ]
            , button [ type_ "submit" ] [ text "שמור" ]
            ]
        ]
