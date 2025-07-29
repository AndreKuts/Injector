//
//  InjectorRegistryTests.swift
//  Injector
//
//  Created by Andrew Kuts
//

import Injector
import Testing

@Suite
struct InjectorRegistryTests {

    @Test
    func registerAndResolveInjector() {
        let injector: any Injector = DependencyInjector()
        let asyncInjector: any AsyncInjector = AsyncDependencyInjector()
        InjectorRegistry.register(injector)
        let syncResolve = InjectorRegistry.resolve()
        InjectorRegistry.register(asyncInjector)
        let asyncResolve = InjectorRegistry.resolveAsync()

        #expect(syncResolve != nil)
        #expect(asyncResolve != nil)
    }

    @Test
    func threadSafetyInjector() async {
        let concurrentCount = 100_000
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<concurrentCount {
                group.addTask(operation: registerAndResolveInjector)
            }
        }
    }
}
