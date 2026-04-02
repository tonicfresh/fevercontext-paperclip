# Coding Conventions

**Analysis Date:** 2026-04-03

## Naming Patterns

**Files:**
- Components: PascalCase (e.g., `Button.tsx`, `ToastProvider.tsx`)
- Utilities/helpers: camelCase (e.g., `assignees.ts`, `inbox.ts`)
- Tests: suffix with `.test.ts` or `.spec.ts` (e.g., `inbox.test.ts`)
- Context providers: PascalCase ending in `Context.tsx` or `Provider.tsx` (e.g., `ToastContext.tsx`, `CompanyContext.tsx`)
- Middleware: kebab-case with `-handler` or `-guard` suffix (e.g., `error-handler.ts`, `auth.ts`)

**Functions:**
- Named exports use camelCase
- Public utility functions: camelCase (e.g., `assigneeValueFromSelection()`, `getRememberedPathOwnerCompanyId()`)
- Private/internal helpers: camelCase prefixed with underscore if truly private (rare in this codebase)
- Hook functions: `use` prefix for React hooks (e.g., `useCompanyPageMemory()` hook files)
- Error handler functions: action verbs (e.g., `badRequest()`, `unauthorized()`, `notFound()`)

**Variables:**
- Constants (top-level): UPPER_SNAKE_CASE (e.g., `DEFAULT_TTL_BY_TONE`, `MIN_TTL_MS`, `MAX_TOASTS`)
- Regular variables: camelCase (e.g., `toasts`, `timersRef`, `dedupeRef`)
- Boolean variables: `is`/`has` prefix (e.g., `isAuthenticatedMode`, `hasActiveInvite`)
- Maps/Collections: plural noun (e.g., `toasts`, `comments`, `issues`)

**Types/Interfaces:**
- PascalCase (e.g., `ToastTone`, `ToastInput`, `ToastItem`, `AssigneeSelection`)
- Input types: suffix with `Input` (e.g., `ToastInput`, `CommentAssigneeSuggestionInput`)
- Context value types: suffix with `ContextValue` or `Value` (e.g., `ToastContextValue`)
- Exported types have explicit `export interface` or `export type`

## Code Style

**Formatting:**
- No explicit linter config detected (`no .eslintrc*` or `.prettierrc*` in root)
- Codebase appears to follow consistent formatting manually or via editor settings
- Import statements formatted with consistent spacing
- Indentation: 2 spaces (observed in all source files)

**Linting:**
- TypeScript strict mode enabled (`"strict": true` in `tsconfig.json`)
- All compiled with TypeScript 5.7.3+
- Module resolution: `bundler` (for modern tooling)
- No explicit ESLint config, but code follows conventional patterns

**TypeScript Configuration:**
- Target: `ES2023`
- Module: `ESNext`
- `strict: true` - enforces strict type checking
- `skipLibCheck: true` - skips checking declaration files
- `forceConsistentCasingInFileNames: true` - prevents case sensitivity issues

## Import Organization

**Order:**
1. Node.js built-in modules (`import { X } from "node:fs"`)
2. Third-party packages (`import { useQuery } from "@tanstack/react-query"`)
3. Workspace packages (`import { X } from "@paperclipai/shared"`)
4. Local imports (`import { X } from "@/lib/..."` or relative paths)

**Path Aliases:**
- `@/*` → `./src/*` (used in frontend/UI)
- `@/lib/*` → utility and helper functions
- `@/components/*` → React components
- `@/context/*` → React Context providers
- `@/hooks/*` → Custom React hooks
- `@/pages/*` → Page components
- `@/api/*` → API client code
- Workspace imports: `@paperclipai/shared`, `@paperclipai/db`, `@paperclipai/adapter-*` etc.

## Error Handling

**Patterns:**
- Custom `HttpError` class extends Error: `new HttpError(status, message, details?)`
- Error factory functions for HTTP status codes: `badRequest()`, `unauthorized()`, `forbidden()`, `notFound()`, `conflict()`, `unprocessable()`
- Each error factory takes message and optional details object
- Details object logged but not always sent to client

**Error Middleware:**
- Express error handler catches and formats errors
- `ZodError` from validation becomes 400 with validation details
- `HttpError` with status >= 500 tracked to telemetry
- All errors attached to response object for structured logging
- Request context (body, params, query) captured for debugging

**Client-side:**
- Tests use `expect().toEqual()` and `expect().toContain()` for assertions
- No formal error catching pattern detected in UI code

## Logging

**Framework:** Pino (piped through pino-pretty for terminal, pino-pretty again for file)

**Patterns:**
- `logger` instance exported from `server/src/middleware/logger.ts`
- HTTP requests logged via `pinoHttp` middleware
- Custom log levels based on HTTP status code (500+ = error, 400+ = warn, otherwise = info)
- File output: `server.log` (path configured via `PAPERCLIP_LOG_DIR` env or config file)
- Console output: pretty-printed with timestamps, colors, and contextual info
- Request body, params, query logged for 4xx/5xx responses for debugging

**Error logging:**
- Error context attached to response for structured output
- Error name, message, and stack captured
- Log redaction applied to usernames and home directories

## Comments

**When to Comment:**
- Complex algorithm logic (e.g., CRC32 calculation in zip test)
- Non-obvious intent (e.g., "Backward compatibility for older drafts")
- Configuration/setup decisions
- Sparse: most code is self-documenting through function names

**JSDoc/TSDoc:**
- Used for exported interfaces and type definitions
- No heavy JSDoc observed; TypeScript types provide documentation
- Some functions have inline comments explaining behavior

## Function Design

**Size:** 
- Utility functions: typically 5-25 lines
- React components: 50-150 lines before breaking into sub-components
- Middleware/handlers: 20-80 lines

**Parameters:**
- Single parameter object pattern used for functions with multiple parameters
- Example: `resolveIssueWorkspaceName(issue, { executionWorkspaceById, projectWorkspaceById, ... })`
- Optional parameters marked with `?` in type definitions

**Return Values:**
- Prefer explicit types over inference
- Return null/undefined explicitly for optional returns
- Map/Set collections returned for O(1) lookups
- Unions used for discriminated types (e.g., `kind: "issue" | "approval" | "join_request"`)

## Module Design

**Exports:**
- Named exports preferred (easier tree-shaking)
- Barrel files used in some directories (e.g., `middleware/index.ts`)
- Type and implementation exports together
- `export interface` and `export function` used

**Barrel Files:**
- `server/src/middleware/index.ts` - exports all middleware
- Common pattern for grouping related exports

## Class Design

**Patterns:**
- Minimal class usage; functional style preferred
- `HttpError` extends Error for custom HTTP exceptions
- Context providers use functional components with hooks, not classes
- React components mostly functional

## Constants and Configuration

**Location:**
- Top-level constants defined in module scope (e.g., `DEFAULT_TTL_BY_TONE`, `MIN_TTL_MS`)
- Environment variables read once at startup (e.g., `PAPERCLIP_LOG_DIR`)
- Feature flags in configuration objects
- Magic numbers extracted to named constants

## Testing Conventions

- See TESTING.md for detailed test patterns and structure

---

*Convention analysis: 2026-04-03*
