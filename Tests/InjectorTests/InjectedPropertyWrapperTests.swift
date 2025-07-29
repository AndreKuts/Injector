//
//  InjectedPropertyWrapperTests.swift
//  Injector
//
//  Created by Andrew Kuts
//

import Testing
import Injector

@Suite(.serialized)
struct InjectedPropertyWrapperTests {

    struct MockService: Equatable {}

    @Test
    func resolvesInjectedValue() {

        class TestStruct {
            @Injected var service: MockService
        }

        let injector = DependencyInjector()
        injector.inject(for: .both) { _ in MockService() }
        InjectorRegistry.register(injector)

        let instance = TestStruct()
        #expect(instance.service == MockService())
    }

    @Test
    func resolvesInjectedOptionalValue() {

        class TestStruct {
            @Injected var service: MockService?
        }

        let injector = DependencyInjector()
        injector.inject(for: .both) { _ in MockService() }
        InjectorRegistry.register(injector)

        let instance = TestStruct()
        #expect(instance.service != nil, "The `service` should be resolved correctly")
    }
}
