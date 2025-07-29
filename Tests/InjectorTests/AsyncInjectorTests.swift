//
//  AsyncInjectorTests.swift
//  Injector
//
//  Created by Andrew Kuts
//

import Testing
import Foundation
import Injector

@Suite
struct AsyncInjectorTests {

    class AsyncMockService {

        let id: UUID

        init(id: UUID = .init()) {
            self.id = id
        }
    }

    @Test
    func extractReturnsSameInstanceForSingleton() async {
        let injector: any AsyncInjector = AsyncDependencyInjector()
        let service = AsyncMockService()
        await injector.inject(for: .singleton) { _ in service }
        let extracted: AsyncMockService = await injector.extract(from: .singleton)

        #expect(extracted === service)
    }

    @Test
    func extractReturnsNewInstanceForFactory() async {
        let injector: any AsyncInjector = AsyncDependencyInjector()
        await injector.inject(for: .factory) { _ in AsyncMockService() }
        let a: AsyncMockService = await injector.extract(from: .factory)
        let b: AsyncMockService = await injector.extract(from: .factory)

        #expect(a !== b)
    }

    @Test
    func extractBothYieldsSameValueForSingletonAndFactory() async {
        let injector: any AsyncInjector = AsyncDependencyInjector()
        let id = UUID()
        await injector.inject(for: .both) { _ in AsyncMockService(id: id) }
        let singleton: AsyncMockService = await injector.extract(from: .singleton)
        let factory: AsyncMockService = await injector.extract(from: .factory)

        #expect(singleton.id == id)
        #expect(factory.id == id)
    }

    @Test
    func ejectSingletonRemovesOnlySingleton() async {
        let injector: any AsyncInjector = AsyncDependencyInjector()
        await injector.inject(for: .both) { _ in AsyncMockService() }
        await injector.eject(type: AsyncMockService.self, from: .singleton)
        let factoryResolved = try? await injector.extractThrows(from: .factory) as AsyncMockService

        await #expect(throws: InjectorError.self) { _ = try await injector.extractThrows(from: .singleton) as AsyncMockService }
        #expect(factoryResolved != nil)
    }

    @Test
    func ejectFactoryRemovesOnlyFactory() async {
        let injector: any AsyncInjector = AsyncDependencyInjector()
        await injector.inject(for: .both) { _ in AsyncMockService() }
        await injector.eject(type: AsyncMockService.self, from: .factory)
        let singletonResolved = try? await injector.extractThrows(from: .singleton) as AsyncMockService

        await #expect(throws: InjectorError.self) { _ = try await injector.extractThrows(from: .factory) as AsyncMockService }
        #expect(singletonResolved != nil)
    }

    @Test
    func ejectBothRemovesAll() async {
        let injector: any AsyncInjector = AsyncDependencyInjector()
        await injector.inject(for: .both) { _ in AsyncMockService() }
        await injector.eject(type: AsyncMockService.self, from: .both)

        await #expect(throws: InjectorError.self) { _ = try await injector.extractThrows(from: .singleton) as AsyncMockService }
        await #expect(throws: InjectorError.self) { _ = try await injector.extractThrows(from: .factory) as AsyncMockService }
    }

    @Test
    func extractOptionalReturnsNilForMissingDependency() async {
        let injector: any AsyncInjector = AsyncDependencyInjector()
        let resolved = await injector.extractOptional(from: .singleton) as AsyncMockService?

        #expect(resolved == nil)
    }
}
