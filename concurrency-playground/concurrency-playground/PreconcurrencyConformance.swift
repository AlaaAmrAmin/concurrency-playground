//
//  PreconcurrencyConformance.swift
//  ConcurrencyProtocolMismatch
//
//  Created by Alaa Amin on 18/10/2024.
//

import SwiftUI

///
/// Objective: This sample demonstrates an issue related to the usage of `@preconcurrency` with protocol conformance
///
/// (The `@preconcurrency` can be used to suppress errors when an actor isolated type, like `MainActorClass`,
/// conforms to a protocol with synchronous and non-isolated functions, like `IntentionallyNonIsolatedProtocol`.
/// To see the errors please remove the `@preconcurrency` in line 72)
///
///
/// To run this code:
/// 1- Go to ContentView.swift.
/// 2- Uncomment the `PreconcurrencyConformanceView()` line in the `body` property
/// 3- Comment out the initializations of other views in the `body` property.
///

struct PreconcurrencyConformanceView: View {
    var body: some View {
        VStack {
            Text("Preconcurrency protocol conformance!")
        }
        .padding()
        .task {
            await nonMainActorIsolatedFunc()
        }
    }
    
    nonisolated func nonMainActorIsolatedFunc() async {
        ///
        /// Example 1: instance1 is `MainActorClass` so the compiler
        /// forces us to use an await to call its isolated `function1`
        ///
        let instance1 = MainActorClass()
        await instance1.function1()
        
        /// Example 2: instance2 type is abstracted to `IntentionallyNonIsolatedProtocol`
        /// The compiler doesn't force the use of `await` when we trigger`functions1` even though
        /// the call site is not `MainActor` isolated (this is a swift bug)
        ///
        /// Two scenarios here:
        /// 1-`MainActor.assertIsolated()` in `function1()` will crash the app as expected.
        /// 2- Removing the assertion stops the crash and we can trigger `MainActor` isolated calls from `function1` without using `await` (incorrect behaviour).
        ///
        /// Note: the `print(#isolation)` line prints `MainActor` in both scenarios.
        ///
        /// Swift bug: https://github.com/swiftlang/swift/issues/76507
        ///
        let instance2: IntentionallyNonIsolatedProtocol = MainActorClass()
        instance2.function1()
        
        /// Same behaviour as above
        Task.detached {
            instance2.function1()
        }
    }
}

// MARK: - Non-isolated, non-sendable protocol

fileprivate protocol IntentionallyNonIsolatedProtocol {
    func function1()
}

@MainActor
fileprivate class MainActorClass: @preconcurrency IntentionallyNonIsolatedProtocol {
    func function1() {
        print(#isolation)
        MainActor.assertIsolated("not running on the main actor")
    }
}
