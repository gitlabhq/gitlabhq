---
name: Service accounts
external_docs: https://docs.gitlab.com/api/service_accounts/
---
Use this API to interact with [service accounts](../../../../doc/user/profile/service_accounts.md).

The number of service accounts you can create depends on your subscription and offering:

- On GitLab Premium and Ultimate, you can create an unlimited number of service accounts for all offerings.
- On GitLab Free, limits vary by offering:
  - For GitLab.com, you can create up to 100 service accounts for each top-level group.
    This includes service accounts created in subgroups or projects.
  - For GitLab Self-Managed, you can create up to 100 service accounts for the entire instance.
    This includes service accounts created for the instance, a group, or a project.

You can also interact with service accounts through the [users API](../../../../doc/api/users.md).
To manage SSH keys for service accounts, use the [user SSH and GPG keys API](../../../../doc/api/user_keys.md).
