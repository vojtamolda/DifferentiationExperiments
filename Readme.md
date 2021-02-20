
# Differentiation Experiments in Swift

This repository contains a more or less random collection of ideas that demonstrate applications of the differentiability built into the Swift programming language. Running the examples requires [trunk development snapshot of the Swift compiler](https://swift.org/download/#snapshots). Release versions of the compiler don't contain the `Differentiation` module.


## Rudiments of automatic differentiation - [`Basics`](Sources/Basics/main.swift)

> Auto-differentiation, or simply autodiff, is a set of techniques to numerically evaluate the derivative of a function specified by a computer program. AD exploits the fact that every computer program, no matter how complicated, executes a sequence of elementary arithmetic operations (addition, subtraction, multiplication, division, etc.) and elementary functions (exp, log, sin, cos, etc.)

Inspired by the [Automatic differentiation](https://en.wikipedia.org/wiki/Automatic_differentiation) Wikipedia page.

---

Licensed under the [MIT License](License.txt).
