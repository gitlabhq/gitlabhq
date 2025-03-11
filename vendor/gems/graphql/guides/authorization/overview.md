---
layout: guide
search: true
section: Authorization
title: Overview
desc: Overview of GraphQL authorization in general and an intro to the built-in framework.
index: 0
---

Here's a conceptual approach to GraphQL authorization, followed by an introduction to the built-in authorization framework. Each part of the framework is described in detail in its own guide.

## Authorization: GraphQL vs REST

In a REST API, the common authorization pattern is fairly simple. Before performing the requested action, the server asserts that the current client has the required permissions for that action. For example:

```ruby
class PostsController < ApiController
  def create
    # First, check the client's permission level:
    if current_user.can?(:create_posts)
      # If the user is permitted, then perform the action:
      post = Post.create(params)
      render json: post
    else
      # Otherwise, return an error:
      render nothing: true, status: 403
    end
  end
end
```

However, this request-by-request mindset doesn't map well to GraphQL because there's only one controller and the requests that come to it may be _very_ different. To illustrate the problem:

```ruby
class GraphqlController < ApplicationController
  def execute
    # What permission is required for `query_str`?
    # It depends on the string! So, you can't generalize at this level.
    if current_user.can?(:"???")
      MySchema.execute(query_str, context: ctx, variables: variables)
    end
  end
end
```

So, what new mindset will work with a GraphQL API?

For __mutations__, remember that each mutation is like an API request in itself. For example, `Posts#create` above would map to the `createPost(...)` mutation in GraphQL. So, each mutation should be authorized in its own right.

For __queries__, you can think of each individual _object_ like a `GET` request to a REST API. So, each object should be authorized for reading in its own right.

By applying this mindset, each part of the GraphQL query will be properly authorized before it is executed. Also, since the different units of code are each authorized on their own, you can be sure that each incoming query will be properly authorized, even if it's a brand new query that the server has never seen before.

## What About Authentication?

As a reminder:

- _Authentication_ is the process of determining what user is making the current request, for example, accepting a username and password, or finding a `User` in the database from `session[:current_user_id]`.
- _Authorization_ is the process of verifying that the current user has permission to do something (or see something), for example, checking `admin?` status or looking up permission groups from the database.

In general, authentication is _not_ addressed in GraphQL at all. Instead, your controller should get the current user based on the HTTP request (eg, an HTTP header or a cookie) and provide that information to the GraphQL query. For example:

```ruby
class GraphqlController < ApplicationController
  def execute
    # Somehow get the current `User` from this HTTP request.
    current_user = get_logged_in_user(request)
    # Provide the current user in `context` for use during the query
    context = { current_user: current_user }
    MySchema.execute(query_str, context: context, ...)
  end
end
```

After your HTTP handler has loaded the current user, you can access it via `context[:current_user]` in your GraphQL code.

## Authorization in Your Business Logic

Before introducing GraphQL-specific authorization, consider the advantages of application-level authorization. (See the [GraphQL.org post](https://graphql.org/learn/authorization/) on the same topic.) For example, here's authorization mixed into the GraphQL API layer:

```ruby
field :posts, [Types::Post], null: false

def posts
  # Perform an auth check in the GraphQL field code:
  if context[:current_user].admin?
    Post.all
  else
    Post.published
  end
end
```

The downside of this is that, when `Types::Post` is queried in other contexts, the same authorization check may not be applied. Additionally, since the authorization code is coupled with the GraphQL API, the only way to test it is via GraphQL queries, which adds some complexity to tests.

Alternatively, you could move the authorization to your business logic, the `Post` class:

```ruby
class Post < ActiveRecord::Base
  # Return the list of posts which `user` may see
  def self.posts_for(user)
    if user.admin?
      self.all
    else
      self.published
    end
  end
end
```

Then, use this application method in your GraphQL code:

```ruby
field :posts, [Types::Post], null: false

def posts
  # Fetch the posts this user can see:
  Post.posts_for(context[:current_user])
end
```

In this case, `Post.posts_for(user)` could be tested _independently_ from GraphQL. Then, you have less to worry about in your GraphQL tests. As a bonus, you can use `Post.posts_for(user)` in _other_ parts of the app, too, such as the web UI or REST API.

## GraphQL-Ruby's Authorization Framework

Despite the advantages of authorization at the application layer, as described above, there might be some reasons to authorize in the API layer:

- Have an extra assurance that your API layer is secure
- Authorize the API request _before_ running it (see "visibility" below)
- Integrate with code that doesn't have authorization built-in

To accomplish these, you can use GraphQL-Ruby's authorization framework. The framework has three levels, each of which is described in its own guide:

- {% internal_link "Visibility", "/authorization/visibility" %} hides parts of the GraphQL schema from users who don't have full permission.
- {% internal_link "Authorization", "/authorization/authorization" %} checks application objects during execution to be sure the user has permission to access them.

Also, [GraphQL::Pro](https://graphql.pro) has integrations for {% internal_link "CanCan", "/authorization/can_can_integration" %} and {% internal_link "Pundit", "/authorization/pundit_integration" %}.
