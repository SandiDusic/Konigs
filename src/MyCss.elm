module MyCss exposing (..)

import Css exposing (..)
import Css.Elements exposing (body, li)
import Css.Namespace exposing (namespace)
import Html.CssHelpers


namespaceName = "MyCss"

{ id, class, classList } =
    Html.CssHelpers.withNamespace namespaceName

type CssClasses
    = TermText

type CssIds
    = NothingAtAllToBeSeenHere

css =
    (stylesheet << namespace namespaceName)
    [ (.) TermText
        [ fontWeight bold
        ]
    ]