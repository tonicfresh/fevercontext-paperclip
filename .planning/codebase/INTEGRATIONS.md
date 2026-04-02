# External Integrations

**Analysis Date:** 2026-04-03

## APIs & External Services

**HTTP Adapter (Agent Communication):**
- Generic HTTP webhook support for agent execution
  - Implementation: `server/src/adapters/http/execute.ts`
  - Sends agent context, runId, and agentId to configurable HTTP endpoint
  - POST/custom method support with custom headers and payload templates
  - Timeout support (configurable per-execution)

**Feedback/Telemetry Export:**
- Optional backend for trace bundle export
  - SDK: Native fetch API
  - Auth: Bearer token (optional, via `PAPERCLIP_FEEDBACK_EXPORT_BACKEND_TOKEN`)
  - Endpoint: Configurable via `PAPERCLIP_FEEDBACK_EXPORT_BACKEND_URL`
  - Purpose: Sends execution feedback traces for analysis/auditing
  - Implementation: `server/src/services/feedback-share-client.ts`

**Telemetry Service:**
- Paperclip official telemetry collection
  - Endpoint: `https://telemetry.paperclip.ing/ingest` (default)
  - Auth: Implicit (installId-based, no token required)
  - Implementation: `packages/shared/src/telemetry/client.ts`
  - Behavior: Fire-and-forget, batched, disabled by default
  - Data: Event names, dimensions (dimensions redacted for privacy)
  - Disabling: `PAPERCLIP_TELEMETRY_DISABLED=1` or `DO_NOT_TRACK=1`

## Data Storage

**Databases:**
- PostgreSQL 12+ (production) or embedded PostgreSQL 18.1.0-beta.16 (development)
  - ORM: Drizzle ORM with full schema migrations
  - Connection: `DATABASE_URL` environment variable (e.g., `postgres://user:pass@host:5432/db`)
  - Default embedded Postgres data directory: `~/.paperclip/postgres-data`
  - Embedded Postgres port: 54329 (configurable)
  - Backup: Automatic hourly backups enabled by default
    - Location: `~/.paperclip/database-backups`
    - Retention: 30 days
    - Configurable via `PAPERCLIP_DB_BACKUP_*` environment variables

**File Storage:**
- Local disk (default) or AWS S3
  - Local: `~/.paperclip/storage` (configurable via `PAPERCLIP_STORAGE_LOCAL_DIR`)
  - S3: Full AWS SDK support for bucket configuration
    - Provider: `@aws-sdk/client-s3`
    - Config: Bucket, region, endpoint, prefix, path style
    - Operations: GetObject, PutObject, DeleteObject, HeadObject
    - Enable S3: Set `PAPERCLIP_STORAGE_PROVIDER=s3`
    - S3 env vars: `PAPERCLIP_STORAGE_S3_BUCKET`, `PAPERCLIP_STORAGE_S3_REGION`, `PAPERCLIP_STORAGE_S3_ENDPOINT`

**Caching:**
- In-memory (server process) - No external cache service
  - React Query client-side caching for UI data fetching

## Authentication & Identity

**Auth Provider:**
- Self-hosted via better-auth library (no external auth service dependency)
  - Implementation: `server/src/auth/better-auth.ts`
  - Session mechanism: HTTP-only cookies + database-backed sessions
  - User management: Email/password signup (configurable, can be disabled)
  - Database tables: `authUsers`, `authSessions`, `authAccounts`, `authVerifications`
  - Signup disable: Set `PAPERCLIP_AUTH_DISABLE_SIGN_UP=true`
  - JWT tokens: Agent-specific JWT auth via `agent-auth-jwt.ts`
  - Trust origins: Configurable trusted origins for CORS/auth validation

**Board Authentication:**
- Session-based (cookies)
- Deployment mode determines auth strictness:
  - `local_trusted`: No authentication required (default for local dev)
  - `authenticated`: Requires login for all users
  - `private`: Only authenticated users on private network

**Agent Authentication:**
- JWT tokens: `PAPERCLIP_AGENT_JWT_SECRET` (env-based)
- API key tokens: Agent-specific keys stored in database
  - Implementation: `server/src/agent-auth-jwt.ts`

**WebSocket Auth:**
- Upgrade context validation: Company ID + actor type (board/agent) + actor ID
- Token hashing: SHA256 token hashing for API key validation
- Implementation: `server/src/realtime/live-events-ws.ts`

## Monitoring & Observability

**Error Tracking:**
- Not detected - Errors logged via Pino but no external error tracking service

**Logs:**
- Pino structured JSON logging (server)
  - Implementation: `server/src/middleware/logger.ts`
  - Output: Console (pretty-printed in dev, JSON in production)
  - Levels: info, warn, error, debug
  - HTTP request logging: Request/response metadata

**Health Endpoint:**
- Not detected - No standard health check endpoint documented

## CI/CD & Deployment

**Hosting:**
- Self-hosted (Node.js process)
- Docker containerized deployment available
- Coolify-compatible (common deployment platform)
- Vercel-compatible (Node.js export format)

**CI Pipeline:**
- GitHub Actions (implied by README and deploy scripts)
  - pnpm-lock.yaml management: Owned by GitHub Actions
  - Lockfile regeneration on push to master
  - Type checking and testing on pull requests

**Build Scripts:**
- `pnpm build` - Build all workspace packages
- `pnpm build:npm` - Build for NPM publishing
- Release management: `pnpm release`, `pnpm release:canary`, `pnpm release:stable`
- GitHub releases: `pnpm release:github`

## Environment Configuration

**Required env vars:**
- `DATABASE_URL` - PostgreSQL connection string (or omit for embedded Postgres)
- `PORT` - HTTP server port (default: 3100)
- `NODE_ENV` - Development/production environment flag

**Common optional env vars:**
- `HOST` - Server hostname to bind to (default: 127.0.0.1, use 0.0.0.0 for Docker)
- `SERVE_UI` - Whether API server serves built UI (default: true)
- `PAPERCLIP_HOME` - Base directory for config and data (default: ~/.paperclip)
- `PAPERCLIP_PUBLIC_URL` - Public URL for auth redirects (e.g., https://example.com)
- `PAPERCLIP_AUTH_PUBLIC_BASE_URL` - Explicit auth base URL (overrides auto-detection)
- `PAPERCLIP_DEPLOYMENT_MODE` - `local_trusted` (default) or `authenticated`
- `PAPERCLIP_STORAGE_PROVIDER` - `local_disk` (default) or `s3`
- `PAPERCLIP_SECRETS_PROVIDER` - `local_encrypted` (default) for secret encryption
- `PAPERCLIP_TELEMETRY_DISABLED` - Set to 1 to disable telemetry
- `PAPERCLIP_FEEDBACK_EXPORT_BACKEND_URL` - Feedback trace export endpoint
- `PAPERCLIP_FEEDBACK_EXPORT_BACKEND_TOKEN` - Bearer token for feedback export

**Secrets location:**
- Encrypted local files: `~/.paperclip/secrets-key` (master encryption key)
- Database: Auth credentials stored in PostgreSQL (better-auth tables)
- S3 credentials: AWS SDK auto-detect (env vars or IAM role)

## Webhooks & Callbacks

**Incoming:**
- HTTP adapter webhook endpoint: Agents POST to configurable HTTP URLs
  - Receives: Agent context, run ID, execution status
  - Response: HTTP status code validation only
  - Timeout: Configurable per-execution

**Outgoing:**
- Feedback trace export: POST to optional telemetry backend
  - Endpoint: Configurable via environment
  - Content: Trace bundle with company ID, execution logs, costs
- Telemetry events: POST to Paperclip telemetry service (telemetry.paperclip.ing)

## Agent Adapters (Multi-Runtime Support)

**Supported Agent Types:**
- OpenClaw Gateway - Remote agent orchestration (`adapter-openclaw-gateway`)
- Claude Local - Claude code execution via local MCP/socket (`adapter-claude-local`)
- Codex Local - Codex agent support (`adapter-codex-local`)
- Cursor Local - Cursor IDE integration (`adapter-cursor-local`)
- Gemini Local - Google Gemini support (`adapter-gemini-local`)
- OpenCode Local - OpenCode runtime (`adapter-opencode-local`)
- Pi Local - Pi agent support (`adapter-pi-local`)
- HTTP Adapter - Generic HTTP webhook execution (`adapters/http/`)
- Process Adapter - Local process execution (`adapters/process/`)
- Hermes Adapter - Legacy/3rd party agent support (`hermes-paperclip-adapter`)

**Adapter Framework:**
- Location: `packages/adapters/`
- Each adapter implements execution interface with timeout/heartbeat support
- Config validation via Zod schemas
- UI config fields: Adapter-specific forms in `ui/src/adapters/*/config-fields.tsx`

---

*Integration audit: 2026-04-03*
