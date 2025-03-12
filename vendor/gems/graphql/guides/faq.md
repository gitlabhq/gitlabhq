---
layout: guide
doc_stub: false
search: true
title: FAQ
other: true
desc: How to do common tasks
---


Returning Route URLs
====================
With GraphQL there is less of a need to include resource URLs to other REST resources, however sometimes you want to use Rails routing to include a URL as one of your fields. A common use case would be to build HTML format URLs to render a link in your React UI. In that case you can pass the request to your context, so that the helpers are able to build full URLs based on the incoming host, port and protocol.

Example
-------
```ruby
class Types::UserType < Types::BaseObject
  include ActionController::UrlFor
  include Rails.application.routes.url_helpers
  # Needed by ActionController::UrlFor to extract the host, port, protocol etc. from the current request
  def request
    context[:request]
  end
  # Needed by Rails.application.routes.url_helpers, it will then use the url_options defined by ActionController::UrlFor
  def default_url_options
    {}
  end
  
  field :profile_url, String, null: false
  def profile_url
    user_url(object)
  end
end

# In your GraphQL controller, add the request to `context`:
MySchema.execute(
  params[:query],
  variables: params[:variables],
  context: {
    request: request
  },
)
```

Returning ActiveStorage blob URLs
=================================
If you are using ActiveStorage and need to return a URL to an attachment blob, you will find that using `Rails.application.routes.url_helpers.rails_blob_url` alone will throw an exception since Rails won't know what host, port or protocol to use in it.
You can include `ActiveStorage::SetCurrent` in your GraphQL controller to pass on this information into your resolvers.

Example
=======

```ruby
class GraphqlController < ApplicationController
  include ActiveStorage::SetCurrent
  ...
end

class Types::UserType < Types::BaseObject
  field :picture_url, String, null: false
  def picture_url
    Rails.application.routes.url_helpers.rails_blob_url(
      object.picture,
      protocol: ActiveStorage::Current.url_options[:protocol],
      host: ActiveStorage::Current.url_options[:host],
      port: ActiveStorage::Current.url_options[:port]
    )
  end
end
```
