module Main exposing (Model, Msg(..), getTodos, init, main, subscriptions, update, view)

import Browser
import Debug exposing (toString)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as D exposing (Decoder, field, string)
import Json.Encode as E
import Maybe
import Time as T



-- MAIN


main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- MODEL


type alias TodoId =
    Int


type alias Todo =
    { id : TodoId
    , done : Bool
    , task : String
    , due : Maybe T.Posix
    }


type Connection
    = Idle
    | Loading


type alias Model =
    { conn : Connection
    , todos : List Todo
    , err : Maybe String
    , todoTask : String
    , todoId : Maybe.Maybe TodoId
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( Model Loading [] Maybe.Nothing "" Maybe.Nothing, getTodos )



-- UPDATE


type Msg
    = GetTodos
      -- | GotText (Result Http.Error String)
    | GotTodos (Result Http.Error (List Todo))
    | PostedTodo (Result Http.Error (List Todo))
    | PatchedTodo TodoId (Result Http.Error (List Todo))
    | NewTodo
    | NewTask String
    | Delete TodoId
    | Deleted (Result Http.Error ())
    | ToggleDone TodoId Bool


patchTodos : (List Todo) -> (List Todo) -> (List Todo)
patchTodos newTodos oldTodos =
    List.foldl (\n os -> List.map (\o -> if o.id == n.id then n else o) os) oldTodos newTodos
        
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GetTodos ->
            ( { model | conn = Loading }, getTodos )

        -- GotText result ->
        --     case result of
        --         Ok t ->
        --             ( Success t, Cmd.none )
        --         Err t ->
        --             ( Success <| ["Error" ++ toString t], Cmd.none )
        GotTodos result ->
            case result of
                Ok ts ->
                    ( { model | conn = Idle, todos = ts }, Cmd.none )

                Err err ->
                    ( { model | conn = Idle, err = Just ("Error: " ++ toString err) }, Cmd.none )

        PostedTodo result ->
            case result of
                Ok ts ->
                    ( { model | conn = Idle, todos = model.todos ++ ts }, Cmd.none )

                Err err ->
                    ( { model | conn = Idle, err = Just ("Error: " ++ toString err) }, Cmd.none )

        PatchedTodo todoId result ->
            case result of
                Ok ts ->
                    ( { model | conn = Idle, todos = patchTodos ts model.todos }, Cmd.none )

                Err err ->
                    ( { model | conn = Idle, err = Just ("Error patching " ++ toString todoId ++ ": " ++ toString err) }, Cmd.none )

        NewTask task ->
            ( { model | todoTask = task }, Cmd.none )

        NewTodo ->
            ( { model | todoTask = "" }, postTodo model.todoTask )

        Delete todoId ->
            ( { model | todoId = Just todoId }, deleteTodo todoId )

        Deleted result ->
            case model.todoId of
                Nothing ->
                    ( { model | err = Just <| "Error: Deleted nothing." }, Cmd.none )

                Just todoId ->
                    case result of
                        Ok _ ->
                            ( { model
                                | todoId = Maybe.Nothing
                                , todos = List.filter (\t -> t.id /= todoId) model.todos
                              }
                            , Cmd.none
                            )

                        Err err ->
                            ( { model
                                | todoId = Maybe.Nothing
                                , err = Just ("Error deleting " ++ toString todoId ++ ": " ++ toString err)
                              }
                            , Cmd.none
                            )
        ToggleDone todoId todoChecked ->
            ( model, toggleDone todoId todoChecked )


-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Html Msg
view model =
    div []
        ([ h2 [] [ text "Todos" ] ]
            ++ viewErr model.err
            ++ viewConn model.conn
            ++ viewTodos model.todos
            ++ [ viewNewTodo model, button [ onClick NewTodo ] [ text "New Task" ] ]
        )


viewErr : Maybe String -> List (Html Msg)
viewErr e =
    case e of
        Nothing ->
            []

        Just s ->
            [ text <| "Error: " ++ s ]


viewConn : Connection -> List (Html Msg)
viewConn c =
    case c of
        Idle ->
            []

        Loading ->
            [ text <| "Loading . . ." ]



-- Success ts ->
--     div []
--         [ button [ onClick MorePlease, style "display" "block" ] [ text "More Please!" ]
--         --, img [ src url ] []
--         , text <| toString ts
--         ]


viewNewTodo : Model -> Html Msg
viewNewTodo m =
    input [ type_ "text", placeholder "New Task", value m.todoTask, onSubmit NewTodo, onInput NewTask ] []


viewTodos : List Todo -> List (Html Msg)
viewTodos ts =
    List.map viewTodo ts


viewTodo : Todo -> Html Msg
viewTodo t =
    div []
        ([ input [ type_ "checkbox", checked t.done , onCheck (ToggleDone t.id) ] []
         , text t.task
         ]
            ++ Maybe.withDefault [] (Maybe.map (\d -> [ text <| "due " ++ toString d ]) t.due)
            -- ++ button [ onClick <| Edit t.id ] [ text "Edit" ]
            ++ [button [ onClick <| Delete t.id ] [ text "Delete" ]]
        )



-- text <| toString ts
-- HTTP


dbUrl : String
dbUrl =
    "http://localhost:3000/todos"


getTodos : Cmd Msg
getTodos =
    Http.get
        { url = dbUrl

        -- expectJson: (Result Error a -> msg) -> Decoder a -> Expect msg
        , expect = Http.expectJson GotTodos todosDecoder
        }


postTodo : String -> Cmd Msg
postTodo task =
    Http.request
        { body = Http.jsonBody <| E.object [ ( "task", E.string task ) ]
        , expect = Http.expectJson PostedTodo todosDecoder
        , headers = [ Http.header "Prefer" "return=representation" ]
        , method = "POST"
        , timeout = Maybe.Nothing
        , tracker = Maybe.Nothing
        , url = dbUrl
        }

patchTodo : TodoId -> String -> Cmd Msg
patchTodo todoId task =
    Http.request
        { body = Http.jsonBody <| E.object [ ( "task", E.string task ) ]
        , expect = Http.expectJson PostedTodo todosDecoder
        , headers = [ Http.header "Prefer" "return=representation" ]
        , method = "PATCH"
        , timeout = Maybe.Nothing
        , tracker = Maybe.Nothing
        , url = dbUrl ++ "?id=eq." ++ toString todoId
        }


deleteTodo : TodoId -> Cmd Msg
deleteTodo todoId =
    Http.request
        { body = Http.emptyBody
        , expect = Http.expectWhatever Deleted
        , headers = []
        , method = "DELETE"
        , timeout = Maybe.Nothing
        , tracker = Maybe.Nothing
        , url = dbUrl ++ "?id=eq." ++ toString todoId
        }

toggleDone : TodoId -> Bool -> Cmd Msg
toggleDone todoId checked =
    Http.request
        { body = Http.jsonBody <| E.object [ ( "done", E.bool checked ) ]
        , expect = Http.expectJson (PatchedTodo todoId) todosDecoder
        , headers = [ Http.header "Prefer" "return=representation" ]
        , method = "PATCH"
        , timeout = Maybe.Nothing
        , tracker = Maybe.Nothing
        , url = dbUrl ++ "?id=eq." ++ toString todoId
        }
    
--url = "https://api.giphy.com/v1/gifs/random?api_key=kVzK0Ww6QpK5mO7uFyChBxzxdBfxO5Wq&tag=cat"
--, expect = Http.expectJson GotText


todoDecoder : Decoder Todo
todoDecoder =
    D.map4 Todo
        (field "id" D.int)
        (field "done" D.bool)
        (field "task" D.string)
        (field "due" (D.maybe decodeTime))


todosDecoder : Decoder (List Todo)
todosDecoder =
    -- D.map toString <| D.list (field "task" string) -- String
    D.list todoDecoder



-- See https://stackoverflow.com/a/37147343/268040


decodeTime : Decoder T.Posix
decodeTime =
    D.int |> D.andThen (\i -> D.succeed (T.millisToPosix i))
