# OmniAuth CAS Strategy [![Gem Version][version_badge]][version] [![Build Status][travis_status]][travis]

This is a fork of [omniauth-cas3](https://github.com/tduehr/omniauth-cas3) to
support:

1. OmniAuth v1 and v2. OmniAuth v2 disables GET requests by default
   and defaults to POST. GitLab already has patched v1 to use POST,
   but other dependencies need to be updated:
   https://gitlab.com/gitlab-org/gitlab/-/issues/30073.
2. We may deprecate this library entirely in the future:
   https://gitlab.com/gitlab-org/gitlab/-/issues/366212

[version_badge]: https://badge.fury.io/rb/omniauth-cas3.png
[version]: http://badge.fury.io/rb/omniauth-cas3
[travis]: http://travis-ci.org/tduehr/omniauth-cas3
[travis_status]: https://secure.travis-ci.org/dlindahl/omniauth-cas3.png
[releases]: https://github.com/tduehr/omniauth-cas3/releases

This is a OmniAuth 1.0 compatible port of the previously available
[OmniAuth CAS strategy][old_omniauth_cas] that was bundled with OmniAuth 0.3. This strategy has also been updated for CAS protocol version 3.0 and patched to deal with namespace issues.

* [View the documentation][document_up]
* [Changelog][releases]

## Installation

Add this line to your application's Gemfile:

    gem 'omniauth-cas3'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install omniauth-cas3

## Usage

Use like any other OmniAuth strategy:

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :cas3, host: 'cas.yourdomain.com'
end
```

### Configuration Options

#### Required

OmniAuth CAS requires at least one of the following two configuration options:

  * `url` - Defines the URL of your CAS server (i.e. `http://example.org:8080`)
  * `host` - Defines the host of your CAS server (i.e. `example.org`).

#### Optional

Other configuration options:

  * `port` - The port to use for your configured CAS `host`. Optional if using `url`.
  * `ssl` - TRUE to connect to your CAS server over SSL. Optional if using `url`.
  * `service_validate_url` - The URL to use to validate a user. Defaults to `'/serviceValidate'`.
  * `callback_url` - The URL custom URL path which CAS uses to call back to the service.  Defaults to `/users/auth/cas3/callback`.
  * `logout_url` - The URL to use to logout a user. Defaults to `'/logout'`.
  * `login_url` - Defines the URL used to prompt users for their login information. Defaults to `/login` If no `host` is configured, the host application's domain will be used.
  * `uid_field` - The user data attribute to use as your user's unique identifier. Defaults to `'user'` (which usually contains the user's login name).
  * `ca_path` - Optional when `ssl` is `true`. Sets path of a CA certification directory. See [Net::HTTP][net_http] for more details.
  * `disable_ssl_verification` - Optional when `ssl` is true. Disables verification.
  * `on_single_sign_out` - Optional. Callback used when a [CAS 3.1 Single Sign Out][sso]
    request is received.
  * `fetch_raw_info` - Optional. Callback used to return additional "raw" user
    info from other sources.

    ```ruby
    provider :cas3,
             fetch_raw_info: lambda { |strategy, options, ticket, user_info|
               ExternalService.get(user_info[:user]).attributes
            }
    ```

Configurable options for values returned by CAS:

  * `uid_key` - The user ID data attribute to use as your user's unique identifier. Defaults to `'user'` (which usually contains the user's login name).
  * `name_key` - The data attribute containing user first and last name.  Defaults to `'name'`.
  * `email_key` - The data attribute containing user email address.  Defaults to `'email'`.
  * `nickname_key` - The data attribute containing user's nickname.  Defaults to `'user'`.
  * `first_name_key` - The data attribute containing user first name.  Defaults to `'first_name'`.
  * `last_name_key` - The data attribute containing user last name.  Defaults to `'last_name'`.
  * `location_key` - The data attribute containing user location/address.  Defaults to `'location'`.
  * `image_key` - The data attribute containing user image/picture.  Defaults to `'image'`.
  * `phone_key` - The data attribute containing user contact phone number.  Defaults to `'phone'`.

## Migrating from OmniAuth 0.3

Given the following OmniAuth 0.3 configuration:

```ruby
provider :CAS, cas_server: 'https://cas.example.com/cas/'
```

Your new settings should look similar to this:

```ruby
provider :cas3,
         host:      'cas.example.com',
         login_url: '/cas/login',
  	     service_validate_url: '/cas/p3/serviceValidate'
```

If you encounter problems wih SSL certificates you may want to set the `ca_path` parameter or activate `disable_ssl_verification` (not recommended).

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Thanks

Special thanks go out to the following people

  * @dlindahl For the original work in porting this from OmniAuth 0.3
  * Phillip Aldridge (@iterateNZ) and JB Barth (@jbbarth) for helping out with Issue #3
  * Elber Ribeiro (@dynaum) for Ubuntu SSL configuration support
  * @rbq for README updates and OmniAuth 0.3 migration guide

[old_omniauth_cas]: https://github.com/intridea/omniauth/blob/0-3-stable/oa-enterprise/lib/omniauth/strategies/cas.rb
[document_up]: http://tduehr.github.com/omniauth-cas3/
[net_http]: http://ruby-doc.org/stdlib-1.9.3/libdoc/net/http/rdoc/Net/HTTP.html
[sso]: https://wiki.jasig.org/display/CASUM/Single+Sign+Out
