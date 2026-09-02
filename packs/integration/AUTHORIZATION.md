# Integration capability authorization

Integration read authorization is capability-based at the agent-facing boundary. It does not expose or duplicate Rails role names.

## Stable read capabilities

| Contracts | Capability |
| --- | --- |
| `openings.search.v1`, `openings.get.v1` | `read:openings` |
| `candidates.get.v1` | `read:candidates` |
| `applications.get.v1` | `read:applications` |

The required capability is metadata on the versioned `Integration::Read::Contract`.

## Trust boundary

Capabilities are not accepted from MCP/HTTP/CLI request arguments or from client-supplied query context.

```text
client request
    |
    | principal / credential reference / actor / executor / client provenance
    v
Integration::Read::Context
    |
    v
server-side CapabilityResolver
    |
    v
Integration::Read::CapabilityGrant
    |
    v
Integration::Read::CapabilityAuthorization
    |
    +-- allow -> query port
    |
    +-- deny  -> unauthorized
```

`Integration::Read::Ports::CapabilityResolver` is the seam for the future workspace/auth implementation. It receives the complete read context, so a concrete resolver may scope grants using workspace, authenticated principal, credential, actor, executor, interface, or client as required by policy.

A `CapabilityGrant` is bound to `workspace_id`, `principal`, and `credential`. `CapabilityAuthorization` rejects a grant whose security identity does not match the query context.

This prevents a grant resolved for one authenticated security identity from being reused for another request.

## Roles versus capabilities

Workspace roles such as owner/admin/member or future recruiting-specific roles remain an authorization implementation concern.

A concrete resolver can translate those internal facts into stable Integration capabilities:

```text
workspace membership / role / credential scope
                  |
                  v
        CapabilityResolver
                  |
                  v
          read:openings
          read:candidates
```

Agent-facing contracts therefore do not change when the internal role model changes.

## Tool discovery

Publishing a tool definition is not the security boundary. A client may know that `applications.get` exists and still receive `unauthorized` when its resolved grant lacks `read:applications`.

A future MCP runtime may additionally filter tool discovery by resolved capabilities, but execution-time authorization remains mandatory.

## Intentionally not implemented

- persistence for agent credentials or capability grants
- translation from ActionPolicy/workspace membership to capabilities
- MCP authentication middleware
- capability administration UI/API
- write capabilities and stricter identity-resolution capabilities

Those can be composed behind `CapabilityResolver` without changing the current read contracts.
