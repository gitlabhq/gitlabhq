---
name: Provider identities
external_docs: https://docs.gitlab.com/api/saml/
---
Use this API to manage the SAML and SCIM identities linked to users in a group.

Prerequisites for the SCIM endpoints:

- You must enable [group SSO](../../../../doc/user/group/saml_sso/_index.md).
- You must enable [SCIM for group SSO](../../../../doc/user/group/saml_sso/scim_setup.md).
- You must authenticate with a [personal access token](../../../../doc/user/profile/personal_access_tokens.md)
  or [group access token](../../../../doc/user/group/settings/group_access_tokens.md) that has the correct scope.

These endpoints get, check, update, and delete SCIM identities in groups, and do not implement
the [RFC7644 protocol](https://www.rfc-editor.org/rfc/rfc7644). They differ from the
[internal group SCIM API](../../../../doc/development/internal_api/_index.md#group-scim-api) and the
[internal instance SCIM API](../../../../doc/development/internal_api/_index.md#instance-scim-api),
which implement RFC7644 for SCIM provider integration and require a SCIM token.
