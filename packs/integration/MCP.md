# MCP read adapter

The MCP layer is intentionally thin. It exposes the shared Integration read contracts without owning domain logic, persistence, authentication, or authorization policy.

```text
MCP transport/runtime
        |
        v
Integration::Mcp::ContextFactory
Integration::Mcp::ReadAdapter
        |
        v
Integration::Read::Dispatcher
        |
        +--> authorization port
        |
        v
query port -> owning package public query implementation
```

`Integration::Mcp::ReadTools` publishes the current read contracts as MCP tool definitions using the JSON Schema owned by each `Integration::Read::Contract`.

Current tools:

- `openings.search`
- `openings.get`
- `candidates.get`
- `applications.get`

The adapter returns the complete Integration outcome as MCP `structuredContent`, mirrors it as JSON text content for model consumption, and sets `isError` for stable contract failures.

`ContextFactory` fixes `interface` to `mcp` while accepting authenticated principal/credential identity and actor/executor/client provenance from the future runtime composition layer.

Still intentionally absent:

- MCP HTTP or stdio server lifecycle
- protocol negotiation/discovery implementation
- authentication middleware
- concrete authorization policy adapter
- direct ActiveRecord access
- concrete owning-package query implementations
- write tools and Transactional Inbox/Outbox handling

Those are composition/runtime concerns and should be added without changing the shared read contract semantics.
