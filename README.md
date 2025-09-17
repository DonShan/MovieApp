# MovieApp 

A modern iOS movie discovery app built with SwiftUI, following Clean Architecture principles and MVVM pattern. The app provides seamless movie browsing, favorites management, and offline capabilities.

## Demo Video

Watch the app in action: [Google Drive Video Link](https://drive.google.com/drive/folders/1pMAGrPTpvuhoXB_saQDjntodcqcb0aVt?usp=share_link)

##  Features

- **Movie Discovery**: Browse popular movies with infinite scroll pagination
- **Favorites Management**: Add/remove movies from favorites with persistent storage
- **Offline Support**: View cached movies when offline with automatic reconnection
- **Search Functionality**: Real-time movie search with filtering
- **Modern UI**: Clean, responsive interface built with SwiftUI
- **Network Monitoring**: Automatic handling of network connectivity changes
- **Image Caching**: Efficient movie poster caching and management

##  Architecture

This project follows **Clean Architecture** with **MVVM** pattern, ensuring separation of concerns and maintainability:

### Architecture Layers

```
📁 Presentation Layer (SwiftUI Views + ViewModels)
├── Views/
│   ├── Screens/ (Main UI screens)
│   ├── Components/ (Reusable UI components)
│   └── Utils/ (UI utilities)
└── ViewModels/
    ├── FetchMoviesViewModel
    ├── FavoritesViewModel
    └── FavoritesListViewModel

📁 Domain Layer (Business Logic)
├── UseCases/ (Business logic implementation)
├── UseCaseProtocols/ (Business logic contracts)
└── Models/ (Domain models)

📁 Data Layer (Data Sources)
├── Repositories/ (Data access implementations)
├── RepositoryProtocols/ (Data access contracts)
├── Network/ (API communication)
├── LocalStorage/ (Local data persistence)
└── Models/ (Data models)

📁 DependencyInjection/ (DI Container)
└── Wrappers/ (Property wrappers for injection)
```

### Key Architectural Decisions

1. **Clean Architecture**: Clear separation between presentation, domain, and data layers
2. **MVVM Pattern**: Each view has its own ViewModel for better testability and maintainability
3. **Dependency Injection**: Custom DI container with property wrappers for loose coupling
4. **Protocol-Oriented Design**: Extensive use of protocols for abstraction and testability
5. **Repository Pattern**: Abstracted data access with protocol-based implementations

##  Technology Stack

### Core Technologies
- **SwiftUI**: Modern declarative UI framework
- **Swift 5.0**: Latest Swift language features
- **iOS 17.6+**: Target deployment version
- **Xcode 15.0**: Development environment

### Data & Storage
- **SwiftData**: Modern Core Data replacement for local persistence
- **UserDefaults**: Lightweight data storage for app preferences
- **Combine**: Reactive programming framework for data flow

### Networking
- **URLSession**: Native networking with custom API client
- **Combine Publishers**: Reactive network responses
- **Custom Error Handling**: Comprehensive API error management

### Testing
- **XCTest**: Unit and UI testing framework
- **Mock Objects**: Comprehensive mocking for isolated testing
- **Test Scripts**: Automated test execution scripts

### Dependency Management
- **Custom DI Container**: Lightweight dependency injection system
- **Property Wrappers**: `@Inject`, `@LazyInject`, `@WeakInject` for clean dependency resolution

##  Getting Started

### Prerequisites

- Xcode15 or later
- iOS 17.6+ deployment target
- macOS 14.0+ for development
- Swift 5.0+

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd MovieApp
   ```

2. **Open the project**
   ```bash
   open MovieApp/MovieApp.xcodeproj
   ```

3. **Configure API Key**
   - The app uses The Movie Database (TMDB) API
   - API key is already configured in `MovieRepositoryEndpoint.swift`
   - For production, move API key to secure configuration

4. **Build and Run**
   - Select your target device or simulator
   - Press `Cmd + R` to build and run


##  Project Structure

```
MovieApp/
├── MovieApp/
│   ├── Data/                    # Data Layer
│   │   ├── LocalStorage/        # UserDefaults management
│   │   ├── Models/              # Data models (Movie, OfflineMovie, CachedImage)
│   │   ├── Network/             # API client and endpoints
│   │   ├── Repositories/        # Data access implementations
│   │   └── RepositoryProtocols/ # Data access contracts
│   ├── DependencyInjection/     # DI container and configuration
│   ├── Domain/                  # Domain Layer
│   │   ├── Models/              # Domain models
│   │   ├── UseCases/            # Business logic
│   │   └── UseCaseProtocols/    # Business logic contracts
│   ├── Presentation/            # Presentation Layer
│   │   ├── Views/               # SwiftUI views and components
│   │   └── ViewModels/          # MVVM view models
│   ├── Utils/                   # Utility classes
│   └── Wrappers/                # Property wrappers
├── MovieAppTests/               # Unit tests
├── MovieAppUITests/             # UI tests
└── Scripts/                     # Build and test scripts
```

##  Key Components

### Dependency Injection System

Custom lightweight DI container with property wrappers:

```swift
@Inject(key: "FavoritesUseCase")
private var favoritesUseCase: FavoritesUseCaseProtocol

@LazyInject(key: "NetworkManager")
private var networkManager: NetworkManager
```

### Network Layer

- **API Client**: Custom URLSession-based client with error handling
- **Endpoints**: Type-safe API endpoint definitions
- **Error Handling**: Comprehensive error mapping and user-friendly messages
- **Connectivity Monitoring**: Real-time network status tracking

### Data Persistence

- **SwiftData**: Modern persistence for complex data (movies, favorites)
- **UserDefaults**: Lightweight storage for app preferences
- **Image Caching**: Efficient poster image caching and management

### Offline Support

- **Cached Data**: Movies are cached for offline viewing
- **Automatic Reconnection**: Smart reconnection with exponential backoff
- **Offline Indicators**: Visual feedback for network status
- **Data Synchronization**: Seamless sync when connection is restored

## Testing Strategy

- **Unit Tests**: ViewModels, UseCases, Repositories, and Utilities
- **Mock Objects**: Comprehensive mocking for all external dependencies
- **Integration Tests**: End-to-end testing of data flow
- **UI Tests**: Automated UI interaction testing

### Test Structure
```
MovieAppTests/
├── ViewModel Tests/     # ViewModel behavior testing
├── UseCase Tests/       # Business logic testing
├── Repository Tests/    # Data access testing
├── Mock Objects/        # Test doubles and mocks
└── Integration Tests/   # Cross-layer testing
```

##  Design  & Architecture

### Architecture Choices

1. **Clean Architecture + MVVM**
   - **Decision**: Separated concerns across presentation, domain, and data layers
   - **Benefit**: Improved testability, maintainability, and scalability
   - **Challenge**: Initial complexity in setup and understanding

2. **Custom Dependency Injection**
   - **Decision**: Built lightweight DI container instead of using third-party libraries
   - **Benefit**: Full control over dependency lifecycle and reduced external dependencies
   - **Challenge**: Required careful design of property wrappers and container management

3. **SwiftData over Core Data**
   - **Decision**: Used SwiftData for modern, Swift-native persistence
   - **Benefit**: Type-safe, modern API with better Swift integration
   - **Challenge**: Newer framework with limited documentation and community resources

- [ ] Widget support for quick access to favorites

##  Resources

- [Clean Architecture by Robert C. Martin](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [MVVM Pattern in iOS](https://developer.apple.com/documentation/swiftui/stateobject-and-observedobject)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Combine Framework](https://developer.apple.com/documentation/combine)
- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)


## Author

**Madushan Senavirathna**
- Clean Architecture enthusiast
- iOS Developer
- SwiftUI & Combine specialist

