# frozen_string_literal: true

# This query is used by graphql-client so don't add the includeDeprecated
# argument for inputFields since the server may not support it. Two stage
# introspection queries will be required to handle this in clients.
GraphQL::Introspection::INTROSPECTION_QUERY = GraphQL::Introspection.query

