## Unreleased

- [#PR ID] Add your changelog entry here.

## v1.8.9 (2024-05-07)

- Support Doorkeeper 5.7

## v1.8.8 (2024-02-26)

- [#201] Add back typ=JWT to header

## v1.8.7 (2023-05-18)

- [#198] Fully qualify `JWT::JWK::Thumbprint` constant with :: (thanks to @stanhu)

## v1.8.6 (2023-05-12)

- [#194] Default to RFC 7638 kid fingerprint generation (thanks to @stanhu).

## v1.8.5 (2023-02-02)

- [#186] Simplify gem configuration reusing Doorkeeper configuration option DSL (thanks to @nbulaj).
- [#182] Drop support for Ruby 2.6 and Rails 5 (thanks to @sato11).
- [#188] Fix dookeeper-jwt compatibility (thanks to @zavan).

## v1.8.4 (2023-02-01)

Note that v1.8.4 changed the default kid fingerprint generation from RFC 7638 to a format
based on the SHA256 digest of the key element. To restore the previous behavior, upgrade to v1.8.6.

- [#177] Replace `json-jwt` with `ruby-jwt` to align with doorkeeper-jwt (thanks to @kristof-mattei).
- [#185] Don't call active_record_options for Doorkeeper >= 5.6.3 (thanks to @zavan).
- [#183] Stop render consent screen when user is not logged-in (thanks to @nov).

## v1.8.3 (2022-12-02)

- [#180] Add PKCE support to OpenID discovery endpoint (thanks to @stanhu).

## v1.8.2 (2022-07-13)

- [#168] Allow to use custom doorkeeper access grant model (thanks @nov).
- [#170] Controllers inherit `Doorkeeper::AppliactionMetalController` (thanks @sato11).
- [#171] Correctly override `AuthorizationsController` params (thanks to @nbulaj).

## v1.8.1 (2022-02-09)

- [#153] Fix ArgumentError caused by client credential validation introduced in Doorkeeper 5.5.1 (thanks to @CircumnavigatingFlatEarther)
- [#161] Fix .well-known/openid-connect issuer (respond to block if provided) (thanks to @fkowal).
- [#152] Expose oauth-authorization-server in routes (thanks to @mitar)

## v1.8.0 (2021-05-11)

No changes from v1.8.0-rc1.

## v1.8.0-rc1 (2021-04-20)

### Upgrading

This gem now requires Doorkeeper 5.5 and Ruby 2.5.

### Changes

- [#138] Support form_post response mode (thanks to @linhdangduy)
- [#144] Support block syntax for `issuer` configuration (thanks to @maxxsnake)
- [#145] Register token flows with the strategy instead of the token class (thanks to @paukul)

## v1.7.5 (2020-12-15)

### Changes

- [#126] Add discovery_url_options option for discovery endpoints URL generation (thanks to @phlegx)

### Bugfixes

- [#123] Remove reference to ApplicationRecord (thanks to @wheeyls)
- [#124] Clone doorkeeper.grant_flows array before appending 'refresh_token' (thanks to @davidbasalla)
- [#129] Avoid to use the config alias while supporting Doorkeeper 5.2 (thanks to @kymmt90)

## v1.7.4 (2020-07-06)

- [#119] Execute end_session_endpoint in the controllers context (thanks to @joeljunstrom)

## v1.7.3 (2020-07-06)

- [#111] Add configuration callback `select_account_for_resource_owner` to support the `prompt=select_account` param
- [#112] Add grant_types_supported to discovery response
- [#114] Fix user_info endpoint when used in api mode
- [#116] Support Doorkeeper API (> 5.4) for registering custom grant flows.
- [#117] Fix migration template to use Rails migrations DSL for association.
- [#118] Use fragment urls for implicit flow error redirects (thanks to @joeljunstrom)

## v1.7.2 (2020-05-20)

### Changes

- [#108] Add support for Doorkeeper 5.4
- [#103] Add support for end_session_endpoint
- [#109] Test against Ruby 2.7 & Rails 6.x

## v1.7.1 (2020-02-07)

### Upgrading

This version adds `on_delete: :cascade` to the migration template for the `oauth_openid_requests` table, in order to fix #82.

For existing installations, you should add a new migration in your application to drop the existing foreign key and replace it with a new one with `on_delete: :cascade` included. Depending on the database you're using and the size of your application this might bring up some concerns, but in most cases the following should be sufficient:

```ruby
class UpdateOauthOpenIdRequestsForeignKeys < ActiveRecord::Migration[5.2]
  def up
    remove_foreign_key(:oauth_openid_requests, column: :access_grant_id)
    add_foreign_key(:oauth_openid_requests, :oauth_access_grants, column: :access_grant_id, on_delete: :cascade)
  end

  def down
    remove_foreign_key(:oauth_openid_requests, column: :access_grant_id)
    add_foreign_key(:oauth_openid_requests, :oauth_access_grants, column: :access_grant_id)
  end
end
```

### Bugfixes

- [#96] Bump `json-jwt` because of CVE-2019-18848 (thanks to @leleabhinav)
- [#97] Fixes for compatibility with Doorkeeper 5.2 (thanks to @linhdangduy)
- [#98] Cascade deletes from `oauth_openid_requests` to `oauth_access_grants` (thanks to @manojmj92)
- [#99] Fix `audience` claim when application is not set on access token (thanks to @ionut998)

## v1.7.0 (2019-11-04)

### Changes

- [#85] This gem now requires Doorkeeper 5.2, Rails 5, and Ruby 2.4

## v1.6.3 (2019-09-24)

### Changes

- [#81] Allow silent authentication without user consent (thanks to @jarosan)
- Don't support Doorkeeper >= 5.2 due to breaking changes

## v1.6.2 (2019-08-09)

### Bugfixes

- [#80] Check for client presence in controller, fixes a 500 error when `client_id` is missing (thanks to @cincospenguinos @urnf @isabellechalhoub)

## v1.6.1 (2019-06-07)

### Bugfixes

- [#75] Fix return value for `after_successful_response` (thanks to @daveed)

### Changes

- [#72] Add `revocation_endpoint` and `introspection_endpoint` to discovery response (thanks to @scarfacedeb)

## v1.6.0 (2019-03-06)

### Changes

- [#70] This gem now requires Doorkeeper 5.0, and actually has done so since v1.5.4 (thanks to @michaelglass)

## v1.5.5 (2019-03-03)

- [#69] Return `crv` parameter for EC keys (thanks to @marco-nicola)

## v1.5.4 (2019-02-15)

### Bugfixes

- [#66] Fix an open redirect vulnerability ([CVE-2019-9837](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-9837), thanks to @meagar)
- [#67] Don't delete existing tokens with `prompt=consent` (thanks to @nov)

### Changes

- [#62] Support customization of redirect params in `id_token` and `id_token token` responses (thanks to @meagar)

## v1.5.3 (2019-01-19)

### Bugfixes

- [#60] Don't break native authorization in Doorkeeper 5.x

### Changes

- [#58] Use versioned migrations for Rails 5.x (thanks to @tvongaza)

## v1.5.2 (2018-09-04)

### Changes

- [#56] The previous release was a bit premature, this fixes some compatibility issues with Doorkeeper 5.x

## v1.5.1 (2018-09-04)

### Changes

- [#55] This gem is now compatible with Doorkeeper 5.x

## v1.5.0 (2018-06-27)

### Features

- [#52] Custom claims can now also be returned directly in the ID token, see the updated README for usage instructions

## v1.4.0 (2018-05-31)

### Upgrading

- Support for Ruby versions older than 2.3 was dropped

### Features

- Redirect errors per Section 3.1.2.6 of OpenID Connect 1.0 (by @ryands)
- Set `id_token` when it's nil in token response (it's used in `refresh_token` requests) (by @Miouge1)

## v1.3.0 (2018-03-05)

### Features

- Support for Implicit Flow (`response_type=id_token` and `response_type=id_token token`),
  see the updated README for usage instructions (by @nashby, @nhance and @stevenvegt)

## v1.2.0 (2017-08-31)

### Upgrading

- The configuration setting `jws_private_key` was renamed to `signing_key`, you can still use the old name until it's removed in the next major release

### Features

- Support for pairwise subject identifiers (by @travisofthenorth)
- Support for EC and HMAC signing algorithms (by @110y)
- Claims now receive an optional third `access_token` argument which allow you to dynamically adjust claim values based on the client's token (by @gigr)

### Bugfixes

## v1.1.2 (2017-01-18)

### Bugfixes

- Fixes the `undefined local variable or method 'pre_auth'` error

## v1.1.1 (2017-01-18)

#### Upgrading

- The configuration setting `jws_public_key` wasn't actually used, it's deprecated now and will be removed in the next major release
- The undocumented shorthand `to_proc` syntax for defining claims (`claim :user, &:name`) is not supported anymore

#### Features

- Claims now receive an optional second `scopes` argument which allow you to dynamically adjust claim values based on the requesting applications' scopes (by @nbibler)
- The `prompt` parameter values `login` and `consent` are now supported
- The configuration setting `protocol` was added (by @gigr)

#### Bugfixes

- Standard Claims are now mapped correctly to their default scopes (by @tylerhunt)
- Blank `nonce` parameters are now ignored

#### Changes

- `nil` values and empty strings are now removed from the UserInfo and IdToken responses
- Allow `json-jwt` dependency at ~> 1.6. (by @nbibler)
- Configuration blocks no longer internally use `instance_eval` which previously gave undocumented and unexpected `self` access to the caller (by @nbibler)

## v1.1.0 (2016-11-30)

This release is a general clean-up and adds support for some advanced OpenID Connect features.

#### Upgrading

- This version adds a table to store temporary nonces, use the generator `doorkeeper:openid_connect:migration` to create a migration
- Implement the new configuration callbacks `auth_time_from_resource_owner` and `reauthenticate_resource_owner` to support advanced features

#### Features

- Add discovery endpoint	 ([a16caa8](/../../commit/a16caa8))
- Add webfinger and keys endpoints for discovery	 ([f70898b](/../../commit/f70898b))
- Add supported claims to discovery response	 ([1d8f9ea](/../../commit/1d8f9ea))
- Support prompt=none parameter	 ([c775d8b](/../../commit/c775d8b))
- Store and return nonces in IdToken responses	 ([d28ca8c](/../../commit/d28ca8c))
- Add generator for initializer	 ([80399fd](/../../commit/80399fd))
- Support max_age parameter	 ([aabe3aa](/../../commit/aabe3aa))
- Respect scope grants in UserInfo response	 ([25f2170](/../../commit/25f2170))
