//
//  PreconcurrencyConformance.swift
//  ConcurrencyProtocolMismatch
//
//  Created by Alaa Amin on 18/10/2024.
//

import SwiftUI

///
/// Objective: This sample demonstrates how actor isolation is inherited in subclasses,
/// with a focus on the behavior of overridden synchronous and asynchronous functions.
/// It highlights that:
/// 1. Synchronous functions inherit the isolation of their parent and cannot override it.
/// 2. Asynchronous functions can override their parent's isolation, adapting to the subclass's isolation context.
/// 3. Actor isolation, when applied to a subclass (e.g., `@MainActor`), is inherited by further subclasses unless explicitly changed.
///
/// To run this code:
/// 1- Go to ContentView.swift.
/// 2- Uncomment the `ClassGlobalActorInheritanceView()` line in the `body` property
/// 3- Comment out the initializations of other views in the `body` property.
///

struct ClassGlobalActorInheritanceView: View {
    var body: some View {
        VStack {
            Text("Global actor inheritance in classes")
        }
        .padding()
        .task {
            await test()
        }
    }
    
    nonisolated func test() async {
        await SubClass2().asyncFunc()
        
        let subClass = SubClass()
        subClass.nonIsolated()
    }
}

fileprivate class SuperClass {
    func nonIsolated() {
        print("SuperClass: nonIsolatedSync  -- runs in the caller's execution context --> isMainThread: \(Thread.isMainThread)")
    }
    
    func asyncFunc() async {
        // This function will run in a background context because it's nonisolated and async
        print("SuperClass: asyncFunc  -- not isolated to the MainActor")
    }
}

@MainActor
///
/// Two points to note regarding the `@unchecked Sendable`:
/// 1- Even though `SubClass` is isolated to `MainActor` is doesn't get the implicit `Sendable` conformance because
/// the superClass is not `MainActor` isolated.
/// 2- This conformance is needed because of the `await super.asyncFunc()` call (line 73),
/// in which self (the Subclass) will cross the isolation context from `MainActor` to non-MainActor.
///
fileprivate class SubClass: SuperClass, @unchecked Sendable {
    override func nonIsolated() {
        /// Overridden synchronous functions inherit their parents' isolation (non-isolation) and can't override it
        print("SubClass: nonIsolatedSync -- runs in the caller's execution context --> isMainThread: \(Thread.isMainThread)")
        super.nonIsolated()
    }
    
    override func asyncFunc() async {
        /// Overridden asynchronous functions can have a different isolation than their parents
        print("SubClass: asyncFunc  -- isolated to the MainActor")
        MainActor.assertIsolated()
        await super.asyncFunc()
    }
}


fileprivate class SubClass2: SubClass, @unchecked Sendable {
    override func asyncFunc() async {
        /// SubClass2 and its functions are isolated to the MainActor. Isolation is inherited from the class's parent (SubClass).
        /// unless we add the nonisolated keyword to the function declaration
        print("SubClass2: asyncFunc  -- isolated to the MainActor")
        MainActor.assertIsolated()
        await super.asyncFunc()
    }
}
