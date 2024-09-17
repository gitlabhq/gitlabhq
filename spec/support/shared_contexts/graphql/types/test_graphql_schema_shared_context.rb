# frozen_string_literal: true

RSpec.shared_context 'with test GraphQL schema' do
  let_it_be(:custom_auth) do
    Class.new(::Gitlab::Graphql::Authorize::ObjectAuthorization) do
      def any?
        true
      end

      def ok?(object, _current_user, scope_validator: nil, **_args)
        return false if object == { id: 100 }
        return false if object.try(:deactivated?)
        raise "Missing scope_validator" unless scope_validator

        true
      end
    end
  end

  let(:scope_validator) { instance_double(::Gitlab::Auth::ScopeValidator, valid_for?: true) }

  let_it_be(:test_schema) do
    auth = custom_auth.new(nil)

    base_object = Class.new(described_class) do
      # Override authorization so we don't need to mock Ability
      define_singleton_method :authorization do
        auth
      end
    end

    y_type = Class.new(base_object) do
      graphql_name 'Y'
      authorize :read_y
      field :id, Integer, null: false

      def id
        object[:id]
      end
    end

    number_type = Module.new do
      include ::Types::BaseInterface

      graphql_name 'Number'

      field :value, Integer, null: false
    end

    odd_type = Class.new(described_class) do
      graphql_name 'Odd'
      implements number_type

      authorize :read_odd
      field :odd_value, Integer, null: false

      def odd_value
        object[:value]
      end
    end

    even_type = Class.new(described_class) do
      graphql_name 'Even'
      implements number_type

      authorize :read_even
      field :even_value, Integer, null: false

      def even_value
        object[:value]
      end
    end

    # an abstract type, delegating authorization to members
    odd_or_even = Class.new(::Types::BaseUnion) do
      graphql_name 'OddOrEven'

      possible_types odd_type, even_type

      define_singleton_method :resolve_type do |object, _ctx|
        if object[:value].odd?
          odd_type
        else
          even_type
        end
      end
    end

    number_type.define_singleton_method :resolve_type do |object, ctx|
      odd_or_even.resolve_type(object, ctx)
    end

    x_type = Class.new(base_object) do
      graphql_name 'X'
      # Scalar types
      field :title, String, null: true
      # monomorphic types
      field :lazy_list_of_ys, [y_type], null: true
      field :list_of_lazy_ys, [y_type], null: true
      field :array_ys_conn, y_type.connection_type, null: true
      # polymorphic types
      field :polymorphic_conn, odd_or_even.connection_type, null: true
      field :polymorphic_object, odd_or_even, null: true do
        argument :value, Integer, required: true
      end
      field :interface_conn, number_type.connection_type, null: true

      def lazy_list_of_ys
        ::Gitlab::Graphql::Lazy.new { object[:ys] }
      end

      def list_of_lazy_ys
        object[:ys].map { |y| ::Gitlab::Graphql::Lazy.new { y } }
      end

      def array_ys_conn
        object[:ys].dup
      end

      def polymorphic_conn
        object[:values].dup
      end
      alias_method :interface_conn, :polymorphic_conn

      def polymorphic_object(value)
        value
      end
    end

    user_type = Class.new(base_object) do
      graphql_name 'User'
      authorize :read_user
      field 'name', String, null: true
    end

    Class.new(GraphQL::Schema) do
      lazy_resolve ::Gitlab::Graphql::Lazy, :force
      use ::Gitlab::Graphql::Pagination::Connections

      query(Class.new(::Types::BaseObject) do
        graphql_name 'Query'
        field :x, x_type, null: true
        field :users, user_type.connection_type, null: true

        def x
          ::Gitlab::Graphql::Lazy.new { context[:x] }
        end

        def users
          ::Gitlab::Graphql::Lazy.new { User.id_in(context[:user_ids]).order(id: :asc) }
        end
      end)

      def unauthorized_object(_err)
        nil
      end
    end
  end
end
