---
name: Compliance policy settings
external_docs: https://docs.gitlab.com/api/compliance_policy_settings/
---
Use this API to manage the security policy settings for an instance, and to set the status of
compliance controls that are evaluated by an external service.

Managing security policy settings requires administrator access to the instance, and security policies
require the Ultimate tier.
Setting the status of a compliance control requires HMAC, Timestamp, and Nonce authentication.

External controls support periodic ping functionality. When ping is enabled, which is the default,
GitLab resets the control status to `pending` every 12 hours. When ping is disabled, the control
status changes only through API calls.
