module Breakfast

import StdEnv
import iTasks

Start world = doTasks tasks world

makeTea = updateInformation [] False <<@ Hint "Make tea?"
    @! (\x -> if (x == True) (?Just "Tea") ?None)
makeCoffee = updateInformation [] False <<@ Hint "Make coffee?"
    @! (\x -> if (x == True) (?Just "Coffee") ?None)
makeSandwich = updateInformation [] False <<@ Hint "Make sandwich?"
    @! (\x -> if (x == True) (?Just "Sandwich") ?None)
eatBreakfast drink food = viewInformation []
    ("I'm eating "+++food+++" and drinking "+++drink)

maybeEatBreakfast :: TaskValue ((? String) (? String)) -> (? (Task String))
maybeEatBreakfast (Value ((?Just drink) (?Just food)) _) = ?Just (eatBreakfast drink food)
maybeEatBreakfast NoValue = ?None

tasks :: Task String
tasks = ((makeTea -||- makeCoffee) -&&- makeSandwich)
        >>* [OnValue maybeEatBreakfast]
