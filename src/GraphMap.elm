module GraphMap where

import Graph
import IntDict
import Node
import Svg
import SvgUtil
import List.Extra
import Layout
import Time
import Focus exposing ((=>))
import NodeBase
import Effects exposing (Effects)
import EffectsUtil


-- MODEL

type alias Model =
    { graph: Graph
    }

type alias Graph =
    Graph.Graph Node.Model Edge

type alias Edge = {}

init: (Model, Effects Action)
init =
    let
        range = [0..5]

        (nodes, nodeFxs) =
            List.map
                (\i ->
                    Node.testNode (500 + 30*i, 300 + (-1)^i*30*i)
                )
                range
            |> List.unzip

        model =
            Graph.fromNodeLabelsAndEdgePairs
                nodes
                [ (0, 1)
                , (0, 2)
                , (2, 3)
                , (3, 4)
                , (2, 5)
                , (2, 4)
                ]
            |> Graph.mapEdges (always {})
            |> Model

        fxs =
            List.map2 (\i fx -> Effects.map (NodeAction i) fx) range nodeFxs
            |> (::) (Effects.tick StepLayout)
            |> Effects.batch
    in
        (model, fxs)

empty: (Model, Effects Action)
empty =
    Model Graph.empty |> EffectsUtil.noFx

getNodePos: Graph.NodeId -> Model -> Maybe (Int, Int)
getNodePos id {graph} =
    case Graph.get id graph of
        Just {node, incoming, outgoing} ->
            Just node.label.pos
        Nothing -> Nothing

addEdge: Graph.NodeId -> Graph.NodeId -> Edge -> Graph -> Graph
addEdge a b edge graph =
    let
        contextUpdate id maybeCtx =
            case maybeCtx of
                Nothing -> Nothing
                Just ctx -> Just
                    {ctx | incoming = IntDict.insert id edge ctx.incoming}
    in
        if a /= b then
            Graph.update a (contextUpdate b) graph
            |> Graph.update b (contextUpdate a)
        else
            graph

addUnconnectedNode: Node.Model -> Graph -> (Graph, Graph.NodeId)
addUnconnectedNode node graph =
    let
        id =
            case Graph.nodeIdRange graph of
                Just (a, b) -> b + 1
                Nothing -> 1

        newNode =
            {node = Graph.Node id node, incoming = IntDict.empty, outgoing = IntDict.empty}
    in
        (Graph.insert newNode graph, id)


-- UPDATE

type Action
    = AddNode (Node.Model, Effects Node.Action)
    | AddEdge Graph.NodeId Graph.NodeId Edge
    | StepLayout Time.Time
    | NodeAction Graph.NodeId Node.Action

update: Action -> Model -> (Model, Effects Action)
update action model =
    case action of
        AddNode (node, fx) ->
            let
                (graph, id) =
                    addUnconnectedNode node model.graph
            in
                ( { model | graph = graph }
                , Effects.map (NodeAction id) fx
                )
        AddEdge a b edge ->
            EffectsUtil.noFx {model | graph = addEdge a b edge model.graph}
        StepLayout dt ->
            ({model | graph = Layout.stepLayout model.graph}
            , Effects.tick StepLayout
            )
        NodeAction id nodeAction ->
            let
                (maybeNode, fx) =
                    case Graph.get id model.graph of
                        Nothing ->
                            EffectsUtil.noFx Nothing
                        Just ctx ->
                            let
                                (node, fx) = Node.update nodeAction ctx.node.label
                            in
                                (Just node, fx)

                focusUpdate ctx node =
                    Focus.update
                        (Graph.node => Graph.label)
                        (always node)
                        ctx

                updateCtx maybeCtx =
                    Maybe.map2 focusUpdate maybeCtx maybeNode
            in
                ( {model | graph = Graph.update id updateCtx model.graph}
                , Effects.map (NodeAction id) fx
                )


-- VIEW

view: Signal.Address (Graph.NodeId, NodeBase.MouseAction)
    -> Signal.Address Action -> Model -> Svg.Svg
view mouseAddress address {graph} =
    let
        toPositions list =
            List.filterMap (\id -> Graph.get id graph) list
            |> List.map (\ctx -> ctx.node.label.pos)

        edges =
            Graph.edges graph
            |> List.map (\{from, to, label} -> (max from to, min from to))
            |> List.Extra.dropDuplicates
            |> List.unzip
            |> (\(l1, l2) -> List.map2 (,) (toPositions l1) (toPositions l2))
            |> List.map (\(a, b) -> edgeForm a b)

        context id =
            NodeAction id
            |> Signal.forwardTo address
            |> Node.Context (Signal.forwardTo mouseAddress (\action -> (id, action)))

        nodes =
            Graph.nodes graph
            |> List.map (\{id, label} -> Node.view (context id) label)
    in
        Svg.g [] (edges ++ nodes)

edgeForm: (Int, Int) -> (Int, Int) -> Svg.Svg
edgeForm posA posB =
    SvgUtil.line posA posB 5 "#244F9F"
