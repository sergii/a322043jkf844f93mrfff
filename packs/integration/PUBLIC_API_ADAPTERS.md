# Public application API adapters

Integration query adapters consume narrow public application APIs from owning bounded contexts. They do not access another package's ActiveRecord models.

## Candidate read adapter

`Integration::Read::Adapters::CandidatesGet` implements `candidates.get.v1` through an injected candidate API that responds to:

```ruby
fetch_candidate(candidate_id:)
```

The current Talent Profile public API provides exactly that operation and returns an immutable snapshot with public typed identifiers.

The adapter deliberately receives the API object through composition instead of referencing `TalentProfile::Api` as a constant. This keeps the Integration contract independently testable while the parallel package and integration branch continue to move.

## Workspace execution scope

The Talent Profile public API requires an established current workspace. Integration represents this requirement as `Integration::Read::Ports::WorkspaceScope`.

A future Rails composition adapter can resolve the opaque `context.workspace_id`, establish `WorkspaceContext`, and yield to the public API call:

```ruby
workspace_scope.call(context) do
  candidate_api.fetch_candidate(candidate_id: query.input.fetch(:id))
end
```

The MCP adapter must not establish database tenant state itself. Authentication/workspace resolution belongs to the server composition layer before domain reads execute.

## Not-found mapping

Owning public APIs may expose framework-specific exceptions while their implementations mature. Integration does not import those exception classes directly.

`CandidatesGet` accepts `not_found_errors:` during composition and maps only those configured exception classes to `Integration::Read::Error::NotFound`. Any unexpected exception is re-raised rather than hidden behind a misleading stable error.

For the current Talent Profile implementation, the composition layer can configure its public API not-found behavior without making Integration depend on ActiveRecord.

## Future composition

Once the working branch is synchronized with an integration base that contains the owning public APIs, the runtime composition can wire:

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
```

The same pattern can later be used for openings and applications when their owning packages publish corresponding public read APIs.
