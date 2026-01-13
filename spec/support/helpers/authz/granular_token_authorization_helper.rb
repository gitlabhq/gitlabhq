# frozen_string_literal: true

module Authz
  module GranularTokenAuthorizationHelper
    def create_interface
      Module.new do
        include ::Types::BaseInterface

        field :interface_field, GraphQL::Types::String, null: true
      end
    end

    def create_base_field(type: GraphQL::Types::String, owner: Types::ProjectType)
      Types::BaseField.new(type: type, owner: owner, name: :test_field, null: true)
    end

    def create_field_with_directive(directive: nil, type: GraphQL::Types::String, owner: Types::ProjectType, **args)
      create_base_field(type:, owner:).tap do |field|
        directive ||= create_directive(**args)
        allow(field).to receive(:directives).and_return([directive])
      end
    end

    def create_directive(**args)
      return unless args

      instance_double(Directives::Authz::GranularScope, arguments: args).tap do |directive|
        allow(directive).to receive(:is_a?) { |klass| klass == Directives::Authz::GranularScope }
      end
    end
  end
end
