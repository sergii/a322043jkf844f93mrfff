# Public application API adapters

Integration query adapters consume narrow public application APIs from owning bounded contexts. They do not access another package's ActiveRecord models.

## Candidate read adapter

`Integration::Read::Adapters::CandidatesGet` implements `candidates.get.v1` through an injected candidate API that responds to:

```ruby
fetch_candidate(candidate_id:)
```

The current Talent Profile public API provides exactly that operation and returns an immutable snapshot with public typed identifiers.

The adapter deliberately receives the API object through composition instead of referencing `TalentProfile::Api` as a constant. This keeps the Integration contract independently testable while the parallel package and integration branch continue to move.

## Opening read adapters

`Integration::Read::Adapters::OpeningsSearch` and `Integration::Read::Adapters::OpeningsGet` define the Integration-side API shape expected from the future Market Catalog public read surface:

```ruby
search_openings(**attributes)
fetch_opening(opening_id:)
```

`attributes` is the normalized `openings.search.v1` input and may contain `query`, `filters`, `cursor`, and `limit`. Integration does not define Market Catalog filter fields; the generic `filters` object is passed through unchanged.

`opening_id` remains an opaque public identifier. Integration never parses it into an ActiveRecord primary key.

Market Catalog currently has no public application API implementation. These adapters are therefore contract-first seams backed only by fake adapter tests until the owning package publishes its API.

## Application read adapter

`Integration::Read::Adapters::ApplicationsGet` defines the Integration-side API shape expected from the future Personal CRM public read surface:

```ruby
fetch_application(application_id:)
```

`application_id` remains opaque. Personal CRM currently has no public application API implementation, so this adapter is also intentionally contract-first.

## Workspace execution scope

Owning package reads may require an established current workspace. Integration represents this requirement as `Integration::Read::Ports::WorkspaceScope`.

A future Rails composition adapter can resolve the opaque `context.workspace_id`, establish `WorkspaceContext`, and yield to the public API call:

```ruby
workspace_scope.call(context) do
  candidate_api.fetch_candidate(candidate_id: query.input.fetch(:id))
end
```

The same scope wraps opening and application reads. The MCP adapter must not establish database tenant state itself. Authentication/workspace resolution belongs to the server composition layer before domain reads execute.

## Not-found mapping

Owning public APIs may expose framework-specific exceptions while their implementations mature. Integration does not import those exception classes directly.

The get adapters accept `not_found_errors:` during composition and map only those configured exception classes to `Integration::Read::Error::NotFound`. Any unexpected exception is re-raised rather than hidden behind a misleading stable error.

For the current Talent Profile implementation, the composition layer can configure its public API not-found behavior without making Integration depend on ActiveRecord. Market Catalog and Personal CRM can use the same seam when their public APIs exist.

## Composition

The intended read paths are:

```text
candidates.get.v1
       |
       v
Integration::Read::Adapters::CandidatesGet
       |
       +--> WorkspaceScope
       |
       v
TalentProfile public API

openings.search.v1 / openings.get.v1
       |
       v
Integration::Read::Adapters::OpeningsSearch / OpeningsGet
       |
       +--> WorkspaceScope
       |
       v
Market Catalog public API (pending)

applications.get.v1
       |
       v
Integration::Read::Adapters::ApplicationsGet
       |
       +--> WorkspaceScope
       |
       v
Personal CRM public API (pending)
```

This keeps MCP, HTTP, and CLI adapters stable while each bounded context can implement its own persistence and domain rules behind a narrow public application API.
