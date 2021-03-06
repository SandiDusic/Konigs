module ContextMenu exposing (..)

import Html
import Html.Events as Events
import Html.Attributes
import MyCss
import Util
import Material.Button as Button
import Material.Icon as Icon
import Material
import Material.Options as Options


-- MODEL


type alias Model =
    { mdl : Material.Model
    , mouseOver : Bool
    }


init : Model
init =
    Model Material.model False



-- UPDATE


type Msg
    = ToParent OutMsg
    | MouseOver
    | MouseOut
    | MdlMsg (Material.Msg Msg)


type OutMsg
    = Remove
    | ToggleDescription


update : Msg -> Model -> ( Model, Cmd Msg, Maybe OutMsg )
update msg model =
    case msg of
        ToParent outMsg ->
            ( model, Cmd.none, Just outMsg )

        MouseOver ->
            ( { model | mouseOver = True }, Cmd.none, Nothing )

        MouseOut ->
            ( { model | mouseOver = False }, Cmd.none, Nothing )

        MdlMsg msg_ ->
            let
                ( model_, cmd ) =
                    Material.update MdlMsg msg_ model
            in
                ( model_, cmd, Nothing )



-- VIEW


options : List (Util.Option OutMsg)
options =
    [ Util.Option Remove "delete" "Delete"
    , Util.Option ToggleDescription "description" "Toggle description"
    ]


view : Model -> Html.Html Msg
view model =
    List.map2 (optionView model)
        (List.range 0 <| List.length options - 1)
        options
        |> Html.div
            [ MyCss.class [ MyCss.ContextMenu ]
            , Events.onMouseEnter MouseOver
            , Events.onMouseLeave MouseOut
            ]


optionView : Model -> Int -> Util.Option OutMsg -> Html.Html Msg
optionView model id option =
    Button.render MdlMsg
        [ id ]
        model.mdl
        [ Button.icon
        , Options.onClick (ToParent option.msg)
        , Options.attribute <| Html.Attributes.title option.tooltip
        ]
        [ Icon.i option.icon ]
