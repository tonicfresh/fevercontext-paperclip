# Technology Stack

**Analysis Date:** 2026-04-03

## Languages

**Primary:**
- TypeScript 5.7.3 - Used throughout server, UI, CLI, and all workspace packages
- JavaScript - Supported as module type "module" (ES modules)

**Secondary:**
- Shell/Bash - Build and deployment scripts (esbuild, docker, release automation)

## Runtime

**Environment:**
- Node.js 20+ (required as per engines specification)

**Package Manager:**
- pnpm 9.15.4 - Monorepo package manager using workspace protocol (`workspace:*`)
- Lockfile: pnpm-lock.yaml (managed by GitHub Actions CI)

## Frameworks

**Core:**
- Express 5.1.0 - HTTP server framework (`server/src/app.ts`)
- React 19.0.0 - UI library for dashboard (`ui/src/`)
- Vite 6.1.0 - Build tool and dev server for React UI

**Database:**
- Drizzle ORM 0.38.4 - TypeScript ORM with schema migrations
- Embedded PostgreSQL 18.1.0-beta.16 - Default local database (auto-started, no setup needed)
- PostgreSQL 3.4.5 - Client library for external Postgres connections

**Authentication:**
- better-auth 1.4.18 - Open-source auth library with session management, adapter-based design
  - Uses Drizzle adapter for database integration
  - Default secret: `BETTER_AUTH_SECRET` or `PAPERCLIP_AGENT_JWT_SECRET` (dev fallback: "paperclip-dev-secret")

**WebSocket/Real-time:**
- ws 8.19.0 - WebSocket server for live agent events (`server/src/realtime/live-events-ws.ts`)

**CLI:**
- Commander 13.1.0 - Command-line interface framework (`cli/src/index.ts`)
- @clack/prompts 0.10.0 - Interactive CLI prompts

**Testing:**
- Vitest 3.0.5 - Unit test runner (TypeScript-native)
- Playwright 1.58.2 - E2E testing with `tests/e2e/playwright.config.ts`

**Build & Dev:**
- TypeScript 5.7.3 - Compiler for all packages
- esbuild 0.27.3 - Fast JavaScript bundler (CLI build)
- tsx 4.19.2 - TypeScript executor for scripts
- chokidar 4.0.3 - File system watcher (dev mode file changes)

## Key Dependencies

**Critical:**
- drizzle-orm 0.38.4 - Type-safe database queries, schema-driven design
- better-auth 1.4.18 - Session and user management without external auth services
- embedded-postgres 18.1.0-beta.16 - Zero-setup PostgreSQL instance
- @aws-sdk/client-s3 3.888.0 - S3 storage integration for attachments/files

**UI Components:**
- @radix-ui/react-slot 1.2.4 - Unstyled, accessible React components
- lucide-react 0.574.0 - Icon library (React components)
- @tanstack/react-query 5.90.21 - Data fetching and caching
- react-router-dom 7.1.5 - Client-side routing
- @mdxeditor/editor 3.52.4 - Markdown editor component
- lexical 0.35.0 - Rich text editor framework

**Styling:**
- Tailwind CSS 4.0.7 - Utility-first CSS framework
- @tailwindcss/typography 0.5.19 - Typography plugin
- @tailwindcss/vite 4.0.7 - Vite integration for Tailwind
- tailwind-merge 3.4.1 - Merge Tailwind CSS classes

**Utilities:**
- Zod 3.24.2 - TypeScript-first schema validation
- Ajv 8.18.0 - JSON Schema validator for adapter configs
- DOMPurify 3.3.2 - HTML sanitization
- sharp 0.34.5 - Image processing (resizing, format conversion)
- jsdom 28.1.0 - JavaScript implementation of web APIs (testing)
- multer 2.0.2 - File upload middleware
- open 11.0.0 - Open URLs in browser during onboarding
- pino 9.6.0 - Structured JSON logging
- pino-http 10.4.0 - HTTP request logging middleware
- pino-pretty 13.1.3 - Pretty-print pino logs in dev

**Drag & Drop:**
- @dnd-kit/core 6.3.1 - Headless drag-and-drop library
- @dnd-kit/sortable 10.0.0 - Sortable lists
- @dnd-kit/utilities 3.2.2 - Utilities

**Diagram/Visualization:**
- mermaid 11.12.0 - Diagram rendering (org charts, flows)
- react-markdown 10.1.0 - Markdown rendering
- remark-gfm 4.0.1 - GitHub Flavored Markdown support

## Configuration

**Environment:**
- `.env` file in project root (local development)
- `~/.paperclip/.env` (user home directory, persistent config)
- Supports both file-based config (`~/.paperclip/paperclip.json`) and environment variables

**Key Configuration Files:**
- `server/src/config.ts` - Main configuration loader
- `packages/shared/src/config-schema.ts` - Shared config schema validation
- `.env.example` - Example environment variables (DATABASE_URL, PORT, SERVE_UI)

**Build:**
- `server/src/tsconfig.json` - TypeScript configuration for server
- `ui/tsconfig.json` - TypeScript configuration for UI
- `cli/tsconfig.json` - TypeScript configuration for CLI
- `vite.config.ts` - Vite bundler configuration
- `playwright.config.ts` - E2E test configuration

## Platform Requirements

**Development:**
- Node.js 20+ (mandatory)
- pnpm 9.15.4 (monorepo package manager)
- macOS, Linux, or Windows with WSL2 supported

**Production:**
- Node.js 20+ runtime
- PostgreSQL 12+ (for external deployments) or embedded PostgreSQL (for local)
- Optional: AWS S3 bucket (for file storage)
- Exposed ports: 3100 (default API port), configurable via environment

**Docker:**
- Dockerfile included for containerized deployment
- docker-compose quickstart available at `docker/docker-compose.quickstart.yml`

---

*Stack analysis: 2026-04-03*
