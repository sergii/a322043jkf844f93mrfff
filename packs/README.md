# LMX packages

LMX is a domain-driven modular monolith. These directories are the intended bounded-context ownership boundaries.

Packwerk enforcement will be enabled after the donor dependency/lockfile baseline is portable. Until then, `package.yml` files document the intended privacy/dependency boundaries and give code migration a stable destination.

Initial packages:

- `workspace` - workspace identity, users, memberships, tenant execution context
- `acquisition` - sources, adapters, raw payloads, ingestion records, source observations
- `market_catalog` - companies, opening parties, job openings/postings, identity resolution, lifecycle
- `talent_profile` - candidates, profile versions, experience, skills, evidence
- `intelligence` - match assessments, ranking, derived interpretation
- `personal_crm` - applications, contacts, interactions, interviews, next actions
- `recruiting` - optional client recruiting/engagement workflows
- `delivery` - Telegram and other notification delivery policies
- `integration` - API, MCP, webhook, agent credentials and external processor adapters

Cross-package access should move through explicit public APIs, commands/queries, or versioned events instead of arbitrary private model references.
