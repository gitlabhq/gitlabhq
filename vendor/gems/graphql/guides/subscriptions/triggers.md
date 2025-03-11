---
layout: guide
doc_stub: false
search: true
section: Subscriptions
title: Triggers
desc: Sending updates from your application to GraphQL
index: 2
---

From your application, you can push updates to GraphQL clients with `.trigger`.

Events are triggered _by name_, and the name must match fields on your {% internal_link "Subscription Type","subscriptions/subscription_type" %}

```ruby
# Update the system with the new blog post:
MySchema.subscriptions.trigger(:post_added, {}, new_post)
```

The arguments are:

- `name`, which corresponds to the field on subscription type
- `arguments`, which corresponds to the arguments on subscription type (for example, if you subscribe to comments on a certain post, the arguments would be `{post_id: comment.post_id}`.)
- `object`, which will be the root object of the subscription update
- `scope:` (shown below) for implicitly scoping the clients who will receive updates.

## Scope

To send updates to _certain clients only_, you can use `scope:` to narrow the trigger's reach.

Scopes are based on query context: a value in `context:` is used as the scope; an equivalent value must be passed with `.trigger(... scope:)` to update that client. (The value is serialized with {{ "GraphQL::Subscriptions::Serialize" | api_doc }})

To specify that a topic is scoped, add a `subscription_scope` option to the Subscription class:

```ruby
class Subscriptions::CommentAdded < Subscription::BaseSubscription
  description "A comment was added to one of the viewer's posts"
  # For a given viewer, this will be triggered
  # whenever one of their posts gets a new comment
  subscription_scope :current_user_id
  # ...
end
```

(Read more in the {% internal_link "Subscription Classes guide", "subscriptions/subscription_classes#scope" %}.)

Then, subscription operations should have a `context: { current_user_id: ... }` value, for example:

```ruby
# current_user_id will be the scope for some subscriptions:
MySchema.execute(query_string, context: { current_user_id: current_user.id })
```

Finally, when events happen in your app, you should provide the scoping value as `scope:`, for example:

```ruby
# A new comment is added
comment = post.comments.create!(attrs)
# notify the author
author_id = post.author.id
MySchema.subscriptions.trigger(:comment_added, {}, comment, scope: author_id)
```

Since this trigger has a `scope:`, only subscribers with a matching scope value will be updated.

## Validation

By default, subscriptions are re-validated when a trigger causes them to send updates. To disable this, you can pass `validate_update: false` when hooking up subscriptions to your schema. For example:

```ruby
use SomeSubscriptions, validate_update: false
```

If you're sure you won't be releasing breaking changes to your schema, this setting can reduce overhead in evaluating updates.
