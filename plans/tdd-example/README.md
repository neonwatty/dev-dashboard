# TDD Example Feature Plan

## Overview
This example demonstrates how Test-Driven Development (TDD) and linting are integrated into our planning workflow. We'll implement a simple user notification system following TDD principles.

## Goals
- **Primary**: Implement user notifications with TDD approach
- **Secondary**: Demonstrate linting integration in workflow
- **Success Criteria**: 100% test coverage, zero linting errors

## Requirements
- **Functional**: Users can receive and dismiss notifications
- **Non-functional**: Fast rendering, accessible UI
- **Constraints**: Must follow existing Rails patterns

## Todo List
- [ ] Task 1: Write failing tests for Notification model (Agent: test-runner-fixer, Priority: High)
- [ ] Task 2: Write failing tests for NotificationsController (Agent: test-runner-fixer, Priority: High)
- [ ] Task 3: Implement Notification model to pass tests (Agent: ruby-rails-expert, Priority: High)
- [ ] Task 4: Run RuboCop and fix Ruby linting issues (Agent: ruby-linter-rubocop, Priority: High)
- [ ] Task 5: Implement NotificationsController (Agent: ruby-rails-expert, Priority: High)
- [ ] Task 6: Run RuboCop on controller code (Agent: ruby-linter-rubocop, Priority: High)
- [ ] Task 7: Write failing UI component tests (Agent: test-runner-fixer, Priority: Medium)
- [ ] Task 8: Implement notification UI components (Agent: javascript-package-expert, Priority: Medium)
- [ ] Task 9: Run ESLint and fix JavaScript issues (Agent: javascript-linter, Priority: High)
- [ ] Task 10: Style notification components (Agent: tailwind-css-expert, Priority: Medium)
- [ ] Task 11: Integration testing (Agent: test-runner-fixer, Priority: Medium)
- [ ] Task 12: Final linting check all files (Agent: ruby-linter-rubocop, Priority: High)

## Implementation Phases

### Phase 1: Test Development (Duration: 2 hours)
**Agent**: test-runner-fixer
**Tasks**:
1. Write RSpec tests for Notification model
   - Test validations, associations, scopes
   - Test instance methods
2. Write controller tests for CRUD operations
3. Write JavaScript component tests
**Dependencies**: None
**Deliverables**: Complete failing test suite
**Quality Gates**: All tests properly fail (red phase)

### Phase 2: Model Implementation (Duration: 1 hour)
**Agent**: ruby-rails-expert
**Tasks**:
1. Create Notification model with validations
2. Add associations and scopes
3. Implement instance methods
**Dependencies**: Failing model tests from Phase 1
**Deliverables**: Working Notification model
**Quality Gates**: Model tests pass (green phase)

### Phase 3: Ruby Linting (Duration: 30 minutes)
**Agent**: ruby-linter-rubocop
**Tasks**:
1. Run `rubocop app/models/notification.rb`
2. Fix any style violations
3. Ensure code follows Ruby style guide
**Dependencies**: Notification model implementation
**Deliverables**: Clean, linted model code
**Quality Gates**: Zero RuboCop offenses

### Phase 4: Controller Implementation (Duration: 1 hour)
**Agent**: ruby-rails-expert
**Tasks**:
1. Implement NotificationsController actions
2. Add proper error handling
3. Implement JSON responses
**Dependencies**: Passing model tests, linted model
**Deliverables**: Working controller
**Quality Gates**: Controller tests pass

### Phase 5: Controller Linting (Duration: 30 minutes)
**Agent**: ruby-linter-rubocop
**Tasks**:
1. Run `rubocop app/controllers/notifications_controller.rb`
2. Fix style violations
3. Refactor for clarity if needed
**Dependencies**: Controller implementation
**Deliverables**: Clean controller code
**Quality Gates**: Zero RuboCop offenses

### Phase 6: UI Implementation (Duration: 2 hours)
**Agent**: javascript-package-expert
**Tasks**:
1. Create notification Stimulus controller
2. Implement notification display logic
3. Add dismiss functionality
**Dependencies**: Failing UI tests, working backend
**Deliverables**: Working UI components
**Quality Gates**: JavaScript tests pass

### Phase 7: JavaScript Linting (Duration: 30 minutes)
**Agent**: javascript-linter
**Tasks**:
1. Run ESLint on all JavaScript files
2. Fix any violations
3. Ensure modern JavaScript patterns
**Dependencies**: UI implementation
**Deliverables**: Clean JavaScript code
**Quality Gates**: Zero ESLint errors

### Phase 8: Styling (Duration: 1 hour)
**Agent**: tailwind-css-expert
**Tasks**:
1. Style notification components
2. Add responsive design
3. Implement animations
**Dependencies**: Working UI components
**Deliverables**: Styled notifications
**Quality Gates**: Responsive on all devices

### Phase 9: Final Quality Check (Duration: 30 minutes)
**Agent**: ruby-linter-rubocop
**Tasks**:
1. Run full project linting
2. Verify all tests still pass
3. Check test coverage
**Dependencies**: All implementation complete
**Deliverables**: Production-ready code
**Quality Gates**: 100% tests pass, zero linting errors

## Agent Delegation Plan
```
DELEGATION SEQUENCE:
1. test-runner-fixer: Write all failing tests
   - Success criteria: Complete test suite that fails
   - Handoff trigger: All test files created

2. ruby-rails-expert: Implement backend
   - Dependencies: Failing tests
   - Completion signal: Backend tests pass

3. ruby-linter-rubocop: Lint Ruby code
   - Dependencies: Ruby implementation
   - Completion signal: Zero violations

4. javascript-package-expert: Implement UI
   - Dependencies: Working backend, failing UI tests
   - Completion signal: UI tests pass

5. javascript-linter: Lint JavaScript
   - Dependencies: JavaScript implementation
   - Completion signal: Zero ESLint errors

6. tailwind-css-expert: Style components
   - Dependencies: Working UI
   - Completion signal: Responsive design complete

7. ruby-linter-rubocop: Final quality check
   - Dependencies: All implementation
   - Completion signal: All quality gates pass
```

## Risk Assessment
- **Risk 1**: Tests might be incomplete → Mitigation: Review test coverage reports
- **Risk 2**: Linting rules conflict → Mitigation: Use project-specific configs
- **Risk 3**: TDD slows development → Mitigation: Tests catch bugs early, saving time

## Test-Driven Development Strategy
- **TDD Cycle**: Red → Green → Refactor → Lint
- **Test Coverage Target**: 100% for new code
- **Unit Tests**: Model validations, controller actions
- **Integration Tests**: Full user workflows
- **UI Tests**: Component behavior and interactions

## Code Quality Standards
- **Ruby Linting**: 
  - RuboCop with project `.rubocop.yml`
  - No offenses allowed in new code
- **JavaScript Linting**:
  - ESLint with project config
  - Modern ES6+ syntax required
- **Pre-commit**: Tests and linting must pass

## Success Metrics
- [ ] 100% test coverage on new code
- [ ] Zero RuboCop offenses
- [ ] Zero ESLint errors
- [ ] All tests passing
- [ ] Sub-100ms response times

## Automatic Execution Command
```bash
Task(description="Execute TDD notification feature",
     subagent_type="project-orchestrator",
     prompt="Execute the plan at plans/tdd-example/README.md following strict TDD with linting at each phase")
```

## Resources
- [RSpec Best Practices](https://www.betterspecs.org/)
- [RuboCop Style Guide](https://rubocop.org/)
- [ESLint Rules](https://eslint.org/docs/rules/)
- [TDD in Rails](https://guides.rubyonrails.org/testing.html)