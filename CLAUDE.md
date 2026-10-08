# CLAUDE.md

Guidance for Claude (and any contributor) working on this repository. The design reference is [README.md](README.md): architecture, protocol, threat model and ADRs. **Read it before any work.** If the code and the README disagree, stop and discuss. Don't silently diverge.

## Project in one paragraph

Agreg (working title) is a self-hosted dashboard that monitors a fleet of WordPress sites: updates, versions, Site Health, pending comments, uptime, TLS expiry, and known vulnerabilities matched locally. It has two deliverables: a **Laravel + Inertia + React/TypeScript dashboard** (`dashboard/`) and a **dependency-free WordPress connector plugin** (`connector/`). v1 is **strictly read-only**. It is also a portfolio project, so code quality, tests and documentation matter as much as features.

## Non-negotiable rules

1. **No credentials or private keys in the database.** Ever. Per-site keys are derived from the master secret (env) via HKDF, as described in README §5.1.
2. **The connector stays read-only in v1.** No endpoint, hook or option may modify the site beyond the connector's own options.
3. **The connector has zero runtime dependencies** and must run on **PHP 7.4 to 8.x**. No union types, no `match`, no named arguments, no enums, no `readonly`, no constructor promotion in `connector/`. Dev tooling (PHPCS, PHPUnit) is fine.
4. **Every outbound HTTP request from the dashboard goes through the SSRF-safe client** (threat T9). Never call `Http::get()` directly on a user-supplied URL.
5. **Data coming from sites is untrusted.** Validate the schema, cap sizes, never render it as HTML.
6. **Secrets never reach logs:** signatures, pairing codes, keys, TOTP secrets.
7. **Constant-time comparisons** (`hash_equals`, libsodium) for anything secret.
8. **The plugin inventory is never sent to a third party.** Vulnerability matching is local.
9. Any change that touches the protocol or the security model **updates the README threat model in the same change**.

## Architecture rules (ADR-009, ADR-010)

- **Rigor where it matters, simplicity elsewhere.** Over-engineering is a defect, just like spaghetti code. Before adding an interface, a layer or an abstraction, ask: does it protect a business rule or make it testable? If not, don't add it.
- **Dashboard layers:** `Domain` (pure PHP) ← `Application` (use cases + ports) ← `Infrastructure` (Laravel adapters) and `Http` (thin controllers). Dependencies point inward only.
- `Domain` never imports `Illuminate\*`, Eloquent, facades or helpers like `now()` / `config()`. Time comes from a `Clock` port.
- **Writes go through a use case. Read-only screens query directly** with a dedicated query class. No domain mapping just to display data.
- Eloquent models live in `Infrastructure` and never cross into `Domain`.
- **Connector:** WordPress functions are only called from `connector/src/WordPress/` adapters. `Domain` code is testable without WordPress.
- **Protocol:** all wire-protocol logic lives in `packages/protocol`. Never reimplement a canonical string, signature or derivation elsewhere. Changing it means regenerating the test vectors and bumping the protocol version.
- Architecture tests enforce these rules. If one fails, fix the design, never the test.

## Conventions

- **Language:** code, comments, docs and commits are in English. Discussion with the maintainer is in French.
- **Small blocks:** work one roadmap block at a time. A block is done when its description is met **and tested**.
- **Tests are part of the block**, not a later step. Security-relevant code references its threat ID in the test name or docblock (e.g. `T5: rejects a replayed nonce`).
- **Connector:** WordPress Coding Standards (PHPCS), everything prefixed `agreg_` / namespaced `Agreg\Connector`, escape on output, sanitize on input, capability checks on admin screens.
- **Dashboard:** Laravel conventions, PHPStan/Larastan at a strict level, strict TypeScript, no `any`.
- **Teaching mode:** the maintainer knows PHP and WordPress well, has Laravel basics, and is new to Docker. When introducing a Docker or Laravel concept for the first time, explain it briefly.
- **Commits:** one logical change per commit, conventional prefixes (`feat(connector):`, `fix(dashboard):`, `docs:`, `test:`, `chore:`).

## Repository layout (target)

```
/
├── README.md              design reference (will later be split into docs/)
├── CLAUDE.md              this file
├── docker-compose.yml     dev and demo environment
├── dashboard/             Laravel application
│   └── app/{Domain,Application,Infrastructure,Http}
├── connector/             WordPress plugin
│   ├── src/{Domain,Port,WordPress,Entry}
│   └── lib/protocol/      build-time copy of packages/protocol (never edit by hand)
├── packages/protocol/     shared wire-protocol library, PHP 7.4, no dependencies
└── docs/
    ├── protocol.md        wire protocol spec
    ├── schema/            JSON Schemas of connector payloads
    ├── test-vectors.json  shared crypto test vectors
    └── adr/               architecture decision records
```

## Commands

*To be filled in as blocks land (Docker, tests, lint, build).*

---

## Roadmap v1

Status: ☐ todo · ◐ in progress · ☑ done

Each block is sized for one focused work session and ends with green tests and at least one commit.

### Phase 0: Foundations

- ☑ **0.1 Architecture ADR.** Write ADR-009 (layers, dependency rule, folder layout for dashboard and connector, shared protocol package). Update the README and this file.
- ☑ **0.2 Git repository.** `git init`, `.gitignore`, `.gitattributes` (force LF line endings, essential on Windows), `.editorconfig`, LICENSE, first commit.
- ☐ **0.3 GitHub remote.** Create the repository, push, set description and topics.
- ☐ **0.4 Docker installation and concepts.** Docker Desktop with WSL 2, `hello-world`, and the four core notions: image, container, volume, network. No project files yet.
- ☐ **0.5 Docker: MySQL service.** Compose file with MySQL, named volume, `.env` for credentials, `.env.example` committed.
- ☐ **0.6 Docker: legacy WordPress.** WordPress on PHP 7.4, probably a custom image because official 7.4 tags are no longer maintained.
- ☐ **0.7 Docker: modern WordPress.** WordPress on PHP 8.3, plus a WP-CLI service that installs both sites automatically.
- ☐ **0.8 Docker: connector mount.** `connector/` mounted as a plugin in both sites (placeholder plugin), so code changes are live.
- ☐ **0.9 Laravel skeleton.** Generate the app in `dashboard/` with the official React starter kit (Inertia + TypeScript).
- ☐ **0.10 Docker: dashboard service.** PHP 8.3 container + Vite, dedicated database and user (separate from the WordPress ones), migrations run.
- ☐ **0.11 Architecture skeleton.** Create the layer folders from ADR-009 and **architecture tests** that fail the build if a layer breaks the dependency rule.
- ☐ **0.12 Dashboard quality tooling.** Pint, Larastan (max level), ESLint + Prettier, `tsc --strict`, composer/npm scripts.
- ☐ **0.13 Connector quality tooling.** PHPCS + WordPress Coding Standards + PHPCompatibilityWP (verifies PHP 7.4 compatibility statically), PHPUnit.
- ☐ **0.14 CI: dashboard.** GitHub Actions: lint, static analysis, tests, `composer audit`, `npm audit`.
- ☐ **0.15 CI: connector.** GitHub Actions: PHPCS and tests on a PHP 7.4 / 8.1 / 8.3 / 8.4 matrix.

### Phase 1: Protocol

- ☐ **1.1 Spec: keys.** `docs/protocol.md`: key types, HKDF derivation, key versions, fingerprints.
- ☐ **1.2 Spec: signed requests.** Headers, canonical string, timestamp window, nonce rules.
- ☐ **1.3 Spec: pairing.** Pairing code format, `/pair` payload, HMAC proof, TTL and single use.
- ☐ **1.4 Spec: responses and errors.** Signed response, error behavior, `docs/schema/status.v1.json` (JSON Schema of the inventory).
- ☐ **1.5 Protocol package.** `packages/protocol`: pure PHP 7.4, no dependencies. Key derivation, canonical builder, signer/verifier, pairing HMAC.
- ☐ **1.6 Test vectors.** Generated by the package from fixed inputs, reviewed, committed. The package passes them.
- ☐ **1.7 Package integration.** Composer path repository for the dashboard, build-time copy into the connector, CI check that both copies are identical.

### Phase 2: Connector plugin

- ☐ **2.1 Plugin bootstrap.** Main file and header (`License: GPL-2.0-or-later`), `connector/LICENSE` with the full GPL text, autoloader without Composer, activation and deactivation hooks, `uninstall.php`.
- ☐ **2.2 WordPress test harness.** WP test suite running in Docker, first smoke test.
- ☐ **2.3 Ports and adapters.** Interfaces wrapping WordPress functions (environment, options, clock), plus in-memory fakes for unit tests.
- ☐ **2.4 Collector: platform.** Core, PHP and database versions, available core update.
- ☐ **2.5 Collector: plugins and themes.** Versions, available updates, active state.
- ☐ **2.6 Collector: origin.** wordpress.org vs. other, from update-transient data.
- ☐ **2.7 Collector: Site Health.** Research how to read results reliably (some tests are async), then implement counters and critical test names.
- ☐ **2.8 Collector: comments.** Pending comment count only.
- ☐ **2.9 Inventory assembler.** Builds the `status` payload; tests validate it against `status.v1.json`.
- ☐ **2.10 Site key storage.** Keypair generation, storage in options, fingerprint.
- ☐ **2.11 Admin screen.** Settings → Agreg: connection status. Capability checks, nonces, escaping.
- ☐ **2.12 Pairing code.** Generation (15 min TTL, single use), display and copy button.
- ☐ **2.13 `POST /pair` endpoint.** HMAC check, TTL, single use, stores the dashboard public key, signed response.
- ☐ **2.14 Request verifier.** Signature, ±300 s window, nonce cache (T4, T5).
- ☐ **2.15 `GET /status` endpoint.** Returns the inventory, response signed and bound to the request nonce (T7).
- ☐ **2.16 Throttling and generic errors.** Per-IP throttling, identical 401s, routes hidden from the REST index (T11).
- ☐ **2.17 Disconnect and cleanup.** "Disconnect" button, full cleanup on uninstall.
- ☐ **2.18 Connector security pass.** Consolidated tests for T4, T5, T7, T11, T18. PHP matrix green.

### Phase 3: Dashboard core

- ☐ **3.1 Starter-kit cleanup.** Remove self-registration and anything not needed. Users are created from the CLI.
- ☐ **3.2 User creation command.** `php artisan agreg:user:create`.
- ☐ **3.3 Mandatory 2FA.** TOTP enforced for every account (reuse the starter kit's Fortify 2FA if present).
- ☐ **3.4 HTTP hardening.** Secure cookies, session regeneration, security headers, Content Security Policy.
- ☐ **3.5 Login throttling and audit log.** Audit log table, authentication events recorded without sensitive data (T3, T15).
- ☐ **3.6 Fleet domain model.** Site, SiteId, Inventory, Component, Version value objects. Pure PHP.
- ☐ **3.7 Fleet persistence.** Migrations (`sites`, `snapshots`, `components`) and repository implementations.
- ☐ **3.8 Master secret and key derivation.** Config, fail-fast boot check if the secret is missing or weak, derivation through the protocol package.
- ☐ **3.9 SSRF policy.** Pure domain rules: IPv4/IPv6 ranges, IPv4-mapped IPv6, odd IP notations. Heavily unit-tested (T9).
- ☐ **3.10 SSRF-safe HTTP client.** DNS pinning, no redirects, timeouts, response size cap, demo-network exception flag (T9).
- ☐ **3.11 Connector client.** Signed requests, response verification.
- ☐ **3.12 Pair-site use case.** Parse the pairing code, create the site, call `/pair`, verify.
- ☐ **3.13 Pairing UI.** Paste code, show fingerprint, confirm.
- ☐ **3.14 Inventory validation.** Schema, size and depth limits, allow-listed characters (T8).
- ☐ **3.15 Sync-site use case.** Job: signed `/status` call, validation, snapshot storage.
- ☐ **3.16 Scheduling and refresh.** Every 2 h via the scheduler, plus a rate-limited "Refresh now" button.
- ☐ **3.17 Failure diagnostics.** "Not reporting" after 2 missed syncs (T14), clock-skew detection, readable error states.

### Phase 4: Monitoring signals and alerts

- ☐ **4.1 Alert domain.** Alert, Severity, deduplication key, lifecycle (open → resolved).
- ☐ **4.2 Alert pipeline.** Persistence, evaluation after each sync.
- ☐ **4.3 Update rules.** Outdated core, plugins, themes.
- ☐ **4.4 PHP end-of-life rule.** EOL dates kept in a versioned data file.
- ☐ **4.5 Site Health and comment rules.**
- ☐ **4.6 Uptime probe.** Every 5 min, down after 2 consecutive failures, response time recorded.
- ☐ **4.7 TLS expiry check.** Daily, alerts at 14 and 3 days.
- ☐ **4.8 Data retention.** Pruning of old probe results and snapshots.

### Phase 5: Vulnerabilities

- ☐ **5.1 Provider decision.** Research, license and attribution for a public demo, ADR.
- ☐ **5.2 Vulnerability domain model.** Vulnerability, AffectedRange, Severity.
- ☐ **5.3 Version comparator.** Handles WordPress' odd version strings. Heavily unit-tested.
- ☐ **5.4 Range matcher.** Inclusive and exclusive bounds, "low confidence" for non-wordpress.org components.
- ☐ **5.5 Feed download.** Daily job, streamed, size cap, allow-listed host via the safe client.
- ☐ **5.6 Feed validation.** Schema, shrink threshold, last good copy kept (T13).
- ☐ **5.7 Feed storage.** Import indexed by type and slug.
- ☐ **5.8 Vulnerability alerts.** Grouped across the fleet, re-evaluated after each sync and each feed refresh.

### Phase 6: The morning screen

- ☐ **6.1 UI foundations.** Layout, design tokens, status and severity components, dark mode.
- ☐ **6.2 Fleet overview.** Every site's status at a glance, alerts sorted by severity.
- ☐ **6.3 Empty and "all clear" states, data freshness.**
- ☐ **6.4 Site detail: inventory.**
- ☐ **6.5 Site detail: history and alerts.**
- ☐ **6.6 Vulnerability view.** Grouped by component across the fleet.
- ☐ **6.7 Audit log screen.**
- ☐ **6.8 Site management.** Re-pair, remove, key rotation.
- ☐ **6.9 Accessibility and responsive pass.**

### Phase 7: Portfolio release

- ☐ **7.1 Threat model review.** Every T# is linked to its tests or an explicit justification.
- ☐ **7.2 Scale check.** Simulate 200 sites with a fake connector, measure, document.
- ☐ **7.3 Demo data.** 3 demo sites seeded with outdated and vulnerable versions.
- ☐ **7.4 Public demo.** Deployment, read-only demo account, nightly reset (T17).
- ☐ **7.5 README pitch.** Short README with screenshots and a GIF.
- ☐ **7.6 Docs split.** `docs/architecture.md`, `docs/threat-model.md`, `docs/adr/*`.
- ☐ **7.7 Connector release readiness.** `readme.txt`, Plugin Check passing.
- ☐ **7.8 Release v1.0.0.** Tag, changelog.
