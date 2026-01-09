# Module Specification: [Module Name]

## Module Overview

**Purpose:** [Brief description of what this module does]

**Business Value:** [Why this module is needed]

**Core Entities:** [List main entities/models]

---

## Domain Layer (Miller9921/flutter-domain)

### Entities

#### [EntityName]Model
Equatable model with the following properties:
- `id` (String) - Unique identifier
- `[property1]` ([type]) - [description]
- `[property2]` ([type]) - [description]
- `createdAt` (DateTime) - Creation timestamp
- `updatedAt` (DateTime?) - Last update timestamp

**Equatable Requirements:**
- const constructor
- final fields
- copyWith method
- props override

### Services

#### [ServiceName]Service
Business logic service that orchestrates repositories.

**Dependencies:**
- `I[Entity]Repository` - Main repository
- Other repository dependencies as needed

**Methods:**
- `Future<List<[Entity]Model>> getAll()` - Retrieve all items
- `Future<[Entity]Model?> getById(String id)` - Get single item
- `Future<[Entity]Model> create([Entity]Model model)` - Create new item
- `Future<[Entity]Model> update([Entity]Model model)` - Update existing item
- `Future<void> delete(String id)` - Delete item

### Repository Interfaces

#### I[Entity]Repository
Abstract interface class for data operations.

**Methods:**
- `Future<List<[Entity]Model>> getAll()`
- `Future<[Entity]Model?> getById(String id)`
- `Future<[Entity]Model> create([Entity]Model model)`
- `Future<[Entity]Model> update([Entity]Model model)`
- `Future<void> delete(String id)`

**Note:** NO use of Either, Failures, or Value Objects in Domain layer.

---

## Infrastructure Layer (Miller9921/flutter-infrastructure)

### DTOs

#### [Entity]Dto
Data Transfer Object with JSON serialization.

**Annotations:** `@JsonSerializable()`

**Properties:** (matching domain model)
- `id` (String?)
- `[property1]` ([type]?)
- `[property2]` ([type]?)
- `createdAt` (String?)
- `updatedAt` (String?)

**Methods:**
- `factory [Entity]Dto.fromJson(Map<String, dynamic> json)`
- `Map<String, dynamic> toJson()`

### Adapters

#### [Entity]Adapter
Extends `ModelAdapter<[Entity]Model, [Entity]Dto, void>`

**Methods:**
- `[Entity]Model toModel([Entity]Dto dto)` - Convert DTO to Model
- `[Entity]Dto fromModel([Entity]Model model)` - Convert Model to DTO

### API Clients

#### [Entity]Api
API client using HttpClientApi.

**Dependencies:**
- `HttpClientApi` - HTTP client service

**Methods:**
- `Future<[Entity]Dto> get[Entity](String id)` - GET single item
- `Future<List<[Entity]Dto>> getAll[Entity]s()` - GET all items
- `Future<[Entity]Dto> create[Entity]([Entity]Dto dto)` - POST new item
- `Future<[Entity]Dto> update[Entity](String id, [Entity]Dto dto)` - PUT update
- `Future<void> delete[Entity](String id)` - DELETE item

**Implementation Details:**
- Use `Uri.https` for URL construction
- Use `HttpClientApi` methods: `getRequestWithToken`, `postRequestWithToken`, etc.
- Use `ExceptionHandlerResponse.responseDataSourceTemplError` for error handling
- Define constants: `TYPE_RETURN_METHOD_GET`, `TYPE_RETURN_METHOD_POST`, etc.

### Repository Implementation

#### [Entity]RepositoryImpl
Implements `I[Entity]Repository` from Domain layer.

**Dependencies:**
- `NetworkVerify` - Network connectivity check
- `[Entity]Api` - API client
- `[Entity]Adapter` - Model/DTO adapter

**Implementation:**
- Check network before each operation
- Use API for data operations
- Use Adapter to convert between DTOs and Models
- Handle errors appropriately

### Kiwi DI Registration

```dart
// In infrastructure layer setup
container.registerFactory((c) => [Entity]Api(c.resolve()));
container.registerFactory((c) => [Entity]Adapter());
container.registerFactory<I[Entity]Repository>(
  (c) => [Entity]RepositoryImpl(
    c.resolve(),
    c.resolve(),
    c.resolve(),
  ),
);
```

---

## UI Layer (Miller9921/flutter-ui-components)

### Generic Widgets

#### [WidgetName]<T>
Generic stateless/stateful widget for [purpose].

**Type Parameters:**
- `T` - Generic type for data

**Properties:**
- `List<T> items` - Data items
- `String Function(T) displayText` - Extract display text from item
- `void Function(T) onItemSelected` - Item selection callback
- `bool? Function(T)? isSelected` - Optional selection state checker
- `ValueChanged<T>? onChange` - Optional change handler

**Styling:**
- Use `Theme.of(context)` for standard theming
- Use `ClapColors` for custom colors
- Responsive to screen size

**State Management:**
- Use StatefulWidget only when controllers needed (ScrollController, TextEditingController)
- Use setState for internal state only
- NO external state management
- NO imported models (only generic types)

### Widgetbook Preview

Create Widgetbook stories for each widget with:
- Different data scenarios
- Various configurations
- Edge cases (empty, single item, many items)

---

## Frontend Admin (Miller9921/flutter-admin-app)

### State Management

#### [Feature]State
Equatable state class.

**Properties:**
- `bool initialLoad` - Initial loading flag
- `bool error` - Error flag
- `String? errorMessage` - Error message
- `List<[Entity]Model> items` - Data items
- `[Entity]Model? selectedItem` - Currently selected item
- `bool errorAction` - Action error flag
- `bool successAction` - Action success flag

**Methods:**
- `copyWith()` - Create copy with modified properties
- `props` - Equatable props override

#### [Feature]Cubit
Cubit extending `Cubit<[Feature]State>`.

**Dependencies:**
- Services/Repositories from Domain/Infrastructure (injected via Kiwi)

**Methods:**
- `initialLoad()` - Load initial data
- `loadItems()` - Load all items
- `selectItem(String id)` - Select specific item
- `createItem([Entity]Model item)` - Create new item
- `updateItem([Entity]Model item)` - Update item
- `deleteItem(String id)` - Delete item

**Error Handling:**
- Wrap all async operations in `customTryCatch`
- Emit error states on failure
- Emit success states on completion

### Screen

#### [Feature]Screen
Screen with `@RoutePage()` annotation.

**Structure:**
- StatefulWidget
- `late final [Feature]Cubit bloc`
- `initState`: `bloc = injector.resolve()..initialLoad()`
- `dispose`: clean up bloc if needed

**UI Structure:**
```dart
AppSectionTemplateAdmin(
  child: BlocListener<[Feature]Cubit, [Feature]State>(
    bloc: bloc,
    listener: (context, state) {
      if (state.error) {
        Utils.alertToastError(context, state.errorMessage ?? 'Error');
      }
      if (state.successAction) {
        // Handle success
      }
    },
    child: BlocBuilder<[Feature]Cubit, [Feature]State>(
      bloc: bloc,
      builder: (context, state) {
        if (state.initialLoad) {
          return Utils().loadingWidget();
        }
        if (state.error && state.items.isEmpty) {
          return Utils().errorWidget();
        }
        // Main content using ui_widgets_clap
        return [MainContent];
      },
    ),
  ),
)
```

### Routing

Add to auto_router configuration:
```dart
AutoRoute(page: [Feature]Route.page, path: '/[feature-path]'),
```

### Kiwi DI Registration

```dart
container.registerFactory((c) => [Feature]Cubit(c.resolve()));
```

---

## Frontend User (Miller9921/flutter-frontuser-app)

### State Management

Same structure as Admin but with user-specific features:

#### [Feature]State
Same structure as Admin state.

#### [Feature]Cubit
Same structure as Admin cubit but with user-focused methods.

### Screens

#### [Primary]Screen
Main screen for [feature] in user app.

**Structure:** Same as Admin (StatefulWidget, BlocListener/Builder, etc.)

#### [Secondary]Screen (if applicable)
Additional screens for the feature.

### Routing

Add to auto_router configuration:
```dart
AutoRoute(page: [Primary]Route.page, path: '/[path]'),
AutoRoute(page: [Secondary]Route.page, path: '/[path2]'),
```

### Kiwi DI Registration

```dart
container.registerFactory((c) => [Feature]Cubit(c.resolve()));
```

---

## i18n Keys (Miller9921/clap_i18n)

### Manual Keys to Add

**Admin Frontend:**
```
[module].[feature].title
[module].[feature].subtitle
[module].[feature].create_button
[module].[feature].edit_button
[module].[feature].delete_button
[module].[feature].confirm_delete
[module].[feature].success_message
[module].[feature].error_message
[module].[entity].[property1]
[module].[entity].[property2]
```

**User Frontend:**
```
[module].[feature].title
[module].[feature].subtitle
[module].[feature].empty_state
[module].[feature].submit_button
[module].[entity].[property1]
[module].[entity].[property2]
```

---

## Kiwi DI Setup Summary

### Dependency Chain

```
Infrastructure Layer:
- API → Adapter → Repository

Domain Layer:
- Services (depend on Repositories)

Frontend Layers:
- Cubits (depend on Services/Repositories)
```

### Registration Order

1. Infrastructure APIs
2. Infrastructure Adapters
3. Infrastructure Repositories
4. Domain Services
5. Frontend Cubits

---

## Implementation Notes

- All async methods return `Future<T>`, NOT `Future<Either<L, R>>`
- All models extend Equatable with const constructor
- All DTOs use @JsonSerializable()
- All adapters extend ModelAdapter
- All API calls use HttpClientApi methods
- All error handling uses try/catch (not Either)
- All frontend state management uses Cubit + BlocBuilder/BlocListener
- All UI widgets are generic with type parameter `<T>`
- All routes use auto_route with @RoutePage()
- All DI uses Kiwi registerFactory

## Testing Considerations

- Unit tests for Services
- Unit tests for Repositories
- Widget tests for UI components
- Integration tests for API clients
- Cubit/Bloc tests for state management

---

**Created by CLAP Orchestrator**
**Version:** 1.0
**Last Updated:** [Date]
