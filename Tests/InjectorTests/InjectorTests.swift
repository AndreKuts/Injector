//
//  InjectorTests.swift
//  Injector
//
//  Created by Andrew Kuts
//

import Testing
import Foundation
import Injector

@Suite
struct InjectorTests {

    struct TestService: Equatable {
        let id: UUID
    }

    @Test
    func extractReturnsSameInstance() {
        let injector: any Injector = DependencyInjector()
        let service = TestService(id: .init())
        injector.inject(for: .singleton) { _ in service }
        let extracted: TestService = injector.extract(from: .singleton)

        #expect(extracted == service)
    }

    @Test
    func extractReturnsNewInstanceEachTime() {
        let injector: any Injector = DependencyInjector()
        injector.inject(for: .factory) { _ in TestService(id: .init()) }
        let a: TestService = injector.extract(from: .factory)
        let b: TestService = injector.extract(from: .factory)

        #expect(a != b)
    }

    @Test
    func extractSingletonThenFactory() {
        let injector: any Injector = DependencyInjector()
        let uuid = UUID()
        injector.inject(for: .both) { _ in TestService(id: uuid) }
        let singleton: TestService = injector.extract(from: .singleton)
        let factory: TestService = injector.extract(from: .factory)

        #expect(singleton.id == uuid)
        #expect(factory.id == uuid)
    }

    @Test
    func removesBoth() {
        let injector: any Injector = DependencyInjector()
        injector.inject(for: .both) { _ in TestService(id: .init()) }
        injector.eject(type: TestService.self, from: .both)

        #expect(throws: InjectorError.self) { try injector.extractThrows(from: .singleton) as TestService }
        #expect(throws: InjectorError.self) { try injector.extractThrows(from: .factory) as TestService }
    }

    @Test
    func missingSingletonThrowsError() {
        let injector: any Injector = DependencyInjector()

        #expect(throws: InjectorError.self) { try injector.extractThrows(from: .singleton) as TestService }
    }

    @Test
    func missingFactoryThrowsError() {
        let injector: any Injector = DependencyInjector()

        #expect(throws: InjectorError.self) { try injector.extractThrows(from: .factory) as TestService }
    }

    @Test
    func missingBothThrowsError() {
        let injector: any Injector = DependencyInjector()

        #expect(throws: InjectorError.self) { try injector.extractThrows(from: .both) as TestService }
    }

    @Test
    func getBothByDefault() {
        let injector: any Injector = DependencyInjector()
        injector.inject(for: .both) { _ in TestService(id: .init()) }
        let extracted: TestService = injector.extract()

        #expect(extracted.id != UUID())
    }

    @Test
    func removesOnlySingleton() {
        let injector: any Injector = DependencyInjector()
        injector.inject(for: .both) { _ in TestService(id: .init()) }
        injector.eject(type: TestService.self, from: .singleton)
        let factoryValue = try? injector.extractThrows(from: .factory) as TestService

        #expect(throws: InjectorError.self) { _ = try injector.extractThrows(from: .singleton) as TestService }
        #expect(factoryValue != nil)
    }

    @Test
    func removesOnlyFactory() {
        let injector: any Injector = DependencyInjector()
        injector.inject(for: .both) { _ in TestService(id: .init()) }
        injector.eject(type: TestService.self, from: .factory)
        let singletonValue = try? injector.extractThrows(from: .singleton) as TestService

        #expect(singletonValue != nil)
        #expect(throws: InjectorError.self) { _ = try injector.extractThrows(from: .factory) as TestService }
    }
}
