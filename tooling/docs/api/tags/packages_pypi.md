---
name: 'Packages: PyPi'
external_docs: https://docs.gitlab.com/api/packages/pypi/
---
Use this API to interact with the [PyPI package manager client](../../../../doc/user/packages/pypi_repository/_index.md).

> [!warning]
> This API is used by the [PyPI package manager client](https://pypi.org/)
> and is generally not meant for manual consumption.

These endpoints do not adhere to the standard API authentication methods.
See the [PyPI package registry documentation](../../../../doc/user/packages/pypi_repository/_index.md)
for details on which headers and token types are supported. Undocumented authentication methods might be removed in the future.

> [!note]
> [Twine 3.4.2](https://twine.readthedocs.io/en/stable/changelog.html?highlight=FIPS#id28) or greater
> is recommended when FIPS mode is enabled.
