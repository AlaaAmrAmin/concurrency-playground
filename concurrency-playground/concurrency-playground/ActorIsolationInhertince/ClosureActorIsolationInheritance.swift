//
//  ContentView.swift
//  ConcurrencyProtocolMismatch
//
//  Created by Alaa Amin on 18/10/2024.
//

import SwiftUI

///
/// Objective: This sample demonstrates how actor isolation is inherited in closures
/// It covers:
/// 1. Closures inherit the actor isolation of the surrounding context when they are not marked `@Sendable`.
/// 2. Closures marked as `@Sendable`, do not inherit actor isolation, except in the case of task closures.
///
/// To run this code:
/// 1- Go to ContentView.swift.
/// 2- Uncomment the `ClosureIsolationInheritanceView()` line in the `body` property
/// 3- Comment out the initializations of other views in the `body` property.
///
struct ClosureIsolationInheritanceView: View {
    var body: some View {
        VStack {
            Text("Actor inheritance in closures")
        }
        .padding()
        .task {
            MainActor.assertIsolated()
            
            ///
            /// Example 1: This closure inherits the isolation of the actor because it not `Sendable`
            ///
            let isolatedClosure: () async -> Void = {
                print("In MainActor isolated closure")
                               
                // We can call a `MainActor` isolated function without an await
                isolatedToMainActor()
            }
           
            await isolatedClosure()
            
            ///
            /// Example 2: This closure doesn't inherit the isolation of the actor because it `Sendable`.
            /// The exception to this rule is the Task's closure. It inherit's the actor's isolation
            ///
            let nonisolatedClosure: @Sendable () async -> Void = {
                print("In non-isolated closure")
                
                // Cann't call a `MainActor` isolated function without an await because the closure is nonisolated
                await isolatedToMainActor()
            }
            
            await nonisolatedClosure()

            ///
            /// When we create a `TaskRunner` type (line 75) to use instead of a Task, allowing us to replace it in our test case
            /// and avoid using `Expectation`, we lose the actor inheritance, even though our action parameter
            /// uses the same signature that's used in the Task's.
            ///
            TaskRunner().run {
                // Cann't call `isolatedToMainActor` function without an await
                await isolatedToMainActor()
            }
        }
    }
    
    func isolatedToMainActor() {}
}


fileprivate class TaskRunner {
    public init() { }
    
    public func run(action: sending @escaping @isolated(any) () async -> Void) {
        Task {
            await action()
        }
    }
}
