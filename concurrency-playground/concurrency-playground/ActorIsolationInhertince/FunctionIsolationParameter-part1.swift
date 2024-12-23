//
//  PreconcurrencyConformance.swift
//  ConcurrencyProtocolMismatch
//
//  Created by Alaa Amin on 18/10/2024.
//

import SwiftUI

///
/// Objective: This sample demonstrates the behavior of functions that take an `isolated` parameter
/// and how it impacts function's isolation. Key concepts covered include:
/// 1. Using the `isolated` parameter, isolates functions to a specific actor context.
/// 2. Dynamic isolation using `isolated (any Actor)?` parameter will isolate the function
///    based on the actor instance passed or make the function non-isolated if `nil` is sent.
///
/// To run this code:
/// 1- Go to ContentView.swift.
/// 2- Uncomment the `FunctionIsolationParameterPart1View()` line in the `body` property
/// 3- Comment out the initializations of other views in the `body` property.
///

struct FunctionIsolationParameterPart1View: View {
    var body: some View {
        VStack {
            Text("Function isolation parameter - Part 1")
        }
        .padding()
    }
}

///
/// Example 1: How does the `isolated` parameter work?
///

fileprivate class NonSendableType {
    var x = 0
}

fileprivate actor ActorExample {
    var nonSendable = NonSendableType()
}

fileprivate struct NonIsolatedStruct {
    
    ///
    /// This function has a parameter of type `isolated ActorExample` which means the following:
    /// 1- The function is now isolated to `ActorExample` even tho it's declared outside of the actor's scope.
    /// 2- We can access and modify `ActorExample` without using an `await` because the function will execute in the `ActorExample`'s context.
    /// 3- If we call this function outside of the `ActorExample`'s context, we will need to use an `await`.
    ///
    func actorIsolatedFuncByParameter(_ actor: isolated ActorExample) {
        actor.nonSendable.x += 1
    }
}

///
/// Example 2: Instead of using a specific actor type as the function parameter we can use `any Actor`
/// Function will be isolated to the actor instance passed to it, or
/// it will be non-isolated if actor == nil
///
fileprivate func dynamicIsolationParameter(_ actor: isolated (any Actor)?) {}

///
/// Apple's examples to show how context isolation works with a function that
/// has a `isolated (any Actor)?` parameter
///

/// This class type is not Sendable.
class Counter {
    var count = 0
}

extension Counter {
    /// Since this is an async function, if it were just declared
    /// non-isolated, calling it from an isolated context would be
    /// forbidden because it requires sharing a non-Sendable value
    /// between concurrency domains. Inheriting isolation makes it
    /// okay. This is a contrived example chosen for its simplicity.
    func incrementAndSleep(isolation: isolated (any Actor)?) async {
        count += 1
        try? await Task.sleep(nanoseconds: 1_000_000)
    }
}

actor MyActor {
    var counter = Counter ()
}

extension MyActor {
    func testActor(other: MyActor) async {
        // allowed
        await counter.incrementAndSleep(isolation: self)
        
        ///
        /// The below are not allowed because the counter is non-sendable, and when
        /// we use an isolation parameter different from the current context we are in (MyActor)
        /// counter will need to cross the isolation boundary, which is not allowed and unsafe.
        ///
//        // not allowed
//        await counter.incrementAndSleep (isolation: other)
//        // not allowed
//        await counter.incrementAndSleep(isolation: MainActor.shared)
//        // not allowed
//        await counter.incrementAndSleep (isolation: nil)
    }
}

@MainActor func testMainActor(counter: Counter) async {
    // allowed
    await counter.incrementAndSleep(isolation: MainActor.shared)
    
//    // not allowed
//    await counter.incrementAndSleep(isolation: nil)
}

func testNonIsolated (counter: Counter) async {
    // allowed -- `testNonIsolated` is non-isolated, and nil is passed to the isolation parameter of `incrementAndSleep`,
    // which results in `incrementAndSleep` also being non-isolated. So no context change)
    await counter.incrementAndSleep(isolation: nil)
    
//    // not allowed
//    await counter.incrementAndSleep(isolation: MainActor.shared)
}
