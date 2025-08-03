# [Feature/Task Name] Plan

## Overview
[Brief description of the task/feature and its business value]

## Goals
- **Primary**: [Main objective]
- **Secondary**: [Supporting objectives]
- **Success Criteria**: [Measurable outcomes]

## Requirements
- **Functional**: [What it must do]
- **Non-functional**: [How it must perform]
- **Constraints**: [Limitations or boundaries]

## Todo List
- [ ] Task 1: Write failing tests for [feature] (Agent: test-runner-fixer, Priority: High)
- [ ] Task 2: Implement [feature] to pass tests (Agent: [implementation-agent], Priority: High)
- [ ] Task 3: Run linting and fix issues (Agent: ruby-linter-rubocop/javascript-linter, Priority: High)
- [ ] Task 4: [Additional tasks...] (Agent: [agent-name], Priority: Medium)

## Implementation Phases

### Phase 1: Test Development (Duration: X days)
**Agent**: test-runner-fixer
**Tasks**:
1. Write comprehensive test suite following TDD
2. Define test cases for all requirements
3. Ensure tests fail initially (red phase)
**Dependencies**: Clear requirements and acceptance criteria
**Deliverables**: Complete failing test suite
**Quality Gates**: Tests properly fail for missing functionality

### Phase 2: Implementation (Duration: X days)
**Agent**: [implementation-agent]
**Tasks**:
1. Implement functionality to make tests pass
2. Follow existing code patterns and conventions
3. Refactor for clarity and performance
**Dependencies**: Failing tests from Phase 1
**Deliverables**: Working implementation
**Quality Gates**: All tests pass (green phase)

### Phase 3: Code Quality (Duration: X hours)
**Agent**: ruby-linter-rubocop or javascript-linter
**Tasks**:
1. Run appropriate linters (rubocop/eslint)
2. Fix all linting violations
3. Ensure code meets project standards
**Dependencies**: Working implementation from Phase 2
**Deliverables**: Clean, linted code
**Quality Gates**: Zero linting errors

## Agent Delegation Plan
```
DELEGATION SEQUENCE:
1. [agent-name]: [What they'll do]
   - Success criteria: [How we know it's done]
   - Handoff trigger: [What signals next phase]

2. [agent-name]: [What they'll do]
   - Dependencies: [What they need from previous phase]
   - Completion signal: [How they indicate done]
```

## Risk Assessment
- **Risk 1**: [Description] → Mitigation: [Strategy]
- **Risk 2**: [Description] → Mitigation: [Strategy]

## Test-Driven Development Strategy
- **TDD Cycle**: Red (failing tests) → Green (pass tests) → Refactor
- **Test Coverage Target**: Minimum 80% coverage
- **Unit Tests**: Test individual components/methods
- **Integration Tests**: Test component interactions
- **User Acceptance**: End-to-end scenarios
- **Test Execution**: Run after each code change

## Code Quality Standards
- **Linting Requirements**:
  - Ruby: rubocop must pass with project config
  - JavaScript: eslint must pass with project config
  - CSS: Follow Tailwind best practices
- **Pre-commit Checks**: Tests and linting must pass
- **Code Review**: Automated quality checks

## Success Metrics
- [ ] [Metric 1 with target]
- [ ] [Metric 2 with target]
- [ ] [Metric 3 with target]

## Automatic Execution Command
```bash
Task(description="Execute [feature] plan",
     subagent_type="project-orchestrator",
     prompt="Execute the plan at plans/[feature-name]/README.md with automatic agent handoffs")
```

## Resources
- [Relevant documentation links]
- [Design references]
- [Technical specifications]