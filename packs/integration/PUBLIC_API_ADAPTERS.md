# Public application API adapters

Integration query adapters consume narrow public application APIs from owning bounded contexts. They do not access another package's ActiveRecord models.

## Candidate read adapter

`Integration::Read::Adapters::CandidatesGet` implements `candidates.get.v1` through an injected candidate API that responds to:

```ruby
fetch_candidate(candidate_id:)
```

The Talent Profile public API provides exactly that operation and returns an immutable snapshot with public typed identifiers.

The adapter deliberately receives the API object through composition instead of referencing `TalentProfile::Api` as a constant. This keeps the Integration contract independently testable and avoids coupling the adapter implementation to package internals.

## Opening read adapters

`Integration::Read::Adapters::OpeningsSearch` and `Integration::Read::Adapters::OpeningsGet` consume an injected public API with:

```ruby
search_openings(**attributes)
fetch_opening(opening_id:)
```

`attributes` is the normalized `openings.search.v1` input and may contain `query`, `filters`, `cursor`, and `limit`. Integration does not define Market Catalog filter fields; the generic `filters` object is passed through unchanged.

`opening_id` remains an opaque public identifier. Integration never parses it into an ActiveRecord primary key.

`MarketCatalog::Api` now provides this public read surface, so these adapters can be composed against the owning bounded context without private model access.

## Application read adapter

`Integration::Read::Adapters::ApplicationsGet` defines the Integration-side API shape expected from the future Personal CRM public read surface:

```ruby
fetch_application(application_id:)
```

`application_id` remains opaque. Personal CRM currently has no public application API implementation, so this adapter remains intentionally contract-first.

## Workspace execution scope

Owning package reads may require an established current workspace and PostgreSQL tenant scope. Integration represents this requirement as `Integration::Read::Ports::WorkspaceScope`.

`Integration::Read::Adapters::PublicApiWorkspaceScope` implements that port through an injected Workspace public API that responds to:

```ruby
with_workspace(workspace_id:) { ... }
```

The adapter passes `context.workspace_id` through unchanged. It never resolves `Organization`, manipulates `Current`, or sets PostgreSQL session state itself. The Workspace bounded context owns those responsibilities behind `Workspace::Api.with_workspace`.

```ruby
workspace_scope.call(context) do
  candidate_api.fetch_candidate(candidate_id: query.input.fetch(:id))
end
```

The same scope can wrap opening and application reads. MCP, HTTP, and CLI adapters therefore remain unaware of Rails tenant implementation details.

The Workspace scope adapter also accepts `not_found_errors:` through composition. Configured owning-package lookup errors are normalized to `Integration::Read::Error::NotFound`; unexpected exceptions are re-raised.

## Not-found mapping

Owning public APIs may expose package-specific or framework-specific exceptions while implementations mature. Integration does not import those exception classes directly.

Read adapters and the Workspace scope adapter accept `not_found_errors:` during composition and map only those configured exception classes to `Integration::Read::Error::NotFound`. Any unexpected exception is re-raised rather than hidden behind a misleading stable error.

This keeps the Integration package independent from ActiveRecord and from concrete owning-package error classes while preserving stable protocol errors at the external boundary.

## Composition

The intended read paths are:

```text
candidates.get.v1
       |
       v
Integration::Read::Adapters::CandidatesGet
       |
       +--> Integration::Read::Adapters::PublicApiWorkspaceScope
       |          |
       |          v
       |     Workspace public API
       |
       v
Talent Profile public API

openings.search.v1 / openings.get.v1
       |
       v
Integration::Read::Adapters::OpeningsSearch / OpeningsGet
       |
       +--> Integration::Read::Adapters::PublicApiWorkspaceScope
       |          |
       |          v
       |     Workspace public API
       |
       v
Market Catalog public API

applications.get.v1
       |
       v
Integration::Read::Adapters::ApplicationsGet
       |
       +--> Integration::Read::Adapters::PublicApiWorkspaceScope
       |
       v
Personal CRM public API (pending)
```

This keeps MCP, HTTP, and CLI adapters stable while each bounded context implements persistence and domain rules behind a narrow public application API.
