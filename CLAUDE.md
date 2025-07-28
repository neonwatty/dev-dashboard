# Claude Code Agent System

## Quick Start

1. **Simple Tasks** → Direct to specialist agent
2. **Complex Tasks** → Use `project-orchestrator` 
3. **Errors** → Auto-escalate to `error-debugger`

## Agent Reference

| Agent | Use For | Trigger Keywords |
|-------|---------|------------------|
| 🚂 `ruby-rails-expert` | Rails models, controllers, migrations | rails, model, controller, activerecord |
| 📦 `javascript-package-expert` | npm/yarn, JS/TS code, Stimulus | npm, javascript, package, stimulus |
| 🎨 `tailwind-css-expert` | Styling, UI, responsive design | css, tailwind, styling, ui |
| 🧪 `test-runner-fixer` | Write/fix tests, coverage | test, spec, rspec, coverage |
| 🐛 `error-debugger` | Debug errors, performance | error, bug, failing, debug |
| 📋 `project-orchestrator` | Planning, coordination | plan, coordinate, complex |
| 🔀 `git-auto-commit` | Create commits | commit, save changes |

## Workflow

See visual workflow: [workflow-diagram.md](.claude/workflow-diagram.md)

## Communication Protocol

All agents use standardized JSON protocol: [communication-protocol.md](.claude/communication-protocol.md)

## Router Configuration

Automatic agent selection rules: [router.yaml](.claude/router.yaml)

## Task Master Integration

**Import Task Master commands:**
@./.taskmaster/CLAUDE.md

All agents automatically:
- Update task status via `mcp__task-master-ai__set_task_status`
- Log progress via `mcp__task-master-ai__update_subtask`

## Starting Complex Tasks

```bash
Task(description="Brief description",
     subagent_type="project-orchestrator", 
     prompt="Create automatic workflow for: [detailed requirements]")
```

The orchestrator will:
1. Analyze requirements
2. Create delegation plan
3. Launch specialist agents
4. Monitor progress
5. Handle errors/escalations
6. Trigger git commit when complete

## Agent Communication Flow

```
User Request → Analyze → Route to Agent → Execute → Report → Next Agent/Complete
                  ↓
              [Complex?] → project-orchestrator → Delegation Plan
```

## Error Handling

Automatic escalation chain:
1. Specialist agent attempts fix
2. Escalate to `error-debugger`
3. Escalate to `project-orchestrator`
4. Replan and reassign

## Best Practices

- Let orchestrator handle multi-domain tasks
- Trust automatic handoffs
- Check Task Master for progress
- Agents complete work before handoff
- Use structured completion reports

## Important Instructions

- Do what's asked; nothing more, nothing less
- Never create files unless necessary
- Always prefer editing existing files
- No unsolicited documentation creation

For detailed agent capabilities, see individual agent files in `.claude/agents/`