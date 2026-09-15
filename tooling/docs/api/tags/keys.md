---
name: Keys
external_docs: https://docs.gitlab.com/api/user_keys/
---
Use this API to retrieve information about [SSH keys](../../../../doc/user/ssh.md), manage a
user's SSH and [GPG keys](../../../../doc/user/project/repository/signed_commits/gpg.md),
and manage [SSH certificates for top-level groups](../../../../doc/user/group/ssh_certificates.md).

Queries about deploy key fingerprints also retrieve information about the projects using that key.
If you use a SHA256 fingerprint in an API call, URL-encode the fingerprint.

Managing group SSH certificates requires the Owner role for a top-level group.
