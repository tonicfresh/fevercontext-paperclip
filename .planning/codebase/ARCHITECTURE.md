# Architecture

**Analysis Date:** 2026-04-03

## Pattern Overview

**Overall:** Monorepo with modular microservice-like architecture. Paperclip is a distributed orchestration platform designed around agent coordination, where each component is independently composable and pluggable.

**Key Characteristics:**
- Multi-workspace, multi-company isolation at database/API level
- Pluggable agent adapters (Claude Local, Codex, Cursor, Gemini, OpenClaw, Hermes, Pi)
- Real-time event-driven communication via WebSocket
- Atomic task checkout and budget enforcement
- Layered service architecture with clear separation of concerns

## Layers

**Presentation Layer (UI):**
- Purpose: React-based web interface for managing companies, agents, tasks, approvals, costs
- Location: `ui/src/`
- Contains: React pages, components, hooks, context providers, adapters for different agent types
- Depends on: API routes via HTTP, live event updates via WebSocket
- Used by: End users, board members, agents

**API/Route Layer:**
- Purpose: Express.js HTTP endpoints and WebSocket handlers exposing business operations
- Location: `server/src/routes/`
- Contains: Route handlers for companies, agents, projects, issues, routines, costs, approvals, plugins
- Depends on: Service layer
- Used by: UI, CLI, agents, external integrations

**Service Layer:**
- Purpose: Core business logic encapsulation - handles companies, agents, issues, costs, budgets, approvals
- Location: `server/src/services/`
- Contains: ~35 service modules covering all domain concepts
- Key services: `companies.ts`, `agents.ts`, `issues.ts`, `costService`, `heartbeatService`, `budgetService`
- Depends on: Database, adapters, storage, messaging
- Used by: Routes, other services, cron jobs

**Adapter Layer:**
- Purpose: Agent runtime abstraction - enables plugging in different agent systems (Claude Code, Cursor, OpenClaw, etc.)
- Location: `packages/adapters/` and `ui/src/adapters/`
- Contains: Adapter implementations for each agent type
- Pattern: Each adapter implements standardized interface for task assignment, execution, status polling
- Depends on: Adapter utils, shared types
- Used by: Server runtime, UI for visualization

**Database Layer:**
- Purpose: Data persistence and schema management with Drizzle ORM
- Location: `packages/db/`
- Contains: Schema definitions, migrations, query builders
- Depends on: Embedded PostgreSQL (dev) or external Postgres (prod)
- Used by: All services via db queries

**Plugin System:**
- Purpose: Runtime extensibility - plugins can listen to events, intercept tools, manage state
- Location: `server/src/services/plugin-*.ts`, `packages/plugins/`
- Contains: Plugin SDK, lifecycle manager, worker manager, job scheduler, event bus
- Pattern: Workers in Node.js managed by plugin manager; plugins isolated in separate processes
- Depends on: Service layer, database
- Used by: Server runtime, agents

**Shared Layer:**
- Purpose: Type definitions and utilities shared across all packages
- Location: `packages/shared/`
- Contains: TypeScript interfaces for agent types, issue states, company concepts
- Depends on: Nothing
- Used by: All packages

**Storage Layer:**
- Purpose: File storage abstraction (local disk or S3)
- Location: `server/src/storage/`
- Contains: Provider registry, local provider, S3 provider
- Depends on: AWS SDK (optional), filesystem
- Used by: Asset management, company exports

## Data Flow

**Task Assignment & Execution:**

1. User creates issue/task in UI
2. API route receives POST `/issues` with details
3. Service layer validates, creates issue with "pending" state
4. If assigned to agent: adapter sends task to agent runtime (Claude Code, Cursor, etc.)
5. Agent receives context (goal ancestry, budget, permissions)
6. Agent works on task; periodic heartbeats poll adapter for status
7. Agent submits work product (code, files, approval request)
8. Service updates issue state, logs cost
9. UI receives live event update and re-renders

**Budget Enforcement:**

1. Budget service checks monthly/per-agent budgets before task checkout
2. Task state transitions to "checked_out" atomically with budget deduction
3. If agent hits budget mid-execution, heartbeat detects overage and forces halt
4. Cost service tracks all API calls (Claude, OpenAI, etc.) across projects
5. Monthly reset occurs automatically via cron

**Approval Workflow:**

1. Agent requests approval (via `/issues/{id}/request-approval`)
2. Issue state → "approval_requested"
3. Approval service creates approval record with change details
4. UI shows "Approvals" page with pending items
5. Board member reviews, approves/rejects
6. If approved: issue transitions to "completed", agent paid budget back if under spend
7. If rejected: issue returns to agent with feedback

**Live Events & Real-Time Updates:**

1. Any state change triggers `publishLiveEvent()` in service
2. WebSocket server broadcasts to connected clients subscribed to company
3. UI receives event, updates local state via React Query
4. Multiple clients stay in sync without polling

**State Management:**

- Company-scoped isolation: All data queries filtered by company ID
- Atomic transactions: Critical operations (task checkout, budget enforcement) wrapped in DB transactions
- Event sourcing for audit: Activity log captures all mutations with full context
- Persistent agent sessions: Runtime services maintain state across heartbeats

## Key Abstractions

**Issue (Task):**
- Purpose: Core work unit in the system - represents a goal/objective for agent to complete
- Examples: `server/src/routes/issues.ts`, `server/src/services/issues.ts`
- Pattern: Domain-driven - has state machine (pending → assigned → in_progress → approval_requested → completed), budget tracking, goal ancestry

**Company:**
- Purpose: Organizational unit - complete data isolation, independent agent teams, separate budgets
- Examples: `server/src/services/companies.ts`, `packages/db/schema/companies.ts`
- Pattern: Multi-tenant - all queries scoped by company ID, export/import for portability

**Agent:**
- Purpose: Team member executing tasks, has role, title, budget, instructions
- Examples: `server/src/services/agents.ts`, `packages/db/schema/agents.ts`
- Pattern: Hierarchical - agents report to other agents (org chart), each has capabilities and skills

**Adapter:**
- Purpose: Bridge between Paperclip and external agent runtime (Claude Code, Cursor, OpenClaw, etc.)
- Examples: `packages/adapters/claude-local/`, `packages/adapters/openclaw-gateway/`
- Pattern: Strategy pattern - implements `AgentAdapter` interface with methods for assign, poll, retrieve_output

**Goal:**
- Purpose: Business objective - links issues into strategy hierarchy
- Examples: `server/src/services/goals.ts`, routes handle GET/POST
- Pattern: Recursive ancestry - every issue traces back to company mission, provides context to agents

**Routine:**
- Purpose: Recurring work - scheduled via cron, executes heartbeat on intervals
- Examples: `server/src/services/routines.ts`
- Pattern: Cron-based triggers, creates issues on schedule, maintains execution history

**Skill:**
- Purpose: Reusable agent capabilities - knowledge base, tool definitions, instructions
- Examples: `server/src/services/company-skills.ts`, skill injection into agent prompts
- Pattern: Injected at runtime - agents receive relevant skills in context when assigned work

**Plugin:**
- Purpose: Runtime extensibility - listen to events, intercept tools, manage state
- Examples: `server/src/services/plugin-*.ts`
- Pattern: Worker processes with message passing, lifecycle hooks (init, beforeToolCall, onEvent)

## Entry Points

**Server:**
- Location: `server/src/index.ts`
- Triggers: `pnpm dev` or `npm start`
- Responsibilities: Initialize embedded/external Postgres, apply migrations, start Express server with WebSocket, load plugins, initialize services

**UI:**
- Location: `ui/src/main.tsx`
- Triggers: Browser navigation to `localhost:3100`
- Responsibilities: Render React app with provider layers, establish WebSocket connection for live events, route to pages

**CLI:**
- Location: `cli/src/index.ts`
- Triggers: `npx paperclipai onboard` or `paperclipai configure`
- Responsibilities: Interactive configuration setup, create default agent, initialize company from template

**Heartbeat Cron:**
- Location: `server/src/services/heartbeat.ts`
- Triggers: Scheduled interval (default 5-30 seconds per agent)
- Responsibilities: Check agent status, enforce budgets, update issue states, trigger routine jobs

**Plugin Scheduler:**
- Location: `server/src/services/plugin-job-scheduler.ts`
- Triggers: On server startup, then periodically
- Responsibilities: Execute scheduled plugin jobs, manage job state, handle retries

## Error Handling

**Strategy:** Layered error handling with user-friendly messages, proper logging, and graceful degradation.

**Patterns:**

- **Validation Layer**: `server/src/middleware/validate.ts` - Zod schemas validate requests before reaching services
- **Service Layer**: Services throw typed errors (e.g., "Company not found", "Budget exceeded")
- **Route Layer**: Routes catch errors, format as JSON responses with status codes
- **Error Middleware**: `server/src/middleware/error-handler.ts` - Global handler catches unhandled errors, prevents crashes
- **Async Error Safety**: Express middleware wraps async handlers to catch promise rejections
- **Database Errors**: Migration errors, connection issues caught and formatted with guidance
- **Plugin Safety**: Plugin worker crashes isolated, don't crash main server; failures logged

## Cross-Cutting Concerns

**Logging:** 
- Framework: Pino for structured JSON logging
- Approach: HTTP logger middleware logs all requests, services log state changes with context
- Files: `server/src/middleware/logger.ts`, `server/src/middleware/index.ts`

**Authentication:**
- Approach: Better Auth for session management, JWT for agents
- Files: `server/src/auth/better-auth.ts`, `server/src/agent-auth-jwt.ts`
- Multi-mode: Personal mode (single user), authenticated mode (board members), agent mode (JWT)

**Authorization:**
- Approach: Company scoping (automatic), role-based checks for sensitive operations (approvals, agent hiring, company deletion)
- Files: `server/src/services/agent-permissions.ts`, `server/src/routes/authz.ts`

**Secrets Management:**
- Approach: Pluggable provider system (encrypted file, external services planned)
- Files: `server/src/secrets/` - provider registry, local encrypted provider
- Sensitive data: API keys, credentials stored encrypted per company

**Telemetry:**
- Approach: Anonymous usage tracking (can be disabled)
- Files: `server/src/telemetry.ts`, CLI telemetry in `cli/src/telemetry.ts`
- Data sent: Feature usage, error rates, deployment mode (no prompts, secrets, paths)

---

*Architecture analysis: 2026-04-03*
