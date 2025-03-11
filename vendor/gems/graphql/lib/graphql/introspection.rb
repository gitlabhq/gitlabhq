# frozen_string_literal: true
module GraphQL
  module Introspection
    def self.query(include_deprecated_args: false, include_schema_description: false, include_is_repeatable: false, include_specified_by_url: false, include_is_one_of: false)
      # The introspection query to end all introspection queries, copied from
      # https://github.com/graphql/graphql-js/blob/master/src/utilities/introspectionQuery.js
      <<-QUERY.gsub(/\n{2,}/, "\n")
query IntrospectionQuery {
  __schema {
    #{include_schema_description ? "description" : ""}
    queryType { name }
    mutationType { name }
    subscriptionType { name }
    types {
      ...FullType
    }
    directives {
      name
      description
      locations
      #{include_is_repeatable ? "isRepeatable" : ""}
      args#{include_deprecated_args ? '(includeDeprecated: true)' : ''} {
        ...InputValue
      }
    }
  }
}
fragment FullType on __Type {
  kind
  name
  description
  #{include_specified_by_url ? "specifiedByURL" : ""}
  #{include_is_one_of ? "isOneOf" : ""}
  fields(includeDeprecated: true) {
    name
    description
    args#{include_deprecated_args ? '(includeDeprecated: true)' : ''} {
      ...InputValue
    }
    type {
      ...TypeRef
    }
    isDeprecated
    deprecationReason
  }
  inputFields#{include_deprecated_args ? '(includeDeprecated: true)' : ''} {
    ...InputValue
  }
  interfaces {
    ...TypeRef
  }
  enumValues(includeDeprecated: true) {
    name
    description
    isDeprecated
    deprecationReason
  }
  possibleTypes {
    ...TypeRef
  }
}
fragment InputValue on __InputValue {
  name
  description
  type { ...TypeRef }
  defaultValue
  #{include_deprecated_args ? 'isDeprecated' : ''}
  #{include_deprecated_args ? 'deprecationReason' : ''}
}
fragment TypeRef on __Type {
  kind
  name
  ofType {
    kind
    name
    ofType {
      kind
      name
      ofType {
        kind
        name
        ofType {
          kind
          name
          ofType {
            kind
            name
            ofType {
              kind
              name
              ofType {
                kind
                name
              }
            }
          }
        }
      }
    }
  }
}
      QUERY
    end
  end
end

require "graphql/introspection/base_object"
require "graphql/introspection/input_value_type"
require "graphql/introspection/enum_value_type"
require "graphql/introspection/type_kind_enum"
require "graphql/introspection/type_type"
require "graphql/introspection/field_type"
require "graphql/introspection/directive_location_enum"
require "graphql/introspection/directive_type"
require "graphql/introspection/schema_type"
require "graphql/introspection/introspection_query"
require "graphql/introspection/dynamic_fields"
require "graphql/introspection/entry_points"
