# Market Catalog

Market Catalog owns LMX's canonical interpretation of the hiring market.

This package owns:

- `MarketCatalog::Company`
- `MarketCatalog::JobOpening`
- `MarketCatalog::JobPosting`
- `MarketCatalog::OpeningParty`
- `MarketCatalog::ResolutionDecision`
- posting identity and posting-to-opening resolution
- market lifecycle state once evidence has been interpreted

It does not own source retrieval, raw payloads, source runs, or `SourceObservation`; those belong to Acquisition. It does not own Candidate profiles, matching/ranking, Applications, recruiting engagements, or notification delivery.

## Global catalog boundary

The canonical market catalog is system-wide rather than workspace-scoped. A public market posting should not be duplicated once per workspace. Workspace-specific Candidates, Applications, preferences, and recruiting workflows may reference these canonical market entities through their own bounded-context APIs.

Private client-only recruiting data belongs in Recruiting, not in the global market catalog.

## Legacy donor boundary

The root donor classes `Job`, `JobPosting`, `ClientCompany`, and `Project` implement the old staffing workflow. They are not the canonical LMX market model. During adoption they remain available to legacy screens while new LMX code uses the namespaced Market Catalog models and `market_catalog_*` tables.

## Public application API

Initial mutation entry points are:

- `MarketCatalog::CreateCompany`
- `MarketCatalog::CreateOpening`
- `MarketCatalog::RecordPosting`
- `MarketCatalog::ResolvePostingOpeningLink`

Callers should use these application services instead of reaching into package models for cross-context mutations.

Identity resolution follows the canonical evidence order: source external ID first, then canonical posting URL, then canonical application URL. Company plus title is never sufficient to merge postings or openings.

Resolution decisions are immutable. Re-linking or unlinking creates another `ResolutionDecision` rather than rewriting prior reasoning.
