-- Autogenerated by generate_metacontent.py
-- If only elm had type classes...

module MetaContent where

import ContentUtil
import Signal
import Debug
import Svg

import Content.Other as Other
import Content.Term as Term


-- MODEL

type MultiModel
    = MOther Other.Model
    | MTerm Term.Model


-- UPDATE

type MultiAction
    = AOther Other.Action
    | ATerm Term.Action

mismatchError: String
mismatchError = "MetaContent.update action model type mismatch"

update: MultiAction -> MultiModel -> MultiModel
update multiAction multiModel =
    case multiAction of
        AOther action ->
            case multiModel of
                MOther model ->
                    Other.update action model |> MOther
                otherwise ->
                    Debug.crash mismatchError
        ATerm action ->
            case multiModel of
                MTerm model ->
                    Term.update action model |> MTerm
                otherwise ->
                    Debug.crash mismatchError


-- VIEW

view: ContentUtil.ViewContext MultiAction -> MultiModel -> Svg.Svg
view context multiModel =
        MOther model ->
            Other.view
                { context | actions = Signal.forwardTo context.actions AOther }
                model
        MTerm model ->
            Term.view
                { context | actions = Signal.forwardTo context.actions ATerm }
                model