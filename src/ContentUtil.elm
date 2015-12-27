module ContentUtil where

type alias ViewContext action =
    { pos: (Int, Int)
    , radius: Int
    , actions: Signal.Address action
    }