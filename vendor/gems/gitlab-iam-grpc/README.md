# gitlab-iam-grpc

Vendored gRPC client stubs for talking to the IAM service
([gitlab-org/auth/iam](https://gitlab.com/gitlab-org/auth/iam)).
The files under `lib/` are generated. Do not edit them by hand.

## Updating

From the root of the Rails monolith, run:

```shell
scripts/update-iam-grpc-client.sh
```

It clones the IAM repo, regenerates the `auth`, `relationships`, and
`update` service stubs (plus the `buf/validate` support stubs), records
the source commit in `REVISION`, and commits the result. Set `REF` to
generate from a specific branch, tag, or commit (defaults to `main`):

```shell
REF=my-branch scripts/update-iam-grpc-client.sh
```

Requirements: `buf` and the `grpc-tools` gem (which provides
`grpc_tools_ruby_protoc`) on your `PATH`. `buf` needs access to the Buf
Schema Registry to resolve the protovalidate dependency.

For more background, see the IAM repo's
[Rails gRPC client updates](https://gitlab.com/gitlab-org/auth/iam/-/blob/main/docs/rails-grpc-client-updates.md)
doc.
