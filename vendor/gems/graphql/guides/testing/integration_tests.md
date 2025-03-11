---
layout: guide
doc_stub: false
search: true
section: Testing
title: Integration Tests
desc: Run the whole GraphQL stack in tests
index: 2
---

Besides testing {% internal_link "schema structure", "/testing/schema_structure" %}, you should also test your GraphQL system's behavior. There are really a few levels to this:

- __Application-level__ behaviors, like business logic, permissions, and persistence. These behaviors may be shared by your API and user interface.
- __Interface-level__ behaviors, like GraphQL fields, mutations, error scenarios, and HTTP-specific behaviors. These are unique to your GraphQL system.
- __Transport-level__ behaviors, like HTTP headers, parameters and status codes

## Testing Application-Level Behaviors

When it comes to _how your application behaves_, you should lean on _unit tests_ which exercise application primitives directly. For example, if postings require a title and a body, you should write a test for `Post` which asserts that invalid `Post`s fail to save. Several other components of the application may be tested this way:

- Permissions: test your authorization system using example resources and actors. Dedicated, high-level frameworks like [Pundit](https://github.com/varvet/pundit) make it easy to test authorization in isolation.
- Business logic: What are the _operations_ that a user can perform in your system? For example, on a blog, they might be: drafting and publishing posts, moderating comments, filtering posts by category, or blocking users. Test these operations in isolation so you can be confident that the core code is correct.
- Persistence (and other external services): how does your app interact with the "outside world", like databases, files, and third-party APIs? These interactions also deserve specific tests.


By testing these (and other) application-level behaviors _without_ GraphQL, you can reduce the overhead of your test suite and simplify your testing scenarios.

## Testing Interface-Level Behaviors

After building your application, you give it an interface so that people (or other software) can interact with it. Sometimes the interface is a website, other times it's a GraphQL API. The interface has transport-specific primitives that map to your application's primitives. For example, a React app might have components that correspond to `Post`, `Comment`, and a `Moderation` operation. (These components might even be context-specific, like `ThreadComment` or `DraftPost`.) Similarly, a GraphQL interface has types and fields that correspond to the underlying application primitives (like `Post` and `Comment` types, a `Post.isDraft` field, or a `ModerateComment` mutation).

The best way to test a GraphQL interface is with _integration tests_ which run the whole GraphQL system (using `MySchema.execute(...)`). By using an integration test, you can be sure that all of GraphQL-Ruby's internal systems are engaged (validation, analysis, authorization, data loading, response type-checking, etc.).

A basic integration test might look like:

```ruby
it "loads posts by ID" do
  query_string = <<-GRAPHQL
    query($id: ID!){
      node(id: $id) {
        ... on Post {
          title
          id
          isDraft
          comments(first: 5) {
            nodes {
              body
            }
          }
        }
      }
    }
  GRAPHQL

  post = create(:post_with_comments, title: "My Cool Thoughts")
  post_id = MySchema.id_from_object(post, Types::Post, {})
  result = MySchema.execute(query_string, variables: { id: post_id })

  post_result = result["data"]["node"]
  # Make sure the query worked
  assert_equal post_id, post_result["id"]
  assert_equal "My Cool Thoughts", post_result["title"]
end
```

To make sure that different parts of the system are properly engaged, you can add integration tests for specific scenarios, too. For example, you could add a test to make sure that data is hidden from some users:


```ruby
it "doesn't show draft posts to anyone except their author" do
  author = create(:user)
  non_author = create(:non_user)
  draft_post = create(:post, draft: true, author: author)

  query_string = <<-GRAPHQL
  query($id: ID!) {
    node(id: $id) {
      ... on Post {
        isDraft
      }
    }
  }
  GRAPHQL

  post_id = MySchema.id_from_object(post, Types::Post, {})

  # Authors can see their drafts:
  author_result = MySchema.execute(query_string, context: { viewer: author }, variables: { id: post_id })
  assert_equal true, author_result["data"]["node"]["isDraft"]

  # Other users can't see others' drafts
  non_author_result = MySchema.execute(query_string, context: { viewer: non_author }, variables: { id: post_id })
  assert_nil author_result["data"]["node"]
end
```

This test engages the underlying authorization and business logic, and provides a sanity check at the GraphQL interface layer.

## Testing Transport-Level Behaviors

GraphQL is usually served over HTTP. You probably want tests that make sure that HTTP inputs are correctly prepared for GraphQL. For example, you might test that:

- POST data is correctly turned into query variables
- Authentication headers are used to load a `context[:viewer]`


In Rails, you might use a [functional test](https://guides.rubyonrails.org/testing.html#functional-tests-for-your-controllers) for this, for example:

```ruby
it "loads user token into the viewer" do
  query_string = "{ viewer { username } }"
  post graphql_path, params: { query: query_string }
  json_response = JSON.parse(@response.body)
  assert_nil json_response["data"]["viewer"], "Unauthenticated requests have no viewer"

  # This time, add some authentication to the HTTP request
  user = create(:user)
  post graphql_path,
    params: { query: query_string },
    headers: { "Authorization" => "Bearer #{user.auth_token}" }

  json_response = JSON.parse(@response.body)
  assert_equal user.username, json_response["data"]["viewer"]["username"], "Authenticated requests load the viewer"
end
```
