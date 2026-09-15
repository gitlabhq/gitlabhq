---
name: AI agent identities
external_docs: https://docs.gitlab.com/user/duo_agent_platform/composite_identity/
---
Use this API to register an external agent identity for a project, so that agent
sessions can be attributed to a user and a machine. Registration returns the existing record if one
already exists, or is rejected if the identity has been revoked.

External agents are published through the
[AI Catalog](../../../../doc/user/duo_agent_platform/ai_catalog.md), and act with a
[composite identity](../../../../doc/user/duo_agent_platform/composite_identity.md) that
combines a service account with the human user who initiated the request.
