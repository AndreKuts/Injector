//  MIT License
//
//  Copyright (c) 2025 Andrew Kuts
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.


/**
 `AsyncInjector` defines an interface for asynchronous dependency injection using Swift's `actor` model.
 
 This protocol enables safe injection, ejection, and retrieval of dependencies in concurrency contexts.
 */
public protocol AsyncInjector: AnyObject {

    /**
     Asynchronously injects a dependency into the internal state using the specified injection type.

     - Parameters:
     - injectType: The strategy to use (e.g. `.singleton`, `.factory`, or `.both`).
     - builder: A closure that builds and returns the dependency instance.
     */
    func inject<T>(for injectType: InjectingType, typeBuilder builder: @escaping (any AsyncInjector) -> T) async

    /**
     Asynchronously removes a dependency from the internal state.

     - Parameters:
        - type: The type of the dependency to remove.
        - injectType: The strategy that determines which container(s) to remove the dependency from.
     */
    func eject<T>(type: T.Type, from injectType: InjectingType) async

    /**
     Asynchronously retrieves a dependency of the specified type.

     - Parameter injectType: The strategy to use for lookup (singleton, factory, or both).
     - Returns: The resolved dependency instance.
     - Precondition: The dependency must be registered; otherwise, the method will crash.
     */
    func extract<T>(from injectType: InjectingType) async -> T

    /**
     Asynchronously attempts to retrieve a dependency of the specified type, or throws if not found.
     
     - Parameter injectType: The strategy to use for lookup.
     - Returns: The resolved dependency instance.
     - Throws: `InjectorError.typeNotFound` if the dependency is not registered.
     */
    func extractThrows<T>(from injectType: InjectingType) async throws -> T

    /**
     Extracts a dependency from the injector's state.

     - Parameters:
        - injectType: The type of injection (`singleton`, `factory`, or `both`).

     - Returns: The extracted dependency of type `T?`.
     */
    func extractOptional<T>(from injectType: InjectingType) async -> T?
}


public actor AsyncDependencyInjector: @preconcurrency AsyncInjector {

    private var singletons: [ObjectIdentifier: Any] = [:]
    private var factories: [ObjectIdentifier: Any] = [:]

    public init() { }

    func extract<T>() async -> T {
        await extract(from: .both)
    }

    public func inject<T>(for injectType: InjectingType, typeBuilder builder: @escaping (any AsyncInjector) -> T) async {
        switch injectType {

        case .singleton:
            singletons[ObjectIdentifier(T.self)] = builder(self)

        case .factory:
            factories[ObjectIdentifier(T.self)] = builder

        case .both:
            singletons[ObjectIdentifier(T.self)] = builder(self)
            factories[ObjectIdentifier(T.self)] = builder
        }
    }

    public func eject<T>(type: T.Type, from injectType: InjectingType) async {
        switch injectType {

        case .singleton:
            singletons.removeValue(forKey: ObjectIdentifier(T.self))

        case .factory:
            factories.removeValue(forKey: ObjectIdentifier(T.self))

        case .both:
            singletons.removeValue(forKey: ObjectIdentifier(T.self))
            factories.removeValue(forKey: ObjectIdentifier(T.self))
        }
    }

    public func extract<T>(from injectType: InjectingType) async -> T {
        switch injectType {
        case .singleton:
            if let singleton = singletons[ObjectIdentifier(T.self)] as? T {
                return singleton
            } else {
                fatalError("Error: Unable to extract type as a singleton for an unregistered type: \(T.self)")
            }

        case .factory:
            if let factory = factories[ObjectIdentifier(T.self)] as? (any AsyncInjector) -> T {
                return factory(self)
            } else {
                fatalError("Error: Unable to extract type as a factory for an unregistered type: \(T.self)")
            }

        case .both:
            if let singleton = singletons[ObjectIdentifier(T.self)] as? T {
                return singleton
            } else if let factory = factories[ObjectIdentifier(T.self)] as? (any AsyncInjector) -> T {
                return factory(self)
            } else {
                fatalError("Error: Unable to extract type as a singleton or factory for an unregistered type: \(T.self)")
            }
        }
    }

    public func extractThrows<T>(from injectType: InjectingType) async throws -> T {
        switch injectType {
        case .singleton:
            if let singleton = singletons[ObjectIdentifier(T.self)] as? T {
                return singleton
            } else {
                throw InjectorError.typeNotFound(message: "Error: Unable to extract type as a singleton for an unregistered type: \(T.self)")
            }

        case .factory:
            if let factory = factories[ObjectIdentifier(T.self)] as? (any AsyncInjector) -> T {
                return factory(self)
            } else {
                throw InjectorError.typeNotFound(message: "Error: Unable to extract type as a factory for an unregistered type: \(T.self)")
            }

        case .both:
            if let singleton = singletons[ObjectIdentifier(T.self)] as? T {
                return singleton
            } else if let factory = factories[ObjectIdentifier(T.self)] as? (any AsyncInjector) -> T {
                return factory(self)
            } else {
                throw InjectorError.typeNotFound(message: "Error: Unable to extract type as a singleton or factory for an unregistered type: \(T.self)")
            }
        }
    }

    public func extractOptional<T>(from injectType: InjectingType) async -> T? {

        if let optionalType = T.self as? AnyOptional.Type {

            let wrappedType = optionalType.wrappedType()
            let key = ObjectIdentifier(wrappedType)

            let value: Any? = {
                switch injectType {
                case .singleton:
                    return singletons[key]
                case .factory:
                    return (factories[key] as? (any AsyncInjector) -> Any)?(self)
                case .both:
                    return singletons[key] ?? (factories[key] as? (any AsyncInjector) -> Any)?(self)
                }
            }()

            if let casted = value {
                return casted as? T
            }

        } else {

            let key = ObjectIdentifier(T.self)

            switch injectType {
            case .singleton:
                if let value = singletons[key] as? T {
                    return value
                }

            case .factory:
                if let factory = factories[key] as? (any AsyncInjector) -> T {
                    return factory(self)
                }

            case .both:
                if let value = singletons[key] as? T {
                    return value
                } else if let factory = factories[key] as? (any AsyncInjector) -> T {
                    return factory(self)
                }
            }
        }

        return nil
    }
}
