# CLAUDE.md

## Project Overview

This is a Swift/SwiftUI application targeting iOS and watchOS platforms, built with a focus on functional programming principles, value types, and comprehensive testing.

## Architecture & Design Principles

### Core Principles
- **Pure Functional Style**: Emphasize pure functions, immutability, and predictable data flow
- **Value Types First**: Prefer `struct` and `enum` over `class` wherever possible
- **SwiftData Integration**: Modern data persistence with type-safe model definitions
- **Declarative UI**: Leverage SwiftUI's declarative paradigm for both iOS and watchOS

### Project Structure
```
Project/
├── Shared/                 # Shared code between iOS and watchOS
│   ├── Models/            # SwiftData models and value types
│   ├── ViewModels/        # Observable view models (structs when possible)
│   ├── Services/          # Business logic and data services
│   └── Utilities/         # Helper functions and extensions
├── iOS/                   # iOS-specific implementation
│   ├── Views/            # iOS SwiftUI views
│   ├── Navigation/       # iOS navigation logic
│   └── Resources/        # iOS assets and configurations
├── watchOS/              # watchOS-specific implementation
│   ├── Views/           # watchOS SwiftUI views
│   ├── Complications/   # Watch complications
│   └── Resources/       # watchOS assets and configurations
└── Tests/               # Unit and integration tests
    ├── SharedTests/     # Tests for shared components
    ├── iOSTests/       # iOS-specific tests
    └── watchOSTests/   # watchOS-specific tests
```

## Development Setup

### Prerequisites
- Xcode 15.0+
- iOS 17.0+ / watchOS 10.0+
- Swift 5.9+

### Initial Setup
1. Clone the repository
2. Open the `.xcodeproj` file in Xcode
3. Swift Package Manager dependencies will resolve automatically
4. Build and run on your preferred simulator/device

### Code Quality Tools

#### SwiftLint
SwiftLint is configured to enforce coding standards and style consistency.

**Configuration**: See `.swiftlint.yml` in the project root

**Key Rules Enforced**:
- Line length limits
- Function complexity thresholds
- Naming conventions
- Force unwrapping detection
- Unused code identification

**Run Locally**:
```bash
swiftlint lint
swiftlint --fix  # Auto-fix certain violations
```

#### SwiftFormat
SwiftFormat ensures consistent code formatting across the project.

**Configuration**: See `.swiftformat` in the project root

**Key Formatting Rules**:
- Consistent indentation and spacing
- Import statement organization
- Trailing comma handling
- Brace style standardization

**Run Locally**:
```bash
swiftformat .
```

## Coding Standards

### Value Types & Functional Programming

#### Prefer Structs Over Classes
```swift
// ✅ Preferred
struct UserProfile {
    let id: UUID
    let name: String
    let email: String

    func withUpdatedName(_ newName: String) -> UserProfile {
        UserProfile(id: id, name: newName, email: email)
    }
}

// ❌ Avoid unless reference semantics are required
class UserProfileManager {
    var profile: UserProfile
    // ...
}
```

#### Pure Functions
```swift
// ✅ Pure function - no side effects, predictable output
func calculateTotal(items: [Item]) -> Decimal {
    items.reduce(0) { $0 + $1.price }
}

// ❌ Impure function - side effects, unpredictable
func calculateTotalAndLog(items: [Item]) -> Decimal {
    let total = items.reduce(0) { $0 + $1.price }
    print("Total calculated: \(total)") // Side effect
    return total
}
```

#### Immutable Data Structures
```swift
// ✅ Immutable with transformation methods
struct AppState {
    let user: User?
    let items: [Item]

    func withNewItem(_ item: Item) -> AppState {
        AppState(user: user, items: items + [item])
    }

    func withoutItem(id: UUID) -> AppState {
        AppState(user: user, items: items.filter { $0.id != id })
    }
}
```

### SwiftData Models

#### Model Definition
```swift
@Model
final class Task {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var createdAt: Date

    init(title: String) {
        self.id = UUID()
        self.title = title
        self.isCompleted = false
        self.createdAt = Date()
    }
}
```

#### Repository Pattern for Data Access
```swift
struct TaskRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchTasks() throws -> [Task] {
        let descriptor = FetchDescriptor<Task>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func save(_ task: Task) throws {
        modelContext.insert(task)
        try modelContext.save()
    }
}
```

### SwiftUI Best Practices

#### View Composition
```swift
// ✅ Small, focused views
struct TaskRowView: View {
    let task: Task
    let onToggle: (Task) -> Void

    var body: some View {
        HStack {
            TaskStatusIcon(isCompleted: task.isCompleted)
            TaskTitleText(title: task.title)
            Spacer()
        }
        .onTapGesture {
            onToggle(task)
        }
    }
}

// ✅ Extract complex logic to computed properties
struct TaskListView: View {
    @State private var tasks: [Task] = []

    private var incompleteTasks: [Task] {
        tasks.filter { !$0.isCompleted }
    }

    private var completedTasks: [Task] {
        tasks.filter { $0.isCompleted }
    }

    var body: some View {
        // View implementation
    }
}
```

## Testing Strategy

### Unit Testing Philosophy
- **Test Pure Functions**: Focus on testing business logic and data transformations
- **Test State Changes**: Verify state transitions and data flow
- **Mock External Dependencies**: Use protocols and dependency injection for testability
- **Value Type Testing**: Leverage the predictability of value types
- **Modern Swift Testing**: Utilize Swift Testing framework for cleaner, more expressive tests

### Testing Structure

#### Model Testing
```swift
@testable import YourApp
import Testing

@Suite("Task Model Tests")
struct TaskTests {
    @Test("Task creation with default values")
    func taskCreation() {
        let task = Task(title: "Test Task")

        #expect(task.title == "Test Task")
        #expect(task.isCompleted == false)
        #expect(task.id != nil)
        #expect(task.createdAt <= Date())
    }

    @Test("Task completion toggle")
    func taskCompletion() {
        var task = Task(title: "Test Task")
        #expect(task.isCompleted == false)

        task.isCompleted = true
        #expect(task.isCompleted == true)
    }

    @Test("Task with empty title", arguments: ["", " ", "   "])
    func taskWithEmptyTitle(title: String) {
        let task = Task(title: title)
        #expect(task.title == title) // Verify behavior with edge cases
    }
}
```

#### Repository Testing
```swift
import Testing
@testable import YourApp

@Suite("Task Repository Tests")
struct TaskRepositoryTests {
    private func createTestRepository() -> TaskRepository {
        // Setup in-memory model context for testing
        let mockModelContext = createInMemoryModelContext()
        return TaskRepository(modelContext: mockModelContext)
    }

    @Test("Save and fetch single task")
    func saveTask() throws {
        let repository = createTestRepository()
        let task = Task(title: "Test Task")

        try repository.save(task)

        let savedTasks = try repository.fetchTasks()
        #expect(savedTasks.count == 1)
        #expect(savedTasks.first?.title == "Test Task")
    }

    @Test("Save multiple tasks and verify order")
    func saveMultipleTasks() throws {
        let repository = createTestRepository()
        let task1 = Task(title: "First Task")
        let task2 = Task(title: "Second Task")

        try repository.save(task1)
        try repository.save(task2)

        let savedTasks = try repository.fetchTasks()
        #expect(savedTasks.count == 2)
        // Verify tasks are ordered by creation date (newest first)
        #expect(savedTasks.first?.title == "Second Task")
    }

    @Test("Delete task")
    func deleteTask() throws {
        let repository = createTestRepository()
        let task = Task(title: "Task to Delete")

        try repository.save(task)
        #expect(try repository.fetchTasks().count == 1)

        try repository.delete(task)
        #expect(try repository.fetchTasks().count == 0)
    }

    @Test("Repository handles invalid operations gracefully")
    func invalidOperations() {
        let repository = createTestRepository()

        // Test fetching from empty repository
        #expect(throws: Never.self) {
            _ = try repository.fetchTasks()
        }
    }
}
```

#### View Model Testing
```swift
import Testing
@testable import YourApp

@Suite("Task List View Model Tests")
struct TaskListViewModelTests {
    @Test("Add new task")
    func addTask() {
        let viewModel = TaskListViewModel()
        let initialCount = viewModel.tasks.count

        viewModel.addTask(title: "New Task")

        #expect(viewModel.tasks.count == initialCount + 1)
        #expect(viewModel.tasks.last?.title == "New Task")
    }

    @Test("Toggle task completion")
    func toggleTaskCompletion() {
        let viewModel = TaskListViewModel()
        viewModel.addTask(title: "Test Task")

        guard let task = viewModel.tasks.first else {
            Issue.record("No task found after adding")
            return
        }

        #expect(task.isCompleted == false)

        viewModel.toggleTask(task)

        guard let updatedTask = viewModel.tasks.first else {
            Issue.record("Task disappeared after toggle")
            return
        }

        #expect(updatedTask.isCompleted == true)
    }

    @Test("Remove task")
    func removeTask() {
        let viewModel = TaskListViewModel()
        viewModel.addTask(title: "Task to Remove")

        guard let task = viewModel.tasks.first else {
            Issue.record("No task found after adding")
            return
        }

        let initialCount = viewModel.tasks.count
        viewModel.removeTask(task)

        #expect(viewModel.tasks.count == initialCount - 1)
        #expect(!viewModel.tasks.contains { $0.id == task.id })
    }

    @Test("Filter completed tasks")
    func filterCompletedTasks() {
        let viewModel = TaskListViewModel()
        viewModel.addTask(title: "Task 1")
        viewModel.addTask(title: "Task 2")
        viewModel.addTask(title: "Task 3")

        // Complete first and third tasks
        if let firstTask = viewModel.tasks.first {
            viewModel.toggleTask(firstTask)
        }
        if let thirdTask = viewModel.tasks.dropFirst(2).first {
            viewModel.toggleTask(thirdTask)
        }

        let completedTasks = viewModel.completedTasks
        let incompleteTasks = viewModel.incompleteTasks

        #expect(completedTasks.count == 2)
        #expect(incompleteTasks.count == 1)
        #expect(completedTasks.allSatisfy { $0.isCompleted })
        #expect(incompleteTasks.allSatisfy { !$0.isCompleted })
    }
}

@Suite("Task List View Model Edge Cases")
struct TaskListViewModelEdgeCaseTests {
    @Test("Add task with empty title", arguments: ["", " ", "   "])
    func addTaskWithEmptyTitle(title: String) {
        let viewModel = TaskListViewModel()
        let initialCount = viewModel.tasks.count

        viewModel.addTask(title: title)

        // Verify behavior - app might reject empty titles or handle them
        #expect(viewModel.tasks.count >= initialCount)
    }

    @Test("Toggle non-existent task")
    func toggleNonExistentTask() {
        let viewModel = TaskListViewModel()
        let fakeTask = Task(title: "Fake Task")

        // This should handle gracefully without crashing
        #expect(throws: Never.self) {
            viewModel.toggleTask(fakeTask)
        }
    }
}
```

### Test Coverage Goals
- **Business Logic**: 90%+ coverage for pure functions and data transformations
- **Data Layer**: 85%+ coverage for repositories and data access
- **View Models**: 80%+ coverage for state management logic

### Running Tests
```bash
# Run all tests in Xcode
cmd+U

# Run tests from command line
swift test

# Run tests for specific platform
swift test --destination 'platform=iOS Simulator,name=iPhone 15'

# Run specific test suite
swift test --filter TaskRepositoryTests

# Run with test coverage
swift test --enable-code-coverage

# Generate and view test coverage report
xcrun llvm-cov show .build/debug/YourAppPackageTests.xctest/Contents/MacOS/YourAppPackageTests \
    --instr-profile .build/debug/codecov/default.profdata \
    --format html --output-dir coverage-report
```

### Swift Testing Advantages
- **Natural language**: Test names and descriptions are more readable
- **Powerful expectations**: `#expect` provides clear, expressive assertions
- **Parameterized tests**: Test multiple inputs with `arguments:` parameter
- **Async/await support**: Built-in support for modern Swift concurrency
- **Issue tracking**: `Issue.record()` for custom failure reporting
- **Suite organization**: `@Suite` for logical test grouping

## Platform-Specific Considerations

### iOS Implementation
- Full feature set with complex navigation
- Rich interactions and animations
- Comprehensive data entry capabilities
- Background processing and notifications

### watchOS Implementation
- Simplified, glanceable interface
- Focus on essential actions and quick interactions
- Optimized for small screen real estate
- Leverage complications and watch-specific APIs

### Shared Code Strategy
- Business logic and data models in Shared framework
- Platform-specific UI implementations
- Consistent data synchronization between platforms

## Dependencies

### Swift Package Manager
Add dependencies through Xcode's Package Manager:
1. File → Add Package Dependencies
2. Enter package URL
3. Select version requirements
4. Add to appropriate targets

### Current Dependencies
- None currently (using only system frameworks)

## Build Configuration

### Debug Configuration
- Enable all debugging symbols
- SwiftLint warnings as errors
- Comprehensive logging
- Development-specific feature flags

### Release Configuration
- Optimized compilation
- Strip debugging symbols
- Disable development logging
- Production feature flags

## Contributing Guidelines

### Code Review Checklist
- [ ] Follows functional programming principles
- [ ] Uses value types where appropriate
- [ ] Includes appropriate unit tests
- [ ] Passes SwiftLint and SwiftFormat checks
- [ ] Maintains SwiftData model consistency
- [ ] Updates documentation as needed

### Git Workflow

- Don't include the following Claude Code signature in git commit messages:
```
🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

1. Create feature branch from `main`
2. Implement changes with tests
3. Run code quality tools
4. Submit pull request with clear description
5. Address review feedback
6. Merge after approval

## Performance Considerations

### SwiftUI Performance
- Use `@State` and `@Binding` appropriately
- Leverage `@ViewBuilder` for conditional views
- Minimize view re-computation with proper state management
- Use `LazyVStack`/`LazyHStack` for large lists

### SwiftData Performance
- Design efficient fetch descriptors
- Use relationships appropriately
- Consider batch operations for large data sets
- Monitor Core Data performance in Instruments

## Troubleshooting

### Common Issues
1. **Build Errors**: Clean build folder and derived data
2. **SwiftLint Failures**: Run `swiftlint --fix` to auto-resolve
3. **Test Failures**: Ensure in-memory contexts for data tests
4. **Package Resolution**: Reset package caches in Xcode

### Debug Tools
- Xcode debugger with breakpoints
- SwiftUI view hierarchy inspector
- Instruments for performance profiling
- Console app for device logs

---

## Project Status

This document represents the current state and standards for the project. Updates should be made as the project evolves and new patterns are established.

## Development Notes

### Build Environment
- **Always use iPhone 16 to build the project**