# Agent Communication Protocol

This document describes the standardized JSON protocol for agent communication and handoffs.

## Overview

All agents must use this protocol for:
- Completion reports
- Error escalations
- Task delegations
- Progress updates

## Message Types

### 1. Agent Completion Report

Used when an agent completes work (successfully or not).

```json
{
  "agent": "ruby-rails-expert",
  "status": "completed",
  "timestamp": "2024-01-20T10:30:00Z",
  "work_summary": {
    "tasks_completed": [
      "Created User model with authentication",
      "Added user controller with CRUD actions"
    ],
    "implementation_details": "Implemented full user authentication system using has_secure_password"
  },
  "files_modified": [
    {
      "path": "app/models/user.rb",
      "action": "created",
      "description": "User model with validations"
    }
  ],
  "next_phase": {
    "ready": true,
    "recommended_agent": "tailwind-css-expert",
    "reason": "UI components need styling"
  },
  "task_master_update": {
    "task_id": "4.1",
    "status_update": "Backend complete, ready for frontend"
  }
}
```

### 2. Error Report

Used when an agent encounters an error it cannot resolve.

```json
{
  "error_type": "runtime_error",
  "message": "undefined method 'authenticate' for User",
  "stack_trace": "app/controllers/sessions_controller.rb:15:in 'create'",
  "file_path": "app/controllers/sessions_controller.rb",
  "line_number": 15,
  "attempted_fixes": [
    "Checked User model for authenticate method",
    "Verified has_secure_password is included"
  ],
  "escalation_needed": true
}
```

### 3. Delegation Request

Used by orchestrator to delegate tasks to specialists.

```json
{
  "from_agent": "project-orchestrator",
  "to_agent": "ruby-rails-expert",
  "task_description": "Create authentication system with User model and sessions controller",
  "priority": "high",
  "dependencies": ["database setup complete"],
  "context": {
    "requirements": ["email/password login", "remember me functionality"],
    "constraints": ["must use built-in Rails authentication"]
  }
}
```

## Usage Guidelines

### For Specialist Agents

1. **Starting Work**: Receive delegation request or direct assignment
2. **During Work**: Update Task Master with progress
3. **Completing Work**: Send completion report with:
   - Summary of work done
   - Files modified
   - Next agent recommendation
   - Any handoff data

### For Project Orchestrator

1. **Receiving Tasks**: Analyze and create delegation plan
2. **Delegating**: Send delegation requests with full context
3. **Monitoring**: Track completion reports
4. **Handling Errors**: Reassign or modify plan as needed

### Status Values

- `completed`: All work finished successfully
- `failed`: Unable to complete, needs intervention
- `blocked`: Waiting on external dependency
- `partial`: Some work done, but not all

## Integration with Task Master

All agents should include `task_master_update` in their reports:

```json
"task_master_update": {
  "task_id": "4.1",
  "subtask_id": "4.1.1", 
  "status_update": "complete",
  "progress_notes": "User authentication implemented"
}
```

## Error Handling

When errors occur:
1. Attempt self-resolution first
2. Document attempts in error report
3. Set `escalation_needed: true` if unresolved
4. Include full context for next agent

## Best Practices

1. **Be Specific**: Include detailed file paths and descriptions
2. **Think Ahead**: Recommend logical next agents
3. **Document Context**: Pass relevant information in handoff_data
4. **Update Promptly**: Send reports immediately upon completion
5. **Handle Errors Gracefully**: Don't hide problems, escalate appropriately