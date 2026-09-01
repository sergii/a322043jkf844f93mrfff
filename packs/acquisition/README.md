# Acquisition

The acquisition context owns how LMX learns facts from external and manual sources. It does not decide whether two observations describe the same real-world job opening and it does not own the canonical market catalog.

## SourceObservation

`SourceObservation` is the first durable boundary in the ingestion pipeline. It records what a source exposed at a particular time together with provenance needed for later reprocessing.

Properties:

- append-only after insertion
- transport is explicit (`rss`, `http_api`, `http_scrape`, `browser_crawl`, `webhook`, `api_submission`, `manual`, or `import`)
- raw structured payload is preserved
- payload content has a deterministic SHA-256 digest
- retries with the same source identity, observation timestamp, and content are idempotent
- observing unchanged content at a later time creates another fact, preserving vacancy lifetime evidence
- source facts remain independent from downstream interpretation

The public application entry point is `Acquisition::RecordSourceObservation.call` rather than direct writes from collectors.

## Boundary with market_catalog

A source observation is evidence, not a canonical vacancy. `market_catalog` will consume acquisition facts to resolve companies, openings, postings, cross-source duplicates, lifecycle changes, compensation history, and reopen events.

Future acquisition entities can include source definitions, adapter health, ingestion records, raw-payload object-storage references, parser runs, and transactional inbox records without changing the meaning of `SourceObservation`.
