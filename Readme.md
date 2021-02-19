
# Differentiation Experiments in Swift

This repository contains a more or less random collection of ideas that demonstrate applications of the differentiability built into the Swift programming language. Running the examples requires [trunk development snapshot of the Swift compiler](https://swift.org/download/#snapshots). Release versions of the compiler don't contain the `Differentiation` module.


## A differentiable ODE integrator for sensitivity analysis - [`RK4`](Sources/RK4/main.swift)

**Currently (Feb 2021) impossible to complete due to a bug that crashes the Swift compiler when inline closures are used. See [https://bugs.swift.org/browse/SR-12992](https://bugs.swift.org/browse/SR-12992) for more details.**

> A related topic is finding derivatives of functions that are defined by differential equations. We typically use a numerical integrator to find solutions to these functions. Those leave us with numeric solutions which we then have to use to approximate derivatives. What if the integrator itself was differentiable? It is after all, just a program, and automatic differentiation should be able to tell us the derivatives of functions that use them.

Source code and the idea is adapted from this [blog post](https://kitchingroup.cheme.cmu.edu/blog/2018/10/11/A-differentiable-ODE-integrator-for-sensitivity-analysis/) published by the Kitchin group at CMU.

![Figure 2](Sources/RK4/Figure%202.png?raw=true)


## Derivative of an integral function - [`Trapz`](Sources/Trapz/main.swift)

> The idea is simple, we define a function in Python as usual, and in the function body calculate the integral in a program. Then we use autograd to get the derivative of the function.

Source code and the idea is adapted from this [blog post](http://kitchingroup.cheme.cmu.edu/blog/2018/10/10/Autograd-and-the-derivative-of-an-integral-function/) published by the Kitchin group at CMU.

![Example 2](Sources/Trapz/Example%202.png?raw=true)


## Bounce - Some balls attached to springs - [`Bounce`](Sources/Bounce/main.swift)

> We demonstrate the language using a mass-spring simulator, with three springs and three mass points, as shown right.

Inspired by an example used in the [DiffTaichi paper](https://arxiv.org/abs/1910.00935).

![Evolution](Sources/Bounce/Evolution.png?raw=true)


## Introduction to differentiable Swift - [`Opening`](Sources/Opening/main.swift)

> Build from the Foundation up!

![Curve Fritting](Sources/Opening/Curve%20Fitting.png?raw=true)


## Rudiments of automatic differentiation - [`Basics`](Sources/Basics/main.swift)

> Auto-differentiation, or simply autodiff, is a set of techniques to numerically evaluate the derivative of a function specified by a computer program. AD exploits the fact that every computer program, no matter how complicated, executes a sequence of elementary arithmetic operations (addition, subtraction, multiplication, division, etc.) and elementary functions (exp, log, sin, cos, etc.)

Inspired by the [Automatic differentiation](https://en.wikipedia.org/wiki/Automatic_differentiation) Wikipedia page.

---

Licensed under the [MIT License](License.txt).
