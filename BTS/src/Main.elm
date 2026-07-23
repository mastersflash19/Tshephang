module Main exposing (main)

{-| Interactive Binary Search Tree Demo

This demo lets you add and remove integers from a BST.
The tree is drawn using SVG, and we show size, height, sum and average
to illustrate the use of folds.

Every use of `map`, `filter`, `foldl`, `foldr` and other list/Maybe
functions is explained in detail.
-}

import Browser
import Html exposing (..)
import Html.Attributes as Attr
import Html.Events exposing (onClick, onInput)
import Maybe exposing (..)
import String
import Svg exposing (..)
import Svg.Attributes as SvgAttr


-- TREE DEFINITION -------------------------------------------------------------

{-| A binary search tree (BST) storing comparable values.
`Empty` represents an empty tree; `Node` holds a value and left/right subtrees.
-}
type BST a
    = Empty
    | Node a (BST a) (BST a)


-- TREE OPERATIONS -------------------------------------------------------------

{-| Insert a value into a BST, maintaining the BST property.
Uses recursion (not fold) because we need to compare and go left/right.
-}
insert : comparable -> BST comparable -> BST comparable
insert x tree =
    case tree of
        Empty ->
            Node x Empty Empty

        Node y left right ->
            if x < y then
                Node y (insert x left) right

            else if x > y then
                Node y left (insert x right)

            else
                tree


{-| Remove a value from a BST.
-}
remove : comparable -> BST comparable -> BST comparable
remove x tree =
    case tree of
        Empty ->
            Empty

        Node y left right ->
            if x < y then
                Node y (remove x left) right

            else if x > y then
                Node y left (remove x right)

            else
                case ( left, right ) of
                    ( Empty, Empty ) ->
                        Empty

                    ( Node _ _ _, Empty ) ->
                        left

                    ( Empty, Node _ _ _ ) ->
                        right

                    ( _, _ ) ->
                        let
                            ( minVal, newRight ) =
                                removeMin right
                        in
                        Node minVal left newRight


{-| Helper: remove the minimum value from a non‑empty BST.
Returns (minimum value, tree without that value).
-}
removeMin : BST comparable -> ( comparable, BST comparable )
removeMin tree =
    case tree of
        Empty ->
            Debug.todo "removeMin called on Empty"

        Node x Empty right ->
            ( x, right )

        Node x left right ->
            let
                ( minVal, newLeft ) =
                    removeMin left
            in
            ( minVal, Node x newLeft right )


-- FOLDS ON TREES --------------------------------------------------------------

{-| A generic fold (catamorphism) for BST.
It applies a function to each node, combining the results from the left and
right subtrees. This is the foundation for many tree computations.

We'll use this function to demonstrate how fold works on a recursive data
structure. Notice that we don't need to traverse the tree explicitly each time;
we just pass a combining function and an initial accumulator.
-}
foldTree : (a -> b -> b -> b) -> b -> BST a -> b
foldTree f acc tree =
    case tree of
        Empty ->
            acc

        Node x left right ->
            f x (foldTree f acc left) (foldTree f acc right)


{-| Compute the number of nodes in the tree using foldTree.
We count 1 for the current node and add the sizes of left and right subtrees.
-}
size : BST a -> Int
size =
    foldTree (\_ leftSize rightSize -> 1 + leftSize + rightSize) 0


{-| Compute the height (maximum depth) of the tree.
Empty tree has height 0. A leaf has height 1 (since depth of root is 1).
-}
height : BST a -> Int
height =
    foldTree (\_ leftHeight rightHeight -> 1 + Basics.max leftHeight rightHeight) 0


{-| Sum of all values in the tree (only works for numbers).
-}
sum : BST Int -> Int
sum =
    foldTree (\x leftSum rightSum -> x + leftSum + rightSum) 0


{-| Convert a BST to a list via in‑order traversal using foldTree.
In‑order: left subtree, then node, then right subtree.
We use `foldTree` and concatenate lists.
-}
toListInOrder : BST a -> List a
toListInOrder =
    foldTree (\x leftList rightList -> leftList ++ [ x ] ++ rightList) []


{-| Pre‑order: node, then left, then right.
-}
toListPreOrder : BST a -> List a
toListPreOrder =
    foldTree (\x leftList rightList -> [ x ] ++ leftList ++ rightList) []


{-| Post‑order: left, then right, then node.
-}
toListPostOrder : BST a -> List a
toListPostOrder =
    foldTree (\x leftList rightList -> leftList ++ rightList ++ [ x ]) []


-- LAYOUT FOR VISUALIZATION ----------------------------------------------------

{-| Compute absolute positions (x, y) for each node so we can draw the tree.
The algorithm: we do an in‑order traversal to assign x coordinates (0,1,2,…)
so that the tree is sorted left‑to‑right. The y coordinate is the depth.
We return a list of (x, y, value) where x and y are integers (will be scaled).

This function uses recursion, not fold, because we need to carry state
(depth and the current x offset) through the traversal.

We use `List.map` later to transform these positions into SVG elements.
-}
layout : BST a -> List ( Int, Int, a )
layout tree =
    let
        layoutRec : Int -> BST a -> List ( Int, Int, a ) -> ( List ( Int, Int, a ), Int )
        layoutRec depth node acc =
            case node of
                Empty ->
                    ( acc, 0 )

                Node val left right ->
                    let
                        ( leftPositions, leftWidth ) =
                            layoutRec (depth + 1) left acc

                        x =
                            leftWidth

                        accWithNode =
                            ( x, depth, val ) :: leftPositions

                        ( rightPositions, rightWidth ) =
                            layoutRec (depth + 1) right accWithNode
                    in
                    ( rightPositions, leftWidth + 1 + rightWidth )
    in
    Tuple.first (layoutRec 0 tree [])


-- EDGES FOR VISUALIZATION ----------------------------------------------------

{-| Collect all edges (parent → child) as a list of `((x1,y1), (x2,y2))`.
Uses the layout positions and traverses the tree recursively.
-}
edges : BST a -> List ( ( Int, Int ), ( Int, Int ) )
edges tree =
    let
        -- Build a lookup list from value to (x,y) using List.map.
        posList =
            layout tree

        -- Create a list of (value, (x,y)) pairs.
        lookupList =
            List.map (\(x, y, val) -> (val, (x, y))) posList

        -- Helper: find (x,y) for a given value.
        findPos val =
            lookupList
                |> List.filter (\(v, _) -> v == val)
                |> List.map (\(_, pos) -> pos)
                |> List.head
                |> Maybe.withDefault (0, 0)  -- fallback, shouldn't happen

        -- Recursive traversal to collect edges.
        collect : BST a -> List ( ( Int, Int ), ( Int, Int ) )
        collect tree_ =
            case tree_ of
                Empty ->
                    []

                Node val left right ->
                    let
                        parentPos =
                            findPos val

                        leftEdges =
                            case left of
                                Empty ->
                                    []

                                Node lval _ _ ->
                                    let
                                        childPos =
                                            findPos lval
                                    in
                                    ( parentPos, childPos ) :: collect left

                        rightEdges =
                            case right of
                                Empty ->
                                    []

                                Node rval _ _ ->
                                    let
                                        childPos =
                                            findPos rval
                                    in
                                    ( parentPos, childPos ) :: collect right
                    in
                    leftEdges ++ rightEdges
    in
    collect tree


-- MODEL AND UPDATE ------------------------------------------------------------

type alias Model =
    { tree : BST Int
    , input : String
    }


type Msg
    = Add
    | Remove
    | InputChange String


update : Msg -> Model -> Model
update msg model =
    case msg of
        Add ->
            case String.toInt model.input of
                Just n ->
                    { model | tree = insert n model.tree }

                Nothing ->
                    model

        Remove ->
            case String.toInt model.input of
                Just n ->
                    { model | tree = remove n model.tree }

                Nothing ->
                    model

        InputChange newInput ->
            { model | input = newInput }


-- VIEW ------------------------------------------------------------------------

view : Model -> Html Msg
view model =
    let
        treeSize =
            size model.tree

        treeHeight =
            height model.tree

        treeSum =
            sum model.tree

        treeAvg =
            if treeSize == 0 then
                "N/A"

            else
                String.fromFloat (toFloat treeSum / toFloat treeSize)

        inOrderList =
            toListInOrder model.tree

        inOrderString =
            inOrderList
                |> List.map String.fromInt
                |> String.join ", "

        preOrderList =
            toListPreOrder model.tree

        preOrderString =
            preOrderList
                |> List.map String.fromInt
                |> String.join ", "

        postOrderList =
            toListPostOrder model.tree

        postOrderString =
            postOrderList
                |> List.map String.fromInt
                |> String.join ", "

        positions =
            layout model.tree

        ( maxX, maxY ) =
            positions
                |> List.foldl
                    (\( x, y, _ ) ( curMaxX, curMaxY ) ->
                        ( Basics.max x curMaxX, Basics.max y curMaxY )
                    )
                    ( 0, 0 )

        spacingX =
            40

        spacingY =
            40

        svgWidth =
            (maxX + 1) * spacingX + 20

        svgHeight =
            (maxY + 1) * spacingY + 20

        toSvgX x =
            String.fromInt (10 + x * spacingX)

        toSvgY y =
            String.fromInt (10 + y * spacingY)

        -- EDGES – using nested tuples
        edgeElements =
            edges model.tree
                |> List.map
                    (\( (x1, y1), (x2, y2) ) ->
                        line
                            [ SvgAttr.x1 (toSvgX x1)
                            , SvgAttr.y1 (toSvgY y1)
                            , SvgAttr.x2 (toSvgX x2)
                            , SvgAttr.y2 (toSvgY y2)
                            , SvgAttr.stroke "#666"
                            , SvgAttr.strokeWidth "2"
                            ]
                            []
                    )

        nodeElements =
            positions
                |> List.map
                    (\( x, y, val ) ->
                        let
                            cx =
                                toSvgX x

                            cy =
                                toSvgY y

                            label =
                                String.fromInt val
                        in
                        g []
                            [ circle
                                [ SvgAttr.cx cx
                                , SvgAttr.cy cy
                                , SvgAttr.r "15"
                                , SvgAttr.fill "#4a90d9"
                                , SvgAttr.stroke "#333"
                                , SvgAttr.strokeWidth "2"
                                ]
                                []
                            , text_
                                [ SvgAttr.x cx
                                , SvgAttr.y cy
                                , SvgAttr.textAnchor "middle"
                                , SvgAttr.dominantBaseline "central"
                                , SvgAttr.fill "white"
                                , SvgAttr.fontSize "14"
                                , SvgAttr.fontWeight "bold"
                                ]
                                [ Svg.text label ]
                            ]
                    )
    in
    div [ Attr.style "font-family" "sans-serif", Attr.style "padding" "20px" ]
        [ h1 [] [ Html.text "Binary Search Tree Demo" ]
        , div []
            [ input
                [ Attr.type_ "number"
                , Attr.placeholder "Enter an integer"
                , Attr.value model.input
                , onInput InputChange
                , Attr.style "padding" "5px"
                , Attr.style "margin-right" "10px"
                , Attr.style "width" "150px"
                ]
                []
            , button [ onClick Add, Attr.style "margin-right" "10px" ] [ Html.text "Add" ]
            , button [ onClick Remove ] [ Html.text "Remove" ]
            ]
        , div [ Attr.style "margin-top" "20px" ]
            [ h3 [] [ Html.text "Tree Visualization" ]
            , if positions == [] then
                p [] [ Html.text "The tree is empty." ]

              else
                svg
                    [ SvgAttr.width (String.fromInt svgWidth)
                    , SvgAttr.height (String.fromInt svgHeight)
                    , Attr.style "border" "1px solid #ccc"
                    , Attr.style "background" "#f9f9f9"
                    ]
                    (edgeElements ++ nodeElements)
            ]
        , div [ Attr.style "margin-top" "20px" ]
            [ h3 [] [ Html.text "Statistics (computed using foldTree)" ]
            , ul []
                [ li [] [ Html.text ("Size: " ++ String.fromInt treeSize) ]
                , li [] [ Html.text ("Height: " ++ String.fromInt treeHeight) ]
                , li [] [ Html.text ("Sum: " ++ String.fromInt treeSum) ]
                , li [] [ Html.text ("Average: " ++ treeAvg) ]
                ]
            ]
        , div [ Attr.style "margin-top" "20px" ]
            [ h3 [] [ Html.text "Traversals (using foldTree)" ]
            , ul []
                [ li [] [ Html.text ("In‑order:  " ++ inOrderString) ]
                , li [] [ Html.text ("Pre‑order: " ++ preOrderString) ]
                , li [] [ Html.text ("Post‑order:" ++ postOrderString) ]
                ]
            ]
        , div [ Attr.style "margin-top" "20px", Attr.style "font-size" "0.9em", Attr.style "color" "#555" ]
            [ p [] [ Html.text "Explanation: The folds above (size, height, sum, traversals) demonstrate how `foldTree` works." ]
            , p [] [ Html.text "List functions like `map`, `filter`, `foldl`, `foldr` are used here:" ]
            , ul []
                [ li [] [ Html.text "`List.map String.fromInt` converts each number to a string (used for traversals)." ]
                , li [] [ Html.text "`String.join \", \"` combines the list (not a fold, but a built‑in)." ]
                , li [] [ Html.text "`List.foldl` is used to compute the maximum coordinates for SVG sizing." ]
                , li [] [ Html.text "We also use `List.map` to turn each positioned node into an SVG circle+text." ]
                ]
            ]
        ]


-- MAIN -----------------------------------------------------------------------

main : Program () Model Msg
main =
    Browser.sandbox
        { init = { tree = Empty, input = "" }
        , update = update
        , view = view
        }