# frozen_string_literal: true
require 'graphql/schema/member/base_dsl_methods'
require 'graphql/schema/member/graphql_type_names'
require 'graphql/schema/member/has_ast_node'
require 'graphql/schema/member/has_dataloader'
require 'graphql/schema/member/has_directives'
require 'graphql/schema/member/has_deprecation_reason'
require 'graphql/schema/member/has_interfaces'
require 'graphql/schema/member/has_path'
require 'graphql/schema/member/has_unresolved_type_error'
require 'graphql/schema/member/has_validators'
require 'graphql/schema/member/relay_shortcuts'
require 'graphql/schema/member/scoped'
require 'graphql/schema/member/type_system_helpers'
require 'graphql/schema/member/validates_input'

module GraphQL
  class Schema
    # The base class for things that make up the schema,
    # eg objects, enums, scalars.
    #
    # @api private
    class Member
      include GraphQLTypeNames
      extend BaseDSLMethods
      extend BaseDSLMethods::ConfigurationExtension
      introspection(false)
      extend TypeSystemHelpers
      extend Scoped
      extend RelayShortcuts
      extend HasPath
      extend HasAstNode
      extend HasDirectives
    end
  end
end

require 'graphql/schema/member/has_arguments'
require 'graphql/schema/member/has_fields'
require 'graphql/schema/member/build_type'
