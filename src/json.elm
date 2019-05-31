module Main exposing (Model(..), Msg(..), getTodos, gifDecoder, init, main, subscriptions, update, view, viewGif)
 
import Browser
import Debug exposing (toString)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as D exposing (Decoder, field, string)



-- MAIN


main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- MODEL


type Model
    = Failure
    | Loading
    | Success (List String)


init : () -> ( Model, Cmd Msg )
init _ =
    ( Loading, getTodos )



-- UPDATE


type Msg
    = MorePlease
    -- | GotText (Result Http.Error String)
    | GotTodos (Result Http.Error (List String))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MorePlease ->
            ( Loading, getTodos )

        -- GotText result ->
        --     case result of
        --         Ok t ->
        --             ( Success t, Cmd.none )

        --         Err t ->
        --             ( Success <| ["Error" ++ toString t], Cmd.none )

        GotTodos result ->
            case result of
                Ok ts ->
                    ( Success ts, Cmd.none )

                Err err ->
                    ( Success <| ["Error " ++ toString err], Cmd.none )



-- GotGif result ->
--   case result of
--     Ok url ->
--       (Success url, Cmd.none)
--     Err _ ->
--       (Failure, Cmd.none)
-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ h2 [] [ text "Todos" ]
        , viewGif model
        ]


viewGif : Model -> Html Msg
viewGif model =
    case model of
        Failure ->
            div []
                [ text "I could not load the todos for some reason. "
                , button [ onClick MorePlease ] [ text "Try Again!" ]
                ]

        Loading ->
            text "Loading..."

        Success ts ->
            div []
                [ button [ onClick MorePlease, style "display" "block" ] [ text "More Please!" ]

                --, img [ src url ] []
                , text <| toString ts
                ]



-- HTTP


getTodos : Cmd Msg
getTodos =
    Http.get
        { url = "http://localhost:3000/todos"

        -- expectJson: (Result Error a -> msg) -> Decoder a -> Expect msg
        , expect = Http.expectJson GotTodos todoDecoder
        }



--url = "https://api.giphy.com/v1/gifs/random?api_key=kVzK0Ww6QpK5mO7uFyChBxzxdBfxO5Wq&tag=cat"
--, expect = Http.expectJson GotText


todoDecoder : Decoder (List String)
todoDecoder =
    -- D.map toString <| D.list (field "task" string) -- String
    D.list (field "task" string)


gifDecoder : Decoder String
gifDecoder =
    field "data" (field "image_url" string)
