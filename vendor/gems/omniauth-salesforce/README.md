# omniauth-salesforce

This is fork of [omniauth-salesforce](https://github.com/realdoug/omniauth-salesforce) to support:

1. OmniAuth v1 and v2. OmniAuth v2 disables GET requests by default
   and defaults to POST. GitLab already has patched v1 to use POST,
   but other dependencies need to be updated:
   https://gitlab.com/gitlab-org/gitlab/-/issues/30073.

There is active discussion with the gem owner (via email) about adding some GitLab employees as gem
authors so tha they can push changes. If that happens, the updated/canonical gem
should be used in favor of this vendored fork.

[OmniAuth](https://github.com/intridea/omniauth) Strategy for [salesforce.com](salesforce.com).

Note: This is a fork of the [original](https://github.com/richardvanhook/omniauth-salesforce) project and is now the main repository for the omniauth-salesforce gem for consumption within GitLab.

## Basic Usage

```ruby
require "sinatra"
require "omniauth"
require "omniauth-salesforce"

class MyApplication < Sinatra::Base
  use Rack::Session
  use OmniAuth::Builder do
    provider :salesforce, ENV['SALESFORCE_KEY'], ENV['SALESFORCE_SECRET']
  end
end
```

## Including other sites

```ruby
use OmniAuth::Builder do
    provider :salesforce, 
             ENV['SALESFORCE_KEY'], 
             ENV['SALESFORCE_SECRET']
    provider OmniAuth::Strategies::SalesforceSandbox, 
             ENV['SALESFORCE_SANDBOX_KEY'], 
             ENV['SALESFORCE_SANDBOX_SECRET']
    provider OmniAuth::Strategies::SalesforcePreRelease, 
             ENV['SALESFORCE_PRERELEASE_KEY'], 
             ENV['SALESFORCE_PRERELEASE_SECRET']
    provider OmniAuth::Strategies::DatabaseDotCom, 
             ENV['DATABASE_DOT_COM_KEY'], 
             ENV['DATABASE_DOT_COM_SECRET']
end
```

## Resources

* [Article: Digging Deeper into OAuth 2.0 on Force.com](http://wiki.developerforce.com/index.php/Digging_Deeper_into_OAuth_2.0_on_Force.com)
