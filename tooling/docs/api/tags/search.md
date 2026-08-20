---
name: Search
external_docs: https://docs.gitlab.com/api/search/
---
Use this API to [search across GitLab](../../../../doc/user/search/_index.md) in an instance, a group,
or a project, and to retrieve information about
[advanced search migrations](../../../../doc/integration/advanced_search/elasticsearch.md#advanced-search-migrations).

Every call to this API requires authentication. Retrieving advanced search migrations requires
administrator access.

Some scopes are available for [basic search](../../../../doc/user/search/_index.md#available-scopes).
When [advanced search](../../../../doc/user/search/advanced_search.md#available-scopes) or
[exact code search](../../../../doc/user/search/exact_code_search.md#available-scopes) is
enabled, additional scopes become available. To use basic search instead, see
[specify a search type](../../../../doc/user/search/_index.md#specify-a-search-type).

These endpoints support [offset-based pagination](../../../../doc/api/rest/_index.md#offset-based-pagination).
