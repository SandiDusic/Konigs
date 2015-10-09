module MouseManipulator where

import GraphMap exposing (Action (..))
import Time
import Node
import Graph
import Debug
import Html.Attributes
import Html
import Svg
import Svg.Attributes as Att
import FpsClock


-- MODEL

type alias Model =
    { graphMap: GraphMap.Model
    , state: State
    , click: Click
    , fpsClock: FpsClock.Model
    }

type Click
    = DoubleClick
    | SingleClick Time.Time

type State
    = NoOp
    | Connecting Graph.NodeId Node.Model (Int, Int)

testModel: Model
testModel =
    Model GraphMap.testModel NoOp (SingleClick 0) FpsClock.init

getPointedNode: (Int, Int) -> GraphMap.Graph -> Maybe (Graph.NodeId, Node.Model)
getPointedNode pos graph =
    Graph.nodes graph
    |> List.filter (\n -> Node.isMouseWithin pos n.label)
    |> List.map (\n -> (n.id, n.label))
    |> List.head


-- UPDATE

type Action
    = Hold (Int, Int) Time.Time
    | Release (Int, Int) Time.Time
    | Move (Int, Int)
    | Tick Time.Time

update: Action -> Model -> Model
update action model =
    case action of
        Hold pos t ->
            case model.state of
                NoOp ->
                    startConnecting pos model
                otherwise ->
                    Debug.log "otherwise in Hold/NoOp branch of MouseManipulator" model
        Release pos t ->
            case model.state of
                Connecting id node pos' ->
                    endConnecting id pos model
                otherwise ->
                    handleDoubleClick pos t model
        Move pos ->
            case model.state of
                Connecting id node pos' ->
                    {model | state <- Connecting id node pos}
                otherwise -> model
        Tick dt ->
            { model
                | graphMap <- GraphMap.update (StepLayout dt) model.graphMap
                , fpsClock <- FpsClock.update dt
            }

startConnecting: (Int, Int) -> Model -> Model
startConnecting pos model =
    case getPointedNode pos model.graphMap.graph of
        Nothing -> model
        Just (id, node) ->
            {model | state <- Connecting id node (fst node.pos, snd node.pos)}

endConnecting: Graph.NodeId -> (Int, Int) -> Model -> Model
endConnecting id pos model =
    case getPointedNode pos model.graphMap.graph of
        Nothing -> {model | state <- NoOp}
        Just (id', node') ->
            if id == id' then
                {model | state <- NoOp}
            else
                { model
                    | graphMap <- GraphMap.update (AddEdge id id' {}) model.graphMap
                    , state <- NoOp
                }

handleDoubleClick: (Int, Int) -> Time.Time -> Model -> Model
handleDoubleClick pos t model =
    let
        afterClickUpdate =
            { model | click <-
                case model.click of
                    DoubleClick -> SingleClick t
                    SingleClick t'  -> if t-t' < 500 then DoubleClick else SingleClick t
            }

        node =
            Node.plainNode pos
    in
        case afterClickUpdate.click of
            SingleClick _ -> afterClickUpdate
            DoubleClick ->
                {afterClickUpdate | graphMap <-
                    GraphMap.update (AddNode node) afterClickUpdate.graphMap}


-- VIEW

view: (Int, Int) -> Model -> Html.Html
view (w, h) model =
    let
        connection =
            case model.state of
                Connecting id node pos ->
                    [GraphMap.edgeForm node.pos pos]
                otherwise -> []

        graph =
            [ GraphMap.view model.graphMap ]

        fps =
            [ FpsClock.view model.fpsClock ]

        svg =
            Svg.svg
                [ toString w |> Att.width
                , toString h |> Att.height
                ]
                (fps ++ connection ++ graph)
    in
        Html.div [unselectableStyle] [svg]

unselectableStyle: Html.Attribute
unselectableStyle =
    Html.Attributes.style
        [ ("-moz-user-select", "none")
        , ("-webkit-user-select", "none")
        , ("-ms-user-select", "none")
        ]