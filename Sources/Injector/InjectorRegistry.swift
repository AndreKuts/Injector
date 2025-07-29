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

/// A global registry for holding references to ``Injector`` and ``AsyncInjector`` instances.
public enum InjectorRegistry {

    private static let syncRegistry = LockedValueBox<any Injector>()
    private static let asyncRegistry = LockedValueBox<any AsyncInjector>()

    /// Registers a synchronous injector instance.
    public static func register(_ injector: some Injector) {
        syncRegistry.register(injector)
    }

    /// Registers an asynchronous injector instance.
    public static func register(_ asyncInjector: some AsyncInjector) {
        asyncRegistry.register(asyncInjector)
    }

    /// Resolves the current synchronous injector, if any.
    public static func resolve() -> (any Injector)? {
        syncRegistry.resolve()
    }

    /// Resolves the current asynchronous injector, if any.
    public static func resolveAsync() -> (any AsyncInjector)? {
        asyncRegistry.resolve()
    }
}
