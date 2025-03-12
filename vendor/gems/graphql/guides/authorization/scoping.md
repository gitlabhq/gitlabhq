---
layout: guide
search: true
section: Authorization
title: Scoping
desc: Filter lists to match the current viewer and context
index: 4
---


_Scoping_ is a complementary consideration to authorization. Rather than checking "can this user see this thing?", scoping takes a list of items filters it to the subset which is appropriate for the current viewer and context.

For similar features, see [Pundit scopes](https://github.com/varvet/pundit#scopes) and [Cancan's `.accessible_by`](https://github.com/cancancommunity/cancancan/wiki/Fetching-Records).

## `scope:` option

Fields accept a `scope:` option to enable (or disable) scoping, for example:

```ruby
field :products, [Types::Product], scope: true
# Or
field :all_products, [Types::Product], scope: false
```

For __list__ and __connection__ fields, `scope: true` is the default. For all other fields, `scope: false` is the default. You can override this by using the `scope:` option.

## `.scope_items(items, ctx)` method

Type classes may implement `.scope_items(items, ctx)`. This method is called when a field has `scope: true`. For example,

```ruby
field :products, [Types::Product] # has `scope: true` by default
```

Will call:

```ruby
class Types::Product < Types::BaseObject
  def self.scope_items(items, context)
    # filter items here
  end
end
```

The method should return a new list with only the appropriate items for the current `context`.

## Bypassing object-level authorization

If you know that any items returned from `.scope_items` should be visible to the current client, you can skip the normal `.authorized?(obj, ctx)` checks by configuring `reauthorize_scoped_objects(false)` in your type definition. For example:

```ruby
class Types::Product < Types::BaseObject
  # Check that singly-loaded objects are visible to the current viewer
  def self.authorized?(object, context)
    super && object.visible_to?(context[:viewer])
  end

  # Filter any list to only include objects that are visible to the current viewer
  def self.scope_items(items, context)
    items = super(items, context)
    items.visible_for(context[:viewer])
  end

  # If an object of this type was returned from `.scope_items`,
  # don't call `.authorized?` with it.
  reauthorize_scoped_objects(false)
end
```
