# Integration capability authorization

Integration read authorization is capability-based at the agent-facing boundary. It does not expose or duplicate Rails role names.

## Stable read capabilities

| Contracts | Capability |
| --- | --- |
| `openings.search.v1`, `openings.get.v1` | `read:openings` |
| `candidates.get.v1`, `candidates.profile.v1` | `read:candidates` |
| `matches.get.v1` | `read:matches` |
| `applications.get.v1` | `read:applications` |

The required capability is metadata on the versioned `Integration::Read::Contract`.

## Trust boundary

Capabilities are not accepted from MCP/HTTP/CLI request arguments or from client-supplied query context.

```text
client request
    |
    | authenticated principal / credential reference / provenance
    v
Integration::Read::Context
    |
    v
CredentialCapabilityResolver
    |
    v
server-side CredentialSource
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

`Integration::Read::CredentialCapabilityResolver` is the concrete read resolver. It passes the complete immutable read context to an injected server-side `CredentialSource`, so the source may take workspace, authenticated principal, credential, actor, executor, interface, and client provenance into account.

The source returns authorization evidence containing `workspace_id`, `principal`, `credential`, and `capabilities`. The resolver constructs the `CapabilityGrant` itself and rejects a source result whose security identity differs from the request context.

An unknown, expired, or revoked credential should resolve to `nil`; the resolver then fails closed as `unauthenticated`.

A malformed source result is a `contract_violation`, not an implicit deny or an automatically re-bound grant. This makes bugs in security composition visible instead of silently changing authorization behavior.

A `CapabilityGrant` remains bound to `workspace_id`, `principal`, and `credential`. `CapabilityAuthorization` also verifies that binding before evaluating the capability required by the query contract.

## Credential source boundary

`Integration::Read::Ports::CredentialSource` is the persistence/composition seam behind the concrete resolver.

It is intentionally server-side. MCP, HTTP, CLI, and agent clients never provide their own capability arrays. A future source may be backed by:

- Integration-owned agent credential persistence and explicit tool grants
- delegated user credentials whose workspace access has already been resolved by trusted authentication/authorization composition
- service credentials with workspace-specific grants
- a composition layer that intersects credential scope with Workspace authorization facts

The resolver contract does not depend on which persistence or authentication mechanism is selected.

## Roles versus capabilities

Workspace roles such as `workspace_admin`, `recruiter`, or client roles remain an authorization implementation concern and are not copied into Integration contracts.

Do not map every active Workspace membership directly to global Integration read capabilities. Some roles are resource-scoped, such as client access, while current read contracts are workspace-scoped. A trusted credential source or authorization composition layer must preserve that distinction.

Conceptually:

```text
Workspace authorization facts + credential scope
                    |
                    v
        server-side CredentialSource
                    |
                    v
        CredentialCapabilityResolver
                    |
                    v
             read:openings
             read:candidates
             read:matches
```

Agent-facing contracts therefore remain stable when the internal role model changes.

## Tool discovery

Publishing a tool definition is not the security boundary. A client may know that `applications.get` exists and still receive `unauthorized` when its resolved grant lacks `read:applications`.

A future MCP runtime may additionally filter tool discovery by resolved capabilities, but execution-time authorization remains mandatory.

## Intentionally not implemented

- persistence and secret verification for agent credentials
- concrete Workspace/ActionPolicy-to-credential-grant composition
- MCP authentication middleware that establishes the trusted principal and credential reference
- capability administration UI/API
- write capabilities and stricter identity-resolution capabilities

These can be added behind the credential-source and authentication boundaries without changing the current read contracts or authorization flow.
