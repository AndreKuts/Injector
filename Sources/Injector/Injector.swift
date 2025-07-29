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

import Foundation

/// The `Injector` protocol defines the interface for dependency injection.
public protocol Injector {

    /**
     Injects a dependency into the injector's state.

     - Parameters:
        - type: The type of injection (`singleton`, `factory`, or `both`).
        - builder: A closure that builds and returns an instance of the dependency.
     */
    func inject<T>(for injectType: InjectingType, typeBuilder builder: @escaping (any Injector) -> T)

    /**
     Ejects a dependency from the injector's state.

     - Parameters:
        - type: Type of object to eject.
        - injectType: The type of injection (`singleton`, `factory`, or `both`).
     */
    func eject<T>(type: T.Type, from injectType: InjectingType)

    /**
     Extracts a dependency from the injector's state.

     - Parameters:
        - type: The type of injection (`singleton`, `factory`, or `both`).

     - Returns: The extracted dependency of type `T`.
     */
    func extract<T>(from injectType: InjectingType) -> T

    /**
     Extracts a dependency from the injector's state, throwing an error if it does not exist.

     - Parameters:
        - injectType: The type of injection (`singleton`, `factory`, or `both`).

     - Throws: `InjectorError.typeNotFound` if the dependency is not registered.

     - Returns: The extracted dependency of type `T`.
     */
    func extractThrows<T>(from injectType: InjectingType) throws -> T

    /**
     Extracts a dependency from the injector's state

     - Parameters:
        - injectType: The type of injection (`singleton`, `factory`, or `both`).

     - Returns: The extracted dependency of type `T?`.
     */
    func extractOptional<T>(from injectType: InjectingType) -> T?
}


public extension Injector {

    /**
     Extracts a dependency from the injector's state as factory.

     - Returns: The extracted dependency of type `T`.
     */
    func extract<T>() -> T {
        extract(from: .both)
    }
}


open class DependencyInjector: Injector {

    private let queue = DispatchQueue(label: "com.dufap.dependencies.injector", attributes: .concurrent)
    private var singletons: [ObjectIdentifier: Any] = [:]
    private var factories: [ObjectIdentifier: Any] = [:]

    public init() {}

    public func inject<T>(for injectType: InjectingType, typeBuilder builder: @escaping (any Injector) -> T) {
        let key = ObjectIdentifier(T.self)
        let instance: T? = (injectType == .singleton || injectType == .both) ? builder(self) : nil

        queue.sync(flags: .barrier) {
            switch injectType {
            case .singleton:
                singletons[key] = instance!
            case .factory:
                factories[key] = builder
            case .both:
                singletons[key] = instance!
                factories[key] = builder
            }
        }
    }


    public func eject<T>(type: T.Type, from injectType: InjectingType) {

        let key = ObjectIdentifier(T.self)

        queue.sync(flags: .barrier) {

            switch injectType {
            case .singleton:
                singletons.removeValue(forKey: key)
            case .factory:
                factories.removeValue(forKey: key)
            case .both:
                singletons.removeValue(forKey: key)
                factories.removeValue(forKey: key)
            }
        }
    }

    public func extractOptional<T>(from injectType: InjectingType) -> T? {

        if let optionalType = T.self as? AnyOptional.Type {

            let wrappedType = optionalType.wrappedType()
            let key = ObjectIdentifier(wrappedType)

            let value: Any? = {
                switch injectType {
                case .singleton:
                    return singletons[key]
                case .factory:
                    return (factories[key] as? (any Injector) -> Any)?(self)
                case .both:
                    return singletons[key] ?? (factories[key] as? (any Injector) -> Any)?(self)
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
                if let factory = factories[key] as? (any Injector) -> T {
                    return factory(self)
                }

            case .both:
                if let value = singletons[key] as? T {
                    return value
                } else if let factory = factories[key] as? (any Injector) -> T {
                    return factory(self)
                }
            }
        }

        return nil
    }

    public func extractThrows<T>(from injectType: InjectingType) throws -> T {

        let key = ObjectIdentifier(T.self)

        return try queue.sync {
            switch injectType {
            case .singleton:
                if let singleton = singletons[key] as? T {
                    return singleton
                }

            case .factory:
                if let factory = factories[key] as? (any Injector) -> T {
                    return factory(self)
                }

            case .both:
                if let singleton = singletons[key] as? T {
                    return singleton
                }
                if let factory = factories[key] as? (any Injector) -> T {
                    return factory(self)
                }
            }

            throw InjectorError.typeNotFound(message: "Injector: Unable to extract \(T.self) as \(injectType). Make sure it is registered.")
        }
    }

    public func extract<T>(from injectType: InjectingType) -> T {

        let key = ObjectIdentifier(T.self)

        return queue.sync {
            switch injectType {
            case .singleton:
                if let instance = singletons[key] as? T {
                    return instance
                }

            case .factory:
                if let factory = factories[key] as? (any Injector) -> T {
                    return factory(self)
                }

            case .both:
                if let instance = singletons[key] as? T {
                    return instance
                }
                if let factory = factories[key] as? (any Injector) -> T {
                    return factory(self)
                }
            }

            preconditionFailure("Injector: Unable to extract type \(T.self) as \(injectType). Make sure it's registered.")
        }
    }
}
