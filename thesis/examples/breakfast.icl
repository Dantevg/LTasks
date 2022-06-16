module Breakfast

import StdEnv
import iTasks

Start :: *World -> *World
Start world = doTasks breakfast world

makeTea :: Task String
makeTea = updateInformation [] False <<@ Hint "Make tea?"
        @ (\x -> if x (?Just "Tea") ?None)
        @? tvFromMaybe

makeCoffee :: Task String
makeCoffee = updateInformation [] False <<@ Hint "Make coffee?"
        @ (\x -> if x (?Just "Coffee") ?None)
        @? tvFromMaybe

makeSandwich :: Task String
makeSandwich = updateInformation [] False <<@ Hint "Make a sandwich?"
        @ (\x -> if x (?Just "A Sandwich") ?None)
        @? tvFromMaybe

eatBreakfast :: String String -> Task String
eatBreakfast drink food = viewInformation []
        ("I'm eating "+++food+++" and drinking "+++drink)

maybeEatBreakfast :: (TaskValue (String, String)) -> ? (Task String)
maybeEatBreakfast (Value (drink, food) _) = ?Just (eatBreakfast drink food)
maybeEatBreakfast _ = ?None

breakfast :: Task String
breakfast = ((makeTea -||- makeCoffee) -&&- makeSandwich)
        >>* [OnValue maybeEatBreakfast]
