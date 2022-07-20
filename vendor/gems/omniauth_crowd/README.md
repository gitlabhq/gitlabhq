# omniauth_crowd

This is fork of [omniauth_crowd](https://github.com/robdimarco/omniauth_crowd) to support:

1. OmniAuth v1 and v2. OmniAuth v2 disables GET requests by default
   and defaults to POST. GitLab already has patched v1 to use POST,
   but other dependencies need to be updated:
   https://gitlab.com/gitlab-org/gitlab/-/issues/30073.
2. We may deprecate this library entirely in the future:
   https://gitlab.com/gitlab-org/gitlab/-/issues/366212

The omniauth_crowd library is an OmniAuth provider that supports authentication against Atlassian Crowd REST apis.

[![Build Status](https://travis-ci.org/robdimarco/omniauth_crowd.svg?branch=master)](https://travis-ci.org/robdimarco/omniauth_crowd)

## Helpful links

*	[Documentation](http://github.com/robdimarco/omniauth_crow)
*	[OmniAuth](https://github.com/intridea/omniauth/)
* [Atlassian Crowd](http://www.atlassian.com/software/crowd/)
* [Atlassian Crowd REST API](http://confluence.atlassian.com/display/CROWDDEV/Crowd+REST+APIs)

## Install and use

### 1. Add the OmniAuth Crowd REST plugin to your Gemfile

    gem 'omniauth', '>= 1.0.0'  # We depend on this
    gem "omniauth_crowd"

### 2. You will need to configure OmniAuth to use your crowd authentication.  This is generally done in Rails in the config/initializers/omniauth.rb with...

    Rails.application.config.middleware.use OmniAuth::Builder do
      provider :crowd, :crowd_server_url=>"https://crowd.mycompanyname.com/crowd", :application_name=>"app", :application_password=>"password"
    end

You will need to supply the correct server URL, application name and password

## Contributing to omniauth_crowd
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2011-14 Rob Di Marco. See LICENSE.txt for
further details.

