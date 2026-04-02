# Codebase Concerns

**Analysis Date:** 2026-04-03

## Tech Debt

**Token Telemetry & Measurement Inflation:**
- Issue: Token usage metrics are unreliable, especially for sessioned adapters like `codex_local`. Session totals are being recorded as per-run deltas, inflating reported token consumption substantially.
- Files: `server/src/services/heartbeat.ts`, adapter implementations in `ui/src/adapters/`
- Impact: Cannot accurately measure optimization impact or cost forecasting; users see inflated token costs; invalidates performance decisions based on token data
- Fix approach: 
  1. Implement normalized usage fields that compute deltas from prior session totals for sessioned adapters
  2. Add explicit fields to track: `sessionReused`, `taskSessionReused`, `promptChars`, `instructionsChars`, `skillSetHash`, `contextFetchMode`
  3. Add per-adapter parser tests to distinguish cumulative-session counters from per-run counters
  4. Store both raw adapter-reported usage and Paperclip-normalized usage for transition period
  - Reference: `/Users/toby/Documents/github/projekte/fevercontext-paperclip/doc/plans/2026-03-13-TOKEN-OPTIMIZATION-PLAN.md` (Phase 1)

**Avoidable Session Resets Destroying Cache Locality:**
- Issue: Task sessions are being intentionally reset on timer wakes and manual wakes, destroying prompt cache reuse and session continuity. Timer wakes are the dominant heartbeat path (~6,587 runs observed), but only 963 end with the same session despite 976 having a prior session.
- Files: `server/src/services/heartbeat.ts` (function `shouldResetTaskSessionForWake(...)`)
- Impact: Massive token waste on resumed heartbeats; lost opportunity for prompt caching; agents restart work context from scratch on every timer wake
- Fix approach:
  1. Stop resetting task sessions on ordinary timer wakes
  2. Keep resetting only for: explicit manual "fresh run" invocations, assignment changes, workspace mismatch, model/invalid resume errors
  3. Add explicit wake flag like `forceFreshSession: true` for board-initiated resets
  4. Record why a session was reused or reset in run metadata
  - Target: 80%+ session reuse on stable timer wakes
  - Reference: Phase 2 of TOKEN-OPTIMIZATION-PLAN

**Repeated Context Reacquisition on Every Heartbeat:**
- Issue: The `paperclip` skill tells agents to re-fetch assignments, issue details, ancestors, and full comment threads on every heartbeat. No API offers efficient delta-oriented alternatives for heartbeat consumption.
- Files: `skills/paperclip/SKILL.md`, API endpoints in `server/src/api/`
- Impact: Agents replay unchanged task context on every wake; blocked-task scenarios with long comment threads become prohibitively expensive; no support for incremental/delta fetching
- Fix approach:
  1. Add heartbeat-oriented endpoints: `/api/agents/me/inbox-lite`, `/api/issues/:id/heartbeat-context`, `/api/issues/:id/comments?after=<cursor>`
  2. Rewrite `paperclip` skill to: fetch compact inbox → fetch compact task context → fetch only new comments (unless first read/mention/cache miss)
  3. Add optional `/api/issues/:id/context-digest` for server-generated compact summaries
  - Target: 80%+ reduction in full-thread comment reloads after first task read
  - Reference: Phase 4 of TOKEN-OPTIMIZATION-PLAN

**Large Static Instruction Surfaces:**
- Issue: Agent instruction files and globally injected skills (~58 KB of skill markdown before company-specific instructions) are reintroduced at startup even when unchanged. Current repo skills: `paperclip/SKILL.md` (17.4 KB), `create-agent-adapter/SKILL.md` (31.8 KB), others (~8.7 KB). Not all loaded on every run, but increases startup surface area.
- Files: `skills/` directory, adapter initialization code in `ui/src/adapters/`
- Impact: Unnecessary token consumption on startup; inflated context window usage; no distinction between bootstrap context and dynamic per-heartbeat context
- Fix approach:
  1. Implement `bootstrapPromptTemplate` end-to-end in adapter execution paths
  2. Use bootstrap only when starting fresh session, not on resumed sessions
  3. Keep `promptTemplate` intentionally small: agent identity, wake trigger, task priority
  4. Move long-lived setup text out of recurring per-run prompts
  5. Replace global skill injection with explicit allowlist per agent/adapter
  6. Default skill set should be just `paperclip`; opt-in for specialized skills
  - Reference: Phases 3 and 6 of TOKEN-OPTIMIZATION-PLAN

**Codex Skill Resolution Brittleness:**
- Issue: When an existing Paperclip skill symlink points at another live checkout, the current implementation skips it instead of repointing. This leaves Codex using stale skill content from a different worktree even after Paperclip-side skill changes land.
- Files: `ui/src/adapters/codex-local/`, skill symlink management code
- Impact: Correctness risk — runtime behavior may not reflect instructions in the active checkout being tested; invalidates token analysis and performance testing
- Fix approach:
  1. Either: run Codex with a worktree-specific `CODEX_HOME` per checkout
  2. Or: treat Paperclip-owned Codex skill symlinks as repairable when they point at a different checkout
  - Reference: Phase 6, note on `codex_local` of TOKEN-OPTIMIZATION-PLAN

---

## Scaling Limits

**Session Context Unbounded Growth:**
- Issue: Long-lived sessions in sessioned adapters (Claude, Codex) accumulate context without automatic rotation. Even with cache optimization, very long sessions can become progressively more expensive to maintain.
- Current capacity: No explicit session rotation policy; sessions can run indefinitely as long as model supports resume
- Limit: Model context window exhaustion; cache hit degradation over time; rising per-heartbeat cost on ancient sessions
- Scaling path:
  1. Implement session rotation thresholds: turns, normalized input tokens, age, cache hit degradation
  2. Before rotating, produce structured carry-forward summary: objective, work completed, decisions, blockers, files touched, next action
  3. Persist summary in task session state; start next session with bootstrap + compact summary + wake trigger
  4. Reference: Phase 5 of TOKEN-OPTIMIZATION-PLAN
  5. Success criteria: very long sessions stop growing without bound, no loss of task continuity on rotation

**Heartbeat Run History Explosion:**
- Issue: With 11,360 runs observed over ~24 days across a single instance, heartbeat_runs table grows rapidly. No evident pagination or archival strategy.
- Current capacity: Single embedded Postgres can handle millions of runs
- Limit: Query performance degradation as history table grows; storage consumption; reporting complexity
- Scaling path:
  1. Implement heartbeat run archival/tiering strategy (cold storage after N days)
  2. Add summary aggregation tables for historical reporting
  3. Implement pagination and filtering in run queries
  4. Monitor query performance on heartbeat_runs lookups

---

## Fragile Areas

**AgentDetail.tsx Component:**
- Files: `ui/src/pages/AgentDetail.tsx` (4,078 lines)
- Why fragile: Monolithic component with multiple responsibilities: agent state management, tab navigation, config editing, permission updates, run history display, budget tracking, instructions management. High cyclomatic complexity with many conditional branches and state interactions.
- Safe modification:
  1. Identify a single responsibility (e.g., "permissions management")
  2. Extract into separate component/hook with its own query/mutation
  3. Update AgentDetail to compose smaller components
  4. Add integration tests for state transitions
- Test coverage: Has some tests, but focus should be on state transition paths rather than rendering
- Priority: High — this is a frequently modified component with high risk of regressions

**Large Form Components:**
- Files: `ui/src/components/AgentConfigForm.tsx` (1,648 lines), `ui/src/components/NewIssueDialog.tsx` (1,476 lines), `ui/src/components/OnboardingWizard.tsx` (1,403 lines)
- Why fragile: Complex nested form state with validation, conditional field rendering, and side effects. Easy to break form state consistency or validation when modifying any field.
- Safe modification:
  1. Map field dependencies explicitly in a configuration object, not in component logic
  2. Separate form state shape from UI rendering concerns
  3. Use form library (react-hook-form, Formik) validation constraints, not custom logic
  4. Test field interdependencies explicitly
- Test coverage: Exists but should focus on field validation workflows and state consistency

**Transcript/Run Display System:**
- Files: `ui/src/components/transcript/RunTranscriptView.tsx` (1,255 lines), `ui/src/adapters/transcript.test.ts`
- Why fragile: Handles multiple adapter-specific transcript formats (Claude, Codex, Gemini, OpenClaw, Cursor, Pi, OpenCode, Hermes). Normalization logic is spread across adapters and transcript view. Changes to one adapter's format can silently break transcript display.
- Safe modification:
  1. Before changes: run full transcript test suite with real adapter outputs
  2. Define strict transcript format contract (JSON schema)
  3. Each adapter must validate output against schema before storing
  4. Add integration tests with recorded adapter outputs
- Test coverage: Has test file but should validate against real adapter formats

---

## Test Coverage Gaps

**Adapter Integration Testing:**
- What's not tested: Real end-to-end adapter execution (Claude local, Codex, Cursor, Gemini, OpenCode, Hermes, Pi) with actual invokeAgent calls, output parsing, and session resumption
- Files: `ui/src/adapters/`, `server/src/services/heartbeat.ts`
- Risk: Adapter changes (config parsing, runtime integration, skill injection) can break silently until hitting production. Session resumption logic is especially fragile across adapter types.
- Coverage needed:
  1. Smoke tests for each adapter: invoke → session state persisted → resume → same session reused
  2. Transcript output parsing validation for each adapter type
  3. Error handling: stale session, model unavailable, auth failure
  4. Skill injection validation per adapter (skills actually reach runtime)

**Permission/Governance Enforcement:**
- What's not tested: Full permission boundaries when agents act (can they modify issues assigned to others? Can they exceed budgets? Can they override role restrictions?)
- Files: `server/src/middleware/auth.ts`, `server/src/services/` (mutations), agent-facing API endpoints
- Risk: Permission checks might be incomplete or bypassable through API endpoints that don't enforce all guards consistently
- Coverage needed:
  1. Matrix tests: each agent role × each mutation type (update issue, create subtask, join, leave)
  2. Budget enforcement: verify mutation fails when agent would exceed spend limit
  3. Permission inheritance: inherited permissions from parent agents/projects actually prevent actions
  4. Audit trail: all permission-guarded actions logged for compliance

**Session Reset & Resume Edge Cases:**
- What's not tested: Session resume after long periods, model changes, workspace changes, explicit fresh-run invocations, cache hit/miss scenarios
- Files: `server/src/services/heartbeat.ts`, adapter session managers
- Risk: Stale sessions causing silent failures; missing context after resume; cache invalidation not handled properly
- Coverage needed:
  1. Session lifecycle matrix: [fresh → resumed → rotated → fresh again] with state verification
  2. Model switch: same session ID but different model → should reset
  3. Workspace change detection: workspace file changes → session invalidation
  4. Forced fresh runs: explicit board action → session reset even if reusable

**Heartbeat Timer Behavior:**
- What's not tested: Actual heartbeat scheduling, concurrent heartbeats, wake coalescing, task session state across multiple sequential wakes
- Files: `server/src/services/heartbeat.ts`, cron/timer implementation
- Risk: Race conditions when multiple agents wake simultaneously; lost updates if heartbeats overlap; timer drift
- Coverage needed:
  1. Concurrent heartbeat simulation: 10+ agents waking at same timestamp → no double-work
  2. Task state consistency: task checkout atomic, budget deducted exactly once
  3. Wake coalescing: multiple wakes within window → single run
  4. Long-running heartbeat: heartbeat takes >1min, next wake timer fires → handled correctly

**Company Portability (Import/Export):**
- What's not tested: Full round-trip company export→import with complex structures (nested projects, linked agents, shared skills, budget policies, routine definitions), conflict resolution, orphaned references
- Files: `ui/src/pages/CompanyExport.tsx`, `ui/src/pages/CompanyImport.tsx`, related API endpoints
- Risk: Data corruption, missing relationships, or silent failures during import that only manifest when agents run
- Coverage needed:
  1. Round-trip: export company → import into clean DB → verify structure identical
  2. Merge conflicts: import with ID collisions → conflict resolution works
  3. Reference integrity: imported agents with dangling project/skill references → caught and handled
  4. State resets: imported agents start with heartbeats disabled (confirmed in v2026.325.0) → verify toggle actually disables

---

## Performance Bottlenecks

**Full Comment Thread Reloads on Every Heartbeat:**
- Problem: Agents re-fetch entire issue comment history on every wake even if blocked on same issue
- Files: `skills/paperclip/SKILL.md`, `server/src/api/issues.ts` (GET /api/issues/:id/comments)
- Cause: No API support for delta fetching; skill pattern fetches full thread by default
- Improvement path:
  1. Implement `/api/issues/:id/comments?after=<cursor>` endpoint first
  2. Update skill to fetch deltas unless first read or mention-triggered
  3. Measure: track % of heartbeats fetching full thread vs deltas
  4. Target: 80%+ reduction in full-thread reloads after first read

**Complex Query Performance on Large History Tables:**
- Problem: Reports, cost pages, activity timelines query heartbeat_runs/activity_logs without pagination or indexes
- Files: `server/src/api/activity.ts`, `ui/src/pages/Costs.tsx` (query structure)
- Cause: No query pagination; loading entire history into memory
- Improvement path:
  1. Add cursor-based pagination to all historical queries
  2. Add database indexes on: (company_id, created_at), (agent_id, created_at), (status, created_at)
  3. Implement query result caching (Redis or in-memory) for 1-hour stable aggregations
  4. Add query performance monitoring

**Transcript Rendering Performance:**
- Problem: RunTranscriptView renders very long transcripts without virtualization (1,255 line component)
- Files: `ui/src/components/transcript/RunTranscriptView.tsx`
- Cause: Rendering all transcript entries at once; no lazy loading or windowing
- Improvement path:
  1. Implement virtual scrolling for transcript entries (react-window or similar)
  2. Load transcript in chunks: first 100 entries, load more on scroll
  3. Measure: monitor render time for runs with 500+, 1000+ entries
  4. Target: <100ms render time even for 5000+ entry transcripts

---

## Dependencies at Risk

**Lexical Editor Dependency:**
- Risk: Using exact version (`0.35.0`) without flexibility. Lexical is under active development; security/compatibility issues may emerge.
- Impact: Cannot patch security issues without upgrading entire major version
- Migration plan:
  1. Add automated dependency update checks (Dependabot)
  2. Test Lexical upgrades quarterly even if not required
  3. Have fallback to plain textarea/markdown if editor becomes problematic
  - Reference: `ui/package.json` line 32-33

**React 19 & React Router 7 Beta Status:**
- Risk: React Router 7.1.5 is very recent; potential for breaking changes, edge cases not yet discovered
- Impact: Framework-level bugs may surface in production; upgrade path to future versions unknown
- Migration plan:
  1. Monitor React Router GitHub issues and discussions for regressions
  2. Pin version in production deployments explicitly
  3. Establish CI test coverage for routing edge cases

**Mermaid Dependency:**
- Risk: Mermaid (11.12.0) is heavy dependency used only for org chart visualization. Future versions may have breaking API changes.
- Impact: If Mermaid breaks, entire org chart feature becomes unusable
- Migration plan:
  1. Abstract Mermaid behind component interface so alternative implementations can be swapped
  2. Consider simpler alternative (custom SVG, React Flow) if Mermaid causes issues
  3. Add feature flag to disable Mermaid rendering if library fails

---

## Security Considerations

**Adapter Configuration Handling:**
- Risk: Adapter configs contain sensitive data (API keys, auth tokens, file paths). Improper handling could leak credentials in logs, error messages, or exports.
- Files: `ui/src/adapters/*/config-fields.tsx`, `server/src/secrets/`, company export logic
- Current mitigation: Has `redactHomePathUserSegments*` utilities in `ui/src/adapters/` and `@paperclipai/adapter-utils`
- Recommendations:
  1. Audit all adapter config serialization paths (display, export, logging)
  2. Ensure company export has explicit secret scrubbing (documented in v2026.325.0 notes)
  3. Add automated checks: grep for bare config values in error logs
  4. Test secret redaction in company import/export round-trip

**Agent Privilege Escalation:**
- Risk: Agents can invoke skills and create issues. Insufficient permission checks could allow agent to escalate privileges (create new agent with higher budget, modify project goals, etc.)
- Files: `server/src/middleware/auth.ts`, skill invocation gates, API endpoints with agent auth
- Current mitigation: Per-role permissions and budget policies exist (mentioned in v2026.325.0)
- Recommendations:
  1. Formal threat model for agent actions: what should each role NOT be able to do?
  2. Add explicit permission tests for each escalation risk (budget override, role change, skill injection)
  3. Implement immutable audit trail for permission-sensitive operations
  4. Add rate limiting on permission-gated endpoints

**Company Data Isolation:**
- Risk: Multi-company isolation is core safety guarantee. Bugs in company_id filtering could leak data between companies.
- Files: All `server/src/api/*` endpoints, database queries
- Current mitigation: Entity-level company scoping mentioned in v2026.325.0 features
- Recommendations:
  1. Add automated tests: every query filters by `company_id` in WHERE clause (SQL-level validation)
  2. Implement strict typing for company-scoped entities to prevent accidental unscoped queries
  3. Add integration tests for cross-company isolation: create identical entity in 2 companies, verify isolation

**Heartbeat Webhook Attacks:**
- Risk: External adapters (HTTP, process) receive heartbeat webhooks. No obvious validation of heartbeat payload source.
- Files: `server/src/adapters/http.ts`, `server/src/adapters/process.ts`
- Recommendations:
  1. Add HMAC signature validation for HTTP heartbeat callbacks
  2. Rate limit heartbeat endpoints by source IP/agent
  3. Log all heartbeat invocations with source, payload hash, result
  4. Add circuit breaker: disable agent if repeated webhook failures

---

## Known Technical Decisions Requiring Future Review

**Bootstrap Prompt Template (Deprecated):**
- Status: `bootstrapPromptTemplate` is documented as deprecated in `docs/agents-runtime.md`; existing configs using it will continue to work but should be migrated
- Impact: UI still exposes this field; adapter execution paths do not currently implement it (per TOKEN-OPTIMIZATION-PLAN Phase 3)
- Action: Prioritize Phase 3 implementation to fully deprecate bootstrap concept and implement proper static/dynamic separation

**Skill symlink handling (codex_local):**
- Status: Known brittleness documented in TOKEN-OPTIMIZATION-PLAN Phase 6
- Impact: Codex agent skill content can become stale across worktree switches
- Action: Queue as tech debt; affects only local Codex development, not production

---

## Missing Critical Features

**Incremental Context APIs:**
- Problem: No API support for delta-oriented issue context fetching (comments only new since last read, issue changes since last read)
- Blocks: Cannot implement Phase 4 token optimization
- Impact: Forces agents to re-read unchanged context on every wake, burning tokens

**Session Rotation with Carry-Forward:**
- Problem: No mechanism to automatically rotate long-lived sessions with work context preservation
- Blocks: Cannot prevent unbounded session cost growth (Phase 5)
- Impact: Very long-lived agent sessions become prohibitively expensive

**Skill Allowlisting:**
- Problem: All repo skills injected globally by default; no per-agent or per-adapter allowlist
- Blocks: Cannot reduce startup instruction surface (Phase 6)
- Impact: All agents pay token cost for skills they don't use

---

## Monitoring & Observability Gaps

**Token Telemetry Validation:**
- Gap: No automated checks that reported token usage is reasonable (detects cumulative-session recording)
- Recommendation: Add validation queries that flag runs with unreasonable token/char ratios by adapter type
- Implement: Dashboard alert if any single run reports >1M tokens without proportional character input

**Heartbeat Timing Analytics:**
- Gap: No visibility into wake timing accuracy, latency, or skew across agents
- Recommendation: Track (scheduled_time - actual_wake_time) distribution; alert on >5min variance
- Implement: Dashboard showing heartbeat SLA compliance

**Adapter Health Checks:**
- Gap: No proactive monitoring of adapter availability or credential expiration
- Recommendation: Periodic adapter health check: attempt to ping/handshake with adapter
- Implement: Dashboard showing last successful adapter check per agent

