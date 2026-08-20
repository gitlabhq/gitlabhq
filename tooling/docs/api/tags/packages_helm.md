---
name: 'Packages: Helm'
external_docs: https://docs.gitlab.com/api/packages/helm/
---
Use this API to interact with [Helm package clients](../../../../doc/user/packages/helm_repository/_index.md).

> [!warning]
> This API is used by the Helm-related package clients such as [Helm](https://helm.sh/)
> and [`helm-push`](https://github.com/chartmuseum/helm-push/#readme),
> and is generally not meant for manual consumption.

These endpoints do not adhere to the standard API authentication methods.
See the [Helm registry documentation](../../../../doc/user/packages/helm_repository/_index.md)
for details on which headers and token types are supported. Undocumented authentication methods might be removed in the future.
