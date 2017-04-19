module Grouped exposing (Grouped, Group, Bar, view, bar)

{-|
@docs Grouped, Bar, view
-}

import Svg exposing (Svg, Attribute, g, svg, text)
import Svg.Attributes as Attributes exposing (class, width, height, fill, stroke)
import Svg.Coordinates exposing (Plane, Point, minimum, maximum)
import Svg.Plot exposing (..)
import Axis exposing (Axis, Mark, defaultMarkView, gridyMarkView)
import Internal.Axis exposing
  ( viewHorizontal
  , viewVertical
  , viewGrid
  , viewBunchOfLines
  , compose
  , maybeCompose
  , raport
  , apply
  )


{-| -}
type alias Group msg =
  { bars : List (Bar msg)
  , label : String
  }

{-| -}
type alias Grouped data msg =
  { toGroups : data -> List (Group msg)
  , width : Float
  }


{-| -}
type alias Bar msg =
  { attributes : List (Attribute msg)
  , y : Float
  }


{-| -}
bar : List (Attribute msg) -> Float -> Bar msg
bar attributes y =
  { attributes = attributes
  , y = y
  }


{-| -}
type alias DependentAxis =
  { line : Maybe (Axis.Raport -> Axis.LineView)
  , mark : DependentMark
  }


{-| -}
type alias DependentMark =
  { label : String -> Svg Never
  , tick : Maybe Axis.TickView
  }


{-| -}
type alias Config =
  { independentAxis : Axis.View
  , dependentAxis : DependentAxis
  }



-- VIEW


{-| -}
view : Config -> Grouped data msg -> data -> Svg msg
view config grouped data =
  let
    groups =
      grouped.toGroups data

    plane =
      planeFromBars config groups

    mark index group =
      { position = toFloat index + 1
      , view =
          { grid = Nothing
          , junk = Nothing
          , label = Just (config.dependentAxis.mark.label group.label)
          , tick = config.dependentAxis.mark.tick
          }
      }

    dependentAxis =
      { position = \_ _ -> 0
      , line = config.dependentAxis.line
      , marks = \_ -> List.indexedMap mark groups
      , mirror = False
      }

    yMarks =
      apply plane.x config.independentAxis.marks
  in
    svg
      [ width (toString plane.x.length)
      , height (toString plane.y.length)
      ]
      [ Svg.map never (viewGrid plane [] yMarks)
      , viewGrouped plane grouped groups
      , Svg.map never (viewHorizontal plane dependentAxis)
      , Svg.map never (viewVertical plane config.independentAxis)
      , Svg.map never (viewBunchOfLines plane [] yMarks)
      ]



-- VIEW HISTOGRAM


viewGrouped : Plane -> Grouped data msg -> List (Group msg) -> Svg msg
viewGrouped plane grouped groups =
  Svg.Plot.grouped plane
    { groups = List.map .bars groups
    , width = grouped.width
    }



-- PLANE


planeFromBars : Config -> List (Group msg) -> Plane
planeFromBars config groups =
  { x =
    { marginLower = 40
    , marginUpper = 40
    , length = 600
    , min = 0.5
    , max = toFloat (List.length groups) + 0.5
    }
  , y =
    { marginLower = 40
    , marginUpper = 40
    , length = 300
    , min = min 0 (minimum .y (List.concatMap .bars groups))
    , max = max 0 (maximum .y (List.concatMap .bars groups))
    }
  }