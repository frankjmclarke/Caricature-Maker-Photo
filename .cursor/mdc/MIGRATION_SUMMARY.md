# Migration Summary: .cursorrules → .mdc Architecture

## What Changed

The monolithic `.cursorrules` file has been refactored into a modular `.mdc` instruction system for better context precision and maintainability.

## New Structure

```
.cursorrules                    # Minimal invariants (always-on)
.cursor/mdc/
  ├── swiftui-architecture.mdc  # MVVM patterns, SwiftUI conventions
  ├── data-persistence.mdc      # Storage strategy, secrets management
  ├── domain-calories.mdc       # Business logic, calculations, philosophy
  ├── ui-design-system.mdc      # Visual style, copy tone
  ├── onboarding-paywall.mdc   # Onboarding flow, paywall integration
  ├── networking-ai.mdc         # API calls, AI service
  ├── testing-workflow.mdc      # Testing patterns, flags
  ├── production-deployment.mdc # Pre-submission checklist
  └── ai-assistant-behavior.mdc # Code generation standards
```

## Rule Migration

### Always-On Rules → `.cursorrules`
- Swift version and framework requirements
- Security invariants (no secrets in code)
- Git practices

### Architecture Rules → `swiftui-architecture.mdc`
- MVVM-lite pattern
- State management (@State, @StateObject, @ObservedObject)
- Navigation patterns
- Code organization

### Data Rules → `data-persistence.mdc`
- UserDefaults vs SwiftData decisions
- API key management
- Testing flags location

### Domain Rules → `domain-calories.mdc`
- App philosophy ("measurement, not judgment")
- Calculation methods (BMR, TDEE)
- Evaluation logic (weekly averages)

### UI Rules → `ui-design-system.mdc`
- Visual style guidelines
- Copy tone requirements

### Feature Rules → `onboarding-paywall.mdc`
- Onboarding flow logic
- Paywall integration details

### Service Rules → `networking-ai.mdc`
- AI service patterns
- Network best practices

### Testing Rules → `testing-workflow.mdc`
- Testing flags usage
- Test coverage expectations

### Deployment Rules → `production-deployment.mdc`
- Pre-submission checklist
- Build configuration

### AI Behavior Rules → `ai-assistant-behavior.mdc`
- Code generation standards
- Code quality principles

## Resolved Collisions

1. **Testing Flags**: Moved from "Persistence" to dedicated `testing-workflow.mdc` - these are workflow concerns, not data storage
2. **Code Output Requirements**: Separated into `ai-assistant-behavior.mdc` - this is about AI behavior, not code structure
3. **Production Readiness**: Extracted to `production-deployment.mdc` - deployment is a distinct workflow from development

## Benefits

- **Context Precision**: Each `.mdc` file contains only related rules
- **Selective Attachment**: Rules can be attached only when relevant
- **Reduced Collisions**: Related rules grouped together, conflicts separated
- **Maintainability**: Clear scope for each file, easier to update

## Usage

Attach specific `.mdc` files when working on:
- UI changes → `ui-design-system.mdc`
- Data layer → `data-persistence.mdc`
- Business logic → `domain-calories.mdc`
- Onboarding/paywall → `onboarding-paywall.mdc`
- Testing → `testing-workflow.mdc`
- Pre-submission → `production-deployment.mdc`

The minimal `.cursorrules` always applies as base constraints.
