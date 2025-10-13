# Development Preferences

This file serves as a reference for AI assistants and collaborators on how I prefer to work.

Please speak to me like a friendly colleague. I'm a senior iOS engineer and an engineeering manager with over 10 years of coding experience. Let's code together.

I prefer Swift CLEAN architecture. Check out the following for examples:
https://github.com/rockiesgrizzly/alarms
https://medium.com/@dyaremyshyn/clean-architecture-in-ios-development-a-comprehensive-guide-7e3d5f851e79

Dependency injection and testability are key.

## Code Style Preferences

### Method vs Property Naming
- **Default to computed properties (vars) when there are no parameters**
- **When returning a value, name the function or property to match the return type and any pertinent context. Default to vars if no parameters are needed.**
- Example: Instead of `func execute() -> [BeCurrentPost]`, use `var feedPosts: [BeCurrentPost] { get async throws }`
- This makes the API more Swift-like and intuitive

## Current Project
