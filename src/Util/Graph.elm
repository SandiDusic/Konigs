module Util.Graph exposing (..)

import Graph exposing (Graph)
import IntDict


type alias EdgeId =
    { from : Graph.NodeId, to : Graph.NodeId }


addEdge : EdgeId -> e -> Graph n e -> Graph n e
addEdge { from, to } edge graph =
    let
        exists =
            case Graph.get from graph of
                Just ctx ->
                    IntDict.member to ctx.outgoing

                Nothing ->
                    False

        contextUpdate id ctx =
            { ctx | outgoing = IntDict.insert id edge ctx.outgoing }
    in
        if from /= to && not exists then
            Graph.update from (contextUpdate to |> Maybe.map) graph
        else
            graph


newNodeId : Graph n e -> Graph.NodeId
newNodeId graph =
    case Graph.nodeIdRange graph of
        Just ( a, b ) ->
            b + 1

        Nothing ->
            1


addUnconnectedNode : Graph.NodeId -> n -> Graph n e -> Graph n e
addUnconnectedNode id node graph =
    Graph.insert
        { node = Graph.Node id node
        , incoming = IntDict.empty
        , outgoing = IntDict.empty
        }
        graph


getEdge : EdgeId -> Graph n e -> Maybe e
getEdge { from, to } graph =
    Graph.get from graph
        |> Maybe.andThen (\ctx -> IntDict.get to ctx.outgoing)