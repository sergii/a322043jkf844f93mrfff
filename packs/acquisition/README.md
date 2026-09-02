# Acquisition

The Acquisition bounded context owns how LMX retrieves and preserves external evidence. It does not decide whether two observations describe the same real-world opening and it never mutates Market Catalog aggregates directly.

## Phase 0 persistence contract

The durable chain is:

```text
SourceRun -> RawPayload -> IngestionRecord -> SourceObservation
```

### SourceRun

`SourceRun` records one acquisition attempt for a source. It preserves the source key, acquisition transport, start/finish times, collector/adapter/parser versions, counts where meaningful, failure details, and replay/source-health provenance.

A terminal run is either `succeeded` or `failed`. A successful run with `observed_count = 0` is intentionally different from a failed run. Terminal outcome data is immutable.

Acquisition transports describe how external source evidence was retrieved. They are deliberately distinct from ingress interfaces such as API, webhook, MCP, import, or manual web entry.

### RawPayload

`RawPayload` preserves source material when practical together with a SHA-256 digest, content type, encoding, source URI, capture time, byte size, and provenance.

Pass a `String` when byte-for-byte source material is available. The body is stored as binary data so its digest describes the exact persisted bytes. Structured Ruby/JSON input is serialized deterministically as a pragmatic fallback.

Persisted raw payloads are immutable and can survive parser failure independently of observations. They can also be reused by a later parser version for replay/reprocessing.

### IngestionRecord

`IngestionRecord` records how a raw capture was processed into LMX evidence. It links the source run and raw payload to one or more observations and keeps collector/adapter/parser versions plus provenance. An optional `ingress_interface` records how an external collector or agent submitted evidence to LMX without confusing that interface with the source run's acquisition transport. A newer parser may create a new ingestion record against the same immutable raw payload.

### SourceObservation

`SourceObservation` is immutable evidence of what a source showed at a point in time. It retains source and ingestion timestamps, source IDs/URLs, presence evidence, parser version, raw-payload digest/reference, structured factual output, and metadata.

An observation is not a `JobPosting` and is not a domain event by itself. Reconciliation in Market Catalog consumes observations through an explicit package boundary and decides whether canonical state should change.

## Public application API

Collectors and integrations should use the narrow Acquisition application APIs instead of writing package models directly:

```ruby
source_run = Acquisition::SourceRuns.start(...)
raw_payload = Acquisition::RecordRawPayload.call(source_run:, ...)
observation = Acquisition::RecordSourceObservation.call(source_run:, raw_payload:, ...)
Acquisition::SourceRuns.succeed(source_run:, observed_count: 0, ...)
```

`RecordSourceObservation` may also receive raw input directly as a convenience. For collectors that must preserve evidence even when parsing fails, record the `RawPayload` first and then process it.

Failures use `Acquisition::SourceRuns.fail`. Start, completion, raw capture, ingestion, and observation recording are idempotent for the same identity. Reusing an idempotency identity with conflicting evidence raises an explicit conflict rather than silently rewriting history.
