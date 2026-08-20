---
name: 'Packages: Conan'
external_docs: https://docs.gitlab.com/api/packages/conan_v1/
---
> [!warning]
> The Conan registry is not FIPS compliant and is disabled when FIPS mode is enabled. These
> endpoints all return `404 Not Found`.

Use this API to interact with the Conan package manager for
[v1](../../../../doc/user/packages/conan_1_repository/_index.md) and
[v2](../../../../doc/user/packages/conan_2_repository/_index.md) repositories. The v1 endpoints work
for both projects and instances, and the availability of the v2 endpoints is controlled by a feature
flag. Generally these endpoints are used by the Conan package manager client and are not meant for
manual consumption.

> [!note]
> These endpoints do not adhere to the standard API authentication methods. See each route for
> details on how credentials are expected to be passed. Undocumented authentication methods might be
> removed in the future.
