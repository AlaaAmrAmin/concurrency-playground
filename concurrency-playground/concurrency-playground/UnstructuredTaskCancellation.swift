//
//  PreconcurrencyConformance.swift
//  ConcurrencyProtocolMismatch
//
//  Created by Alaa Amin on 18/10/2024.
//

import SwiftUI

///
/// Objective: This sample demonstrates that unstructured tasks
/// (created using `Task {}` or `Task.detached {}`) do not get
/// automatically canceled when their parent task is canceled.
/// It highlights the independent lifecycle of unstructured tasks.
///
/// To run this code:
/// 1- Go to ContentView.swift.
/// 2- Uncomment the `UnstructuredTaskCancellationView()` line in the `body` property
/// 3- Comment out the initializations of other views in the `body` property.
///

struct UnstructuredTaskCancellationView: View {
    var body: some View {
        VStack {
            Text("Unstructured task cancellation!")
        }
        .padding()
        .task {
            await test()
        }
    }
    
    nonisolated func test() async {
        let task1 = Task {
            print("Task 1")
            
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            print("Is task 1 cancelled: \(Task.isCancelled)") // Should be true because of `task1.cancel()` call in line 46
            
            Task {
                print("Task 2")
                print("Is task 2 cancelled: \(Task.isCancelled)") // Should be false
            }
        }
        
        task1.cancel()
        await task1.value
    }
}
