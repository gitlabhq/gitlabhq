---
name: Instance
external_docs: https://docs.gitlab.com/api/appearance/
---
Use this API to manage an instance's
[appearance](../../../../doc/administration/appearance.md) and
[application settings](../../../../doc/api/settings.md#available-settings), and to retrieve
statistics about the instance.

Changes to application settings are subject to caching and might not take effect immediately. By
default, GitLab caches application settings for 60 seconds. For more information, see
[application cache interval](../../../../doc/administration/application_settings_cache.md).

All of these endpoints require administrator access to the instance.
