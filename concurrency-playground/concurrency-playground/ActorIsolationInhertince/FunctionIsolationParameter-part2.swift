//
//  PreconcurrencyConformance.swift
//  ConcurrencyProtocolMismatch
//
//  Created by Alaa Amin on 18/10/2024.
//

import SwiftUI

///
/// Objective: This sample demonstrates how we can overcome the protocol mismatch error
/// when a protocol with synchronous and non-isolated requirements is implemented by an actor.
/// We might not want to change the protocol requirements to be synchronous because it's implemented
/// by another non-actor type.
/// This code demonstrates two approaches very close to each other using the `isolated (any Actor)?` function parameter.
///
///
/// To run this code:
/// 1- Go to ContentView.swift.
/// 2- Uncomment the `FunctionIsolationParameterPart2View()` line in the `body` property
/// 3- Comment out the initializations of other views in the `body` property.
///


///
/// Approach 1
///
/// The `isolation` property will be used to pass the correct isolation to the `doStuff` function, ensuring
/// that the function gets executed in the correct context.
///
/// For example:
/// if a MainActor conforms to the protocol, the `isolation` should be `MainActor.Shared` (check the `MainActorClass` implementation).
/// if a non-isolated class conforms to the protocol, the `isolation` should be `nil` (check the `Logger` implementation).
///
fileprivate protocol IsolatedParameterProtocol {
    var isolation: Actor? { get }
    func doStuff(actor: isolated (any Actor)?)
}

///
/// Will explain later why we need this protocol
///
fileprivate protocol ActorIsolated: Sendable {}

///
/// Approach 2
///
/// In this approach, we eliminate the `var isolation: Actor?` property.
/// Instead, we use the `#isolation` directive. This will pass the call site's isolation context to `doStuff()`.
/// This approach is risky, and we will explain why later.
///
extension IsolatedParameterProtocol {
    func doStuff() {
        self.doStuff(actor: #isolation)
    }
}

@MainActor
fileprivate class MainActorClass: IsolatedParameterProtocol, ActorIsolated {
    nonisolated var isolation: Actor? {
        MainActor.shared
    }
    
    func doStuff(actor: isolated (any Actor)?) {
        ///
        /// We used `MainActor.assumeIsolated` here to be able to trigger
        /// `MainActor` isolated properties and functions without using an `await`.
        /// We assumed it would be safe to use the `assumeIsolated` because the caller
        /// would pass the `isolation` property to the `actor` parameter.
        ///
        MainActor.assumeIsolated {
            self.modifyX()
        }
    }
    
    var x = 1
    func modifyX() {
        x += 1
    }
}
  
fileprivate class Logger: IsolatedParameterProtocol {
    nonisolated var isolation: Actor? { nil }
    
    func doStuff(actor: isolated (any Actor)?) {
        self.modifyX()
    }
    
    var x = 1
    func modifyX() {
        x += 1
    }
}

fileprivate struct ViewInputEventsDispatcher {
    let abstractToProtocol: IsolatedParameterProtocol = MainActorClass()
    let logger: IsolatedParameterProtocol = Logger()
    
    func triggerFuncApproach1() {
        ///
        /// If we try to call `doStuff` like this, we will get a compilation error.
        /// We need to use `await` because the function is isolated to the `abstractToProtocol.isolation`
        ///
//        abstractToProtocol.doStuff(actor: abstractToProtocol.isolation)
        
        ///
        /// If we place the call in a `Task` and used an `await`, as shown below, we will still get a compilation error.
        /// This time, the error is due to the `abstractToProtocol` not being `Sendable`
        ///
//        Task {
//            await abstractToProtocol.doStuff(actor: abstractToProtocol.isolation)
//        }
        
        ///
        /// To overcome the above problem, we introduced the `ActorIsolated` protocol
        /// so we can guarantee to the compiler that the instance is `Sendable`
        ///
        typealias IsIsolatedAndSendable = IsolatedParameterProtocol & ActorIsolated
        if let isolatedAndSendable = abstractToProtocol as? IsIsolatedAndSendable {
            Task {
                await isolatedAndSendable.doStuff(actor: isolatedAndSendable.isolation)
            }
        }
        
        ///
        /// Please note the following:
        /// - If we pass `nil` to `doStuff` we don't need to use an `await`, because the function won't be isolated.
        /// - However, if we pass the `logger.isolation` we will need to use an `await` even tho it returns `nil`
        ///
        logger.doStuff(actor: nil)
//        logger.doStuff(actor: logger.isolation) // compilation error
    }
    
    
    func triggerFuncApproach2() {
        ///
        /// If call `doStuff` using the second approach, we don't need to use an `await`
        /// because the isolation context doesn't change, and the type doesn't need to be `Sendable`
        ///
        abstractToProtocol.doStuff()
        logger.doStuff()
        
        ///
        /// However, triggering `doStuff` from an isolation different from what the protocol conformer expects
        /// could lead to errors. In this example, it will lead to a crash because we are using the `MainActor.assumeIsolated`
        /// in our `doStuff` implementation
        ///
        Task.detached {
            MainActorClass().doStuff()
        }
    }
}

struct FunctionIsolationParameterPart2View: View {
    var body: some View {
        VStack {
            Text("Function isolation parameter - Part 2")
        }
        .padding()
        .task {
            ViewInputEventsDispatcher().triggerFuncApproach1()
            ViewInputEventsDispatcher().triggerFuncApproach2()
        }
    }
}
