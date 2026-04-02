# Codebase Structure

**Analysis Date:** 2026-04-03

## Directory Layout

```
paperclip/                              # Monorepo root
├── server/                             # Express.js API server + WebSocket
│   ├── src/
│   │   ├── index.ts                   # Server entry point
│   │   ├── app.ts                     # Express app factory
│   │   ├── config.ts                  # Config loading (env, file)
│   │   ├── middleware/                # HTTP middleware (auth, validation, errors)
│   │   ├── routes/                    # API endpoints
│   │   ├── services/                  # Business logic (~35 service modules)
│   │   ├── adapters/                  # Agent adapter registry + utilities
│   │   ├── storage/                   # File storage abstraction (S3/local)
│   │   ├── secrets/                   # Secrets provider system
│   │   ├── auth/                      # Better Auth integration
│   │   ├── realtime/                  # WebSocket live events
│   │   ├── types/                     # TypeScript extensions
│   │   ├── __tests__/                 # Unit tests (co-located pattern)
│   │   └── onboarding-assets/         # Default agent configs (AGENTS.md templates)
│   ├── scripts/                        # Dev utilities
│   └── package.json
│
├── ui/                                 # React/Vite frontend
│   ├── src/
│   │   ├── main.tsx                   # App entry point
│   │   ├── App.tsx                    # Root component with routing
│   │   ├── pages/                     # Page components (Companies.tsx, Agents.tsx, etc.)
│   │   ├── components/                # Shared UI components (buttons, cards, etc.)
│   │   ├── components/ui/             # Shadcn UI primitives
│   │   ├── hooks/                     # React hooks (useCompany, useAgent, etc.)
│   │   ├── context/                   # Context providers (Company, LiveUpdates, Dialog, etc.)
│   │   ├── adapters/                  # UI adapters for agent types (claude-local, cursor, etc.)
│   │   ├── api/                       # API client utilities
│   │   ├── lib/                       # Utilities (routing, formatting, etc.)
│   │   ├── fixtures/                  # Mock data for dev/testing
│   │   ├── plugins/                   # Plugin bridge initialization
│   │   └── index.css                  # Tailwind CSS imports
│   ├── public/                        # Static assets
│   └── vite.config.ts                 # Vite build config
│
├── cli/                                # NPM package: paperclipai CLI
│   ├── src/
│   │   ├── index.ts                   # CLI entry point (commander)
│   │   ├── commands/                  # Commands (onboard, configure, etc.)
│   │   ├── client/                    # API client
│   │   ├── config/                    # Config parsing
│   │   ├── prompts/                   # Interactive prompts
│   │   ├── checks/                    # Pre-flight checks
│   │   ├── adapters/                  # Agent adapter handling
│   │   └── utils/                     # Helpers
│   └── package.json                   # Standalone NPM package
│
├── packages/                           # Workspace packages
│   ├── db/                            # @paperclipai/db - Drizzle ORM layer
│   │   ├── src/
│   │   │   ├── index.ts               # Exports all db utilities
│   │   │   ├── schema/                # Drizzle schema definitions
│   │   │   ├── migrations/            # SQL migrations (numbered)
│   │   │   └── queries/               # Query builders
│   │   └── package.json
│   │
│   ├── shared/                        # @paperclipai/shared - Types & interfaces
│   │   ├── src/
│   │   │   ├── index.ts               # Type exports
│   │   │   ├── types/                 # Domain types (Company, Agent, Issue, etc.)
│   │   │   └── constants/             # Shared constants
│   │   └── package.json
│   │
│   ├── adapter-utils/                 # @paperclipai/adapter-utils - Shared adapter logic
│   │   ├── src/
│   │   │   ├── types.ts               # AgentAdapter interface
│   │   │   └── utils.ts               # Common helper functions
│   │   └── package.json
│   │
│   ├── adapters/                      # Agent adapter implementations
│   │   ├── claude-local/              # @paperclipai/adapter-claude-local
│   │   ├── cursor-local/              # @paperclipai/adapter-cursor-local
│   │   ├── codex-local/               # @paperclipai/adapter-codex-local
│   │   ├── gemini-local/              # @paperclipai/adapter-gemini-local
│   │   ├── openclaw-gateway/          # @paperclipai/adapter-openclaw-gateway
│   │   ├── opencode-local/            # @paperclipai/adapter-opencode-local
│   │   └── pi-local/                  # @paperclipai/adapter-pi-local
│   │   Each contains:
│   │   ├── src/
│   │   │   └── index.ts               # Implements AgentAdapter interface
│   │   └── package.json
│   │
│   └── plugins/                       # Plugin system
│       ├── sdk/                       # @paperclipai/plugin-sdk
│       │   └── src/                   # Plugin API interfaces
│       ├── create-paperclip-plugin/   # Plugin scaffolding tool
│       └── examples/                  # Example plugins
│
├── tests/                              # E2E and integration tests
│   ├── e2e/                           # Playwright E2E tests
│   └── release-smoke/                 # Release smoke tests
│
├── docker/                             # Docker images
│   ├── quadlet/                       # Podman quadlet configs
│   └── untrusted-review/              # Review sandbox container
│
├── .agents/                            # Agent skills (used by Paperclip itself)
│   └── skills/                        # Skill definitions for self-orchestration
│       ├── release/
│       ├── doc-maintenance/
│       ├── pr-report/
│       └── company-creator/
│
├── evals/                              # Evaluation suite (promptfoo)
│   └── promptfoo/
│       ├── tests/                     # Test definitions
│       └── prompts/                   # Prompt variations
│
├── doc/                                # Documentation
│   ├── DEVELOPING.md                  # Development guide
│   └── assets/                        # Images, logos
│
├── scripts/                            # Root-level scripts
│   ├── dev-runner.ts                  # Dev server orchestrator
│   ├── build-npm.sh                   # NPM package build
│   ├── release.sh                     # Release automation
│   └── ...
│
├── pnpm-workspace.yaml                # Workspace configuration
├── package.json                       # Root package (dev deps, workspace scripts)
├── tsconfig.json                      # Root TypeScript config
└── README.md
```

## Directory Purposes

**`server/src/`:**
- Purpose: Node.js backend - manages all orchestration logic, database, plugins, real-time communication
- Contains: Routes, services, middleware, adapters registry, storage, auth, secrets, WebSocket
- Key files: `index.ts` (entry), `app.ts` (Express setup), routes/services (business logic)

**`server/src/routes/`:**
- Purpose: HTTP API endpoints
- Contains: Route handlers for companies, agents, issues, projects, goals, routines, approvals, costs, plugins
- Pattern: Each route file exports a Router with related endpoints
- Key files: `companies.ts`, `agents.ts`, `issues.ts`, `approvals.ts`, `costs.ts`

**`server/src/services/`:**
- Purpose: Core business logic encapsulation
- Contains: ~35 service modules, each handling a domain concept
- Key files: `companies.ts`, `agents.ts`, `issues.ts`, `heartbeat.ts`, `costService.ts`, `budgetService.ts`, `routines.ts`
- Pattern: Each service exports singleton (e.g., `companyService`), provides CRUD + domain methods

**`server/src/middleware/`:**
- Purpose: HTTP request/response interceptors
- Contains: Logging, error handling, auth, validation, guards
- Key files: `logger.ts` (Pino), `auth.ts` (session), `error-handler.ts`, `validate.ts` (Zod)

**`server/src/adapters/`:**
- Purpose: Agent adapter registry and utilities
- Contains: Adapter selection logic, model definitions for Cursor/Codex, utility functions
- Key files: `registry.ts` (loads adapters), `index.ts` (exports all adapters)

**`server/src/services/plugin-*.ts`:**
- Purpose: Plugin system runtime
- Contains: Lifecycle management, worker pool, job scheduler, event bus, state store
- Key files: `plugin-lifecycle.ts`, `plugin-worker-manager.ts`, `plugin-job-scheduler.ts`, `plugin-event-bus.ts`

**`ui/src/pages/`:**
- Purpose: Full-page React components
- Contains: Companies, Agents, AgentDetail, Issues (Inbox), Projects, Goals, Approvals, Costs, Dashboard, CompanySettings
- Key files: `Companies.tsx` (company list), `AgentDetail.tsx` (largest - agent state machine UI)

**`ui/src/components/`:**
- Purpose: Reusable UI components
- Contains: Shadcn UI primitives, custom components (buttons, cards, modals, etc.), transcript viewer, execution workspace UI
- Pattern: Component tree structure matching UI structure

**`ui/src/context/`:**
- Purpose: React context providers for global state
- Contains: CompanyContext, LiveUpdatesProvider, DialogContext, ToastContext, ThemeContext, SidebarContext
- Pattern: Each context wraps provider + hook (e.g., `useCompany()`)

**`ui/src/adapters/`:**
- Purpose: Agent-type-specific UI adapters
- Contains: Implementations for Claude Code, Cursor, Codex, Gemini, OpenClaw, Hermes, Pi, Process, HTTP
- Pattern: Each exports component for rendering agent state + methods for interaction

**`packages/db/src/`:**
- Purpose: Data persistence layer
- Contains: Drizzle ORM schema, migrations, query builders
- Key files: `schema/` (table definitions), `migrations/` (SQL), `queries/` (select/insert builders)

**`packages/shared/src/`:**
- Purpose: Shared TypeScript interfaces
- Contains: Domain types (Company, Agent, Issue, Goal, Approval, etc.), enums, interfaces
- Used by: All packages for type safety

**`packages/adapters/*/src/`:**
- Purpose: Each adapter implements integration with an agent runtime
- Contains: One `index.ts` file implementing `AgentAdapter` interface
- Pattern: Methods: `assign()` (send task), `poll()` (check status), `retrieveOutput()` (get results)

**`cli/src/`:**
- Purpose: Command-line interface for setup and configuration
- Contains: Commands, interactive prompts, API client, config parser
- Key files: `index.ts` (Commander setup), `commands/` (onboard, configure, etc.)

**`.agents/skills/`:**
- Purpose: Reusable agent instructions for self-orchestration
- Contains: Skill definitions that Paperclip uses for its own tasks (releases, docs, reports)
- Pattern: YAML or markdown files with instructions, tools, examples

## Key File Locations

**Entry Points:**
- `server/src/index.ts`: Server startup, database initialization, service creation
- `ui/src/main.tsx`: React app root, provider setup, router initialization
- `cli/src/index.ts`: CLI command setup via Commander

**Configuration:**
- `server/src/config.ts`: Environment variable parsing and defaults
- `.claude/`: Agent configuration (skills, instructions) - used for Paperclip self-orchestration
- `packages/db/src/migrations/`: SQL schema versioning

**Core Logic:**
- `server/src/services/`: Business logic (35+ modules)
- `ui/src/pages/`: Page-level features
- `packages/db/src/schema/`: Data model definition

**Testing:**
- `server/src/__tests__/`: Unit tests (vitest)
- `tests/e2e/`: Playwright E2E tests
- `tests/release-smoke/`: Release validation tests

**Database:**
- `packages/db/src/schema/`: Drizzle table schemas
- `packages/db/src/migrations/`: Numbered SQL migrations (001, 002, etc.)

**Types:**
- `packages/shared/src/types/`: All domain types
- `packages/adapter-utils/src/types.ts`: AgentAdapter interface

## Naming Conventions

**Files:**
- Services: `[noun].ts` in `services/` (e.g., `issues.ts`, `agents.ts`)
- Routes: `[noun].ts` in `routes/` (e.g., `companies.ts`, `approvals.ts`)
- React components: `PascalCase.tsx` (e.g., `AgentDetail.tsx`, `Companies.tsx`)
- Middleware: `[adjective]-[noun].ts` (e.g., `error-handler.ts`, `auth.ts`)
- Utilities: `[action].ts` (e.g., `validate.ts`)
- Tests: `*.test.ts` or `*.spec.ts` (co-located with code)

**Directories:**
- Services: Plural nouns in `services/`
- Routes: Plural nouns in `routes/`
- Components: Plural `components/` with subdirectories for categories
- Types: `types/` or `__types/`
- Tests: `__tests__/` or `__test__/`
- Schema: `schema/` for database tables

**Functions/Variables:**
- Camel case: `issueService`, `agentRouter`, `companyId`
- Singletons with service suffix: `companyService`, `costService`
- Hooks in React: Prefix `use` (e.g., `useCompany()`, `useLiveUpdates()`)
- Context providers: Suffix `Provider` (e.g., `CompanyProvider`)

**Types:**
- Interfaces: PascalCase, prefix with `I` optional (e.g., `Company`, `Agent`, `Issue`)
- Enums: PascalCase (e.g., `IssueState`, `AgentRole`)
- Type aliases: PascalCase (e.g., `CompanyId`)

## Where to Add New Code

**New Feature (e.g., "Add expense tracking"):**
- Primary code: `server/src/services/expenses.ts` (new service)
- Routes: `server/src/routes/expenses.ts` (new route file)
- Tests: `server/src/__tests__/expenses.test.ts`
- Database: `packages/db/src/schema/expenses.ts` (new table), `packages/db/src/migrations/00X-add-expenses.sql`
- Types: `packages/shared/src/types/expenses.ts`
- UI: `ui/src/pages/Expenses.tsx` + components in `ui/src/components/`

**New Component/Module:**
- React component: `ui/src/components/[Category]/ComponentName.tsx`
- Service: `server/src/services/[module-name].ts`
- Test: Co-located `__tests__/[module-name].test.ts`

**Utilities:**
- Shared helpers (used by multiple services): `server/src/lib/[utility].ts`
- React hooks: `ui/src/hooks/use[FeatureName].ts`
- Server utilities: `server/src/utils/[utility].ts`

**New Adapter (e.g., "Add support for new agent runtime"):**
- Create: `packages/adapters/[runtime-name]/`
- Implement: `src/index.ts` with `AgentAdapter` interface
- Register: Add to server's adapter registry
- UI visualization: `ui/src/adapters/[runtime-name].tsx`

**New Plugin Capability:**
- Plugin SDK: `packages/plugins/sdk/src/` (add new interface if needed)
- Example: `packages/plugins/examples/plugin-[name]/`
- Server support: Add listener/dispatcher in `server/src/services/plugin-*.ts`

## Special Directories

**`packages/db/src/migrations/`:**
- Purpose: SQL database schema versioning
- Generated: By Drizzle ORM (`pnpm db:generate`)
- Committed: Yes - all migrations in git for reproducibility
- Pattern: Numbered files (001-init.sql, 002-add-columns.sql, etc.)
- Applied: On server startup, interactive prompt if pending

**`server/src/onboarding-assets/`:**
- Purpose: Default AGENTS.md templates for new companies
- Generated: No
- Committed: Yes - static assets for setup
- Pattern: Subdirectories by agent type (ceo, default, etc.)

**`.agents/skills/`:**
- Purpose: Reusable instructions Paperclip uses for self-orchestration
- Generated: No
- Committed: Yes - version controlled with repo
- Pattern: YAML or markdown with tools, prompts, context

**`ui/src/fixtures/`:**
- Purpose: Mock data for development and testing
- Generated: No
- Committed: Yes - dev fixtures
- Pattern: Mimic API response shape

**`tests/e2e/`:**
- Purpose: End-to-end tests with Playwright
- Generated: No
- Committed: Yes
- Pattern: User journey tests (onboard, create company, assign task, etc.)

**`server/src/__tests__/`:**
- Purpose: Unit tests for services and utilities
- Generated: No
- Committed: Yes
- Pattern: Vitest, often use fixtures and mocks

## Dependency Structure

```
ui → API routes → Services → Database
                ↓
            Adapters
              ↓
         Agent Runtimes

Server Services:
  Issue, Agent, Company → Cost, Budget, Approval → Routine, Heartbeat → Live Events
```

- **Shared** is imported by all packages (no circular deps)
- **Adapter-utils** imported by all adapters + server
- **DB** imported by server + CLI (not by UI - uses API)
- **Plugins** isolated workers - server manages lifecycle

---

*Structure analysis: 2026-04-03*
