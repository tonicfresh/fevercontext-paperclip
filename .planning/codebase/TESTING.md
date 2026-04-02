# Testing Patterns

**Analysis Date:** 2026-04-03

## Test Framework

**Runner:**
- Vitest 3.0.5 (modern, fast, Vite-native test runner)
- Config: `vitest.config.ts` at project root and in each package (`ui/`, `server/`, etc.)
- Root config references projects: `packages/db`, `packages/adapters/codex-local`, `packages/adapters/opencode-local`, `server`, `ui`, `cli`

**Assertion Library:**
- Vitest built-in `expect()` (no additional library needed)

**Run Commands:**
```bash
pnpm test                # Run all tests in watch mode
pnpm test:run            # Run all tests once (CI mode)
pnpm test:e2e            # Run Playwright E2E tests
pnpm test:e2e:headed     # Run E2E tests with browser visible
pnpm test:release-smoke  # Run release smoke tests
```

## Test File Organization

**Location:**
- Co-located with source: `src/lib/inbox.test.ts` lives next to `src/lib/inbox.ts`
- Server: `src/__tests__/` directory (centralized)
- Server example: `src/__tests__/log-redaction.test.ts`

**Naming:**
- `.test.ts` suffix for unit tests
- `.spec.ts` suffix for E2E tests (Playwright)
- Match source file name (e.g., `inbox.ts` → `inbox.test.ts`)

**Structure:**
```
ui/src/
├── lib/
│   ├── inbox.ts
│   └── inbox.test.ts          # Test co-located
├── context/
│   ├── ToastContext.tsx
│   └── ToastContext.test.ts    # (if tested)
└── hooks/
    └── useCompanyPageMemory.test.ts

server/src/
└── __tests__/
    ├── log-redaction.test.ts
    ├── ui-branding.test.ts
    └── monthly-spend-service.test.ts
```

## Test Structure

**Suite Organization:**
```typescript
// From ui/src/lib/inbox.test.ts
import { beforeEach, describe, expect, it } from "vitest";
import { someFunction } from "./inbox";

describe("inbox helpers", () => {
  beforeEach(() => {
    // Setup before each test
    storage.clear();
  });

  it("does something specific", () => {
    const result = someFunction(...);
    expect(result).toEqual(...);
  });

  it("handles edge case", () => {
    // ...
  });
});
```

**Patterns:**
- `describe()` groups related tests
- `it()` defines individual test cases
- `beforeEach()` runs setup before each test
- Clear, descriptive test names that read as assertions
- One assertion per test (or grouped related assertions)

## Mock Setup and Test Data

**localStorage Mock (for UI tests):**
```typescript
// From ui/src/lib/inbox.test.ts
const storage = new Map<string, string>();

Object.defineProperty(globalThis, "localStorage", {
  value: {
    getItem: (key: string) => storage.get(key) ?? null,
    setItem: (key: string, value: string) => {
      storage.set(key, value);
    },
    removeItem: (key: string) => {
      storage.delete(key);
    },
    clear: () => {
      storage.clear();
    },
  },
  configurable: true,
});
```

**Test Data Factories:**
```typescript
// From ui/src/lib/inbox.test.ts
function makeApproval(status: Approval["status"]): Approval {
  return {
    id: `approval-${status}`,
    companyId: "company-1",
    type: "hire_agent",
    // ... required fields with sensible defaults
    status,
  };
}

function makeApprovalWithTimestamps(
  id: string,
  status: Approval["status"],
  updatedAt: string,
): Approval {
  return {
    ...makeApproval(status),
    id,
    createdAt: new Date(updatedAt),
    updatedAt: new Date(updatedAt),
  };
}
```

**Pattern:**
- Factory functions named `make*()` or `create*()`
- Accept overrides as optional parameters
- Provide sensible defaults for all required fields
- Return full, valid objects ready for testing

## Mocking

**Framework:** No external mocking library (Vitest's built-in mocking)

**What to Mock:**
- Browser APIs (localStorage, window methods)
- External service calls
- Date/time (use Date constructor with specific values)
- Math.random() if needed for deterministic tests

**What NOT to Mock:**
- Pure utility functions (test them directly)
- Internal data transformations
- Standard library functions (unless testing error paths)
- Array/Object methods

**File I/O Tests:**
- Tests in `server/src/__tests__/` use actual Uint8Array operations
- Binary file handling tested with real buffer construction (see `zip.test.ts`)

## Fixtures and Factories

**Test Data:**
- Factories use default objects with overrideable properties
- All entities have required IDs and timestamps
- Dates normalized to `new Date("2026-03-11T00:00:00.000Z")` for consistency

**Location:**
- Defined inline in test files (not in separate fixtures directory)
- Shared factories (if needed) would go in `__tests__/fixtures/` or similar

**Example - Complex Factory with Overrides:**
```typescript
// From ui/src/lib/inbox.test.ts
function makeProjectWorkspace(overrides: Partial<ProjectWorkspace> = {}): ProjectWorkspace {
  return {
    id: "project-workspace-1",
    companyId: "company-1",
    projectId: "project-1",
    name: "Primary workspace",
    // ... many required fields
    ...overrides,  // Allow overriding any field
  };
}

// Usage:
const workspace = makeProjectWorkspace({ name: "Secondary workspace" });
```

## Coverage

**Requirements:** Not enforced (no coverage config in `vitest.config.ts`)

**View Coverage:**
- No standard command configured
- Could use: `vitest run --coverage` if coverage plugin installed

## Test Types

**Unit Tests:**
- Scope: Individual functions and small modules
- Approach: Test inputs and outputs, verify data transformations
- Location: `src/lib/*.test.ts` for utilities, `src/__tests__/*.test.ts` for server code
- Examples: `inbox.test.ts`, `assignees.test.ts`, `zip.test.ts`

**Integration Tests:**
- Scope: Multiple modules working together
- Approach: Test complete workflows, data flow through multiple layers
- Example: `log-redaction.test.ts` tests redaction across nested objects and arrays

**E2E Tests:**
- Framework: Playwright (`tests/e2e/playwright.config.ts`)
- Scope: Full user workflows in browser
- Commands: `pnpm test:e2e`, `pnpm test:e2e:headed`
- Examples: `onboarding.spec.ts`, `docker-auth-onboarding.spec.ts`

## Common Patterns

**Async Testing:**
```typescript
// From ui/src/lib/zip.test.ts
it("reads a Paperclip zip archive back into rootPath and file contents", async () => {
  const archive = createZipArchive({ ... });

  await expect(readZipArchive(archive)).resolves.toEqual({
    rootPath: "paperclip-demo",
    files: { ... },
  });
});
```

**Pattern:**
- Mark test function `async`
- Use `await expect(...).resolves` or `await expect(...).rejects` for promises
- Chain `.toEqual()` or other matchers after `.resolves`

**Error Testing:**
```typescript
// Test that a function returns null/undefined for invalid input
it("falls back to the actual assignee when there is no better commenter hint", () => {
  expect(
    suggestedCommentAssigneeValue(
      { assigneeUserId: "board-user" },
      [{ authorUserId: "board-user" }],
      "board-user",
    ),
  ).toBe("user:board-user");
});

// Error validation with ZodError
if (err instanceof ZodError) {
  res.status(400).json({ error: "Validation error", details: err.errors });
}
```

**Pattern:**
- Test happy path and edge cases
- Verify null/undefined returns explicitly
- No try/catch in tests (expect errors to propagate or use `.rejects`)

**Vitest Environment Directive:**
```typescript
// From ui/src/lib/inbox.test.ts - explicitly set node environment
// @vitest-environment node

import { describe, expect, it } from "vitest";
// ... test code
```

**Pattern:**
- Use `// @vitest-environment node` at top of file when testing non-browser code
- Default is DOM environment for UI tests
- Node environment for utility function tests

## Test Organization Best Practices

**One concept per describe block:**
```typescript
describe("inbox helpers", () => {
  // All inbox-related tests here
  it("counts the same inbox sources the badge uses", () => {...});
  it("drops dismissed runs and alerts from the computed badge", () => {...});
});
```

**Descriptive test names:**
- Read like English sentences
- Explain what is being tested and expected
- Example: `"limits recent touched issues before unread badge counting"`

**Setup is minimal:**
- Use `beforeEach()` for common setup
- Keep test data close to test (inline factories preferred)
- Avoid complex global state

**Use of Maps for O(1) lookups in tests:**
```typescript
// From ui/src/lib/inbox.test.ts
resolveIssueWorkspaceName(issue, {
  executionWorkspaceById: new Map([[executionWorkspace.id, executionWorkspace]]),
  projectWorkspaceById: new Map([
    [defaultWorkspace.id, defaultWorkspace],
    [secondaryWorkspace.id, secondaryWorkspace],
  ]),
  defaultProjectWorkspaceIdByProjectId: new Map([[issue.projectId!, defaultWorkspace.id]]),
})
```

---

*Testing analysis: 2026-04-03*
