# Injector

A lightweight and flexible dependency injection framework for Swift — built with simplicity, testability, and performance in mind.

---

## 🚀 Features

- ✅ Simple and expressive API for registering and resolving dependencies sync and async
- 🧩 Supports constructor and property injection  
- 🔄 Singleton and factory lifecycles  
- 🧪 Easy mocking and overrides for testing  
- 🧵 Thread-safe container resolution  
- 🧼 No runtime reflection, minimal overhead  

---

## 📦 Installation
### Swift Package Manager (Recommended)

Add the following to your `Package.swift` dependencies:

```swift
.package(url: "https://github.com/AndreKuts/Injector.git", from: "1.0.0")
```

---
## 🛠️ Usage
1. Define, Inject and Register

```swift

import Injector

// Define
protocol ApiService {
    func fetchData() -> String
}

struct DefaultApiService: ApiService {
    func fetchData() -> String { "Hey default API service" } 
}

let asyncInjector: any AsyncInjector = AsyncDependencyInjector()
let injector: any Injector = DependencyInjector()

// Inject
await asyncInjector.inject(for: .both) { injector in
    DefaultApiService() as ApiService
}

injector.inject(for: .factory) { injector in
    DefaultApiService() as ApiService
}

// Register
InjectorRegistry.register(injector)
InjectorRegistry.register(asyncInjector)

```

2. Extract 

```swift
// Extract it in a standard way.
let api: ApiService = injector.extract()
let asyncApi = await asyncInjector.extract()

// Extract as a property wrapper.
class ViewModel {
    @Injected var apiService: ApiService
}

```

