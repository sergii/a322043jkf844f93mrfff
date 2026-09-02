# Market Catalog

Market Catalog owns LMX's canonical interpretation of the hiring market.

This package owns:

- `MarketCatalog::Company`
- `MarketCatalog::JobOpening`
- `MarketCatalog::JobPosting`
- `MarketCatalog::PostingSnapshot`
- `MarketCatalog::OpeningParty`
- `MarketCatalog::ResolutionDecision`
- posting identity and posting-to-opening resolution
- market lifecycle state once evidence has been interpreted

It does not own source retrieval, raw payloads, source runs, or `SourceObservation`; those belong to Acquisition. It does not own Candidate profiles, matching/ranking, Applications, recruiting engagements, or notification delivery.

## Global catalog boundary

The canonical market catalog is system-wide rather than workspace-scoped. A public market posting should not be duplicated once per workspace. Workspace-specific Candidates, Applications, preferences, and recruiting workflows may reference these canonical market entities through their own bounded-context APIs.

Private client-only recruiting data belongs in Recruiting, not in the global market catalog.

## Evidence boundary

`SourceObservation` remains owned by Acquisition. Market Catalog stores only its opaque observation identifier when creating a `PostingSnapshot`; there is intentionally no Active Record association across that package boundary.

A `PostingSnapshot` is an immutable normalized view of one source observation for one canonical `JobPosting`. It preserves normalized source facts and their evidence levels before later reconciliation changes market projections. A snapshot can carry `present`, `missing`, `explicit_closed`, or `unknown` source evidence without directly forcing the canonical posting lifecycle to the same state.

Repeated processing of the same source observation is idempotent when normalized content is identical. Different normalized output for the same observation is treated as a conflict rather than silently rewriting historical evidence.

## Legacy donor boundary

The root donor classes `Job`, `JobPosting`, `ClientCompany`, and `Project` implement the old staffing workflow. They are not the canonical LMX market model. During adoption they remain available to legacy screens while new LMX code uses the namespaced Market Catalog models and `market_catalog_*` tables.

## Public application API

Cross-context callers should use `MarketCatalog::Api`. The API returns immutable hashes with typed identifiers rather than leaking Market Catalog Active Record models.

Initial mutation capabilities are:

- `create_company`
- `create_opening`
- `record_posting`
- `record_posting_snapshot`
- `resolve_posting_opening_link`

Initial read capabilities are:

- `fetch_company`
- `fetch_opening`
- `fetch_posting`
- `fetch_posting_snapshot`
- `fetch_posting_history`

Identity resolution follows the canonical deterministic evidence order: source external ID first, then canonical posting URL, then canonical application URL. Company plus title is never sufficient to merge postings or openings.

Resolution decisions are immutable. Re-linking or unlinking creates another `ResolutionDecision` rather than rewriting prior reasoning.
