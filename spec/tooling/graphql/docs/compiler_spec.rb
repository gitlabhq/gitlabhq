# frozen_string_literal: true

require 'spec_helper'

require_relative Rails.root.join('tooling/graphql/docs/compiler')

RSpec.describe Tooling::Graphql::Docs::Compiler, feature_category: :api do
  let_it_be(:mock_schema) do
    spec_scalar = Class.new(::Types::BaseScalar) do
      graphql_name 'Scalar'
      description 'A scalar.'
    end

    spec_input_object = Class.new(::Types::BaseInputObject) do
      graphql_name 'InputObject'
      description 'An input object.'

      argument :scalar_arg, GraphQL::Types::String, required: false,
        description: 'A scalar argument.', default_value: 'the default'
      argument :deprecated_arg, GraphQL::Types::String, required: false,
        description: 'A deprecated argument.',
        deprecated: { milestone: '1.0', reason: 'Use scalarArg instead' }
      argument :experimental_arg, GraphQL::Types::String, required: false,
        description: 'An experimental argument.',
        experiment: { milestone: '2.0' }
    end

    spec_enum = Class.new(::Types::BaseEnum) do
      graphql_name 'Enum'
      description 'An enum.'

      value 'PLAIN', 'A plain value.'
      value 'EXPERIMENTAL', 'An experimental value.', experiment: { milestone: '2.0' }
      value 'DEPRECATED', 'A deprecated value.', deprecated: { milestone: '1.0', reason: 'Use PLAIN instead' }
    end

    spec_directive = Class.new(GraphQL::Schema::Directive) do
      graphql_name 'Directive'
      description 'A directive.'
      repeatable true
      locations(:INLINE_FRAGMENT, :FIELD)

      argument :directive_arg, GraphQL::Types::String, required: false, description: 'A directive argument.'
    end

    spec_interface = Module.new do
      include ::Types::BaseInterface
      graphql_name 'ExampleInterface'
      description 'An interface.'

      field :id, GraphQL::Types::ID, null: true, description: 'ID.'
    end

    spec_object = Class.new(::Types::BaseObject) do
      graphql_name 'Object'
      description 'An object.'

      implements spec_interface

      field :scalar_field, GraphQL::Types::String, null: true, description: 'A scalar field.' do
        argument :filter, GraphQL::Types::String, required: false, description: 'A filter argument.'
      end
      field :deprecated_field, GraphQL::Types::String, null: true,
        description: 'A deprecated field.',
        deprecated: { milestone: '1.0', reason: 'Use scalarField instead' }
      field :experimental_field, GraphQL::Types::String, null: true,
        description: 'An experimental field.',
        experiment: { milestone: '2.0' }
    end

    spec_connection_with_extra = Class.new(spec_object.connection_type) do
      graphql_name 'ObjectWithExtraConnection'

      field :total, GraphQL::Types::Int, null: true, description: 'Total count.'
    end

    spec_object_without_description = Class.new(::Types::BaseObject) do
      graphql_name 'ObjectWithoutDescription'

      field :scalar_field, GraphQL::Types::String, null: true, description: 'A scalar field.'
    end

    # A second implementor of ExampleInterface, declared after Object so the
    # implementations list is sorted alphabetically (not by declaration order).
    spec_alpha_implementor = Class.new(::Types::BaseObject) do
      graphql_name 'AlphaImplementor'
      description 'Another implementor of the interface.'

      implements spec_interface

      field :id, GraphQL::Types::ID, null: true, description: 'ID.'
    end

    # An interface with a connection field, to prove the connection note links
    # across to the objects page from the interfaces page.
    spec_connection_interface = Module.new do
      include ::Types::BaseInterface
      graphql_name 'ConnectionInterface'
      description 'An interface with a connection field.'

      field :related, spec_object.connection_type, null: true, description: 'Related objects.'
    end

    spec_connection_interface_implementor = Class.new(::Types::BaseObject) do
      graphql_name 'ConnectionInterfaceImplementor'

      implements spec_connection_interface

      field :related, spec_object.connection_type, null: true, description: 'Related objects.'
    end

    # An interface with no description, to prove the section renders straight
    # from the heading to the implementations without a blank description line.
    spec_interface_without_description = Module.new do
      include ::Types::BaseInterface
      graphql_name 'InterfaceWithoutDescription'

      field :id, GraphQL::Types::ID, null: true, description: 'ID.'
    end

    spec_interface_without_description_implementor = Class.new(::Types::BaseObject) do
      graphql_name 'InterfaceWithoutDescriptionImplementor'

      implements spec_interface_without_description

      field :id, GraphQL::Types::ID, null: true, description: 'ID.'
    end

    # An interface that nothing implements, to prove the implementations section
    # is omitted when there are none.
    spec_interface_without_implementations = Module.new do
      include ::Types::BaseInterface
      graphql_name 'InterfaceWithoutImplementations'
      description 'An interface without implementations.'

      field :id, GraphQL::Types::ID, null: true, description: 'ID.'
    end

    # Members are declared out of alphabetical order to prove they are sorted.
    spec_union = Class.new(::Types::BaseUnion) do
      graphql_name 'Union'
      description 'A union.'

      possible_types spec_object_without_description, spec_object
    end

    spec_union_without_description = Class.new(::Types::BaseUnion) do
      graphql_name 'UnionWithoutDescription'

      possible_types spec_object
    end

    spec_union_without_members = Class.new(::Types::BaseUnion) do
      graphql_name 'UnionWithoutMembers'
      description 'A union without members.'
    end

    spec_object_with_union_field = Class.new(::Types::BaseObject) do
      graphql_name 'ObjectWithUnionField'

      field :union_field, spec_union, null: true, description: 'A union field.'
    end

    # Add a connection field to the object so field descriptions render the
    # connection note. Defined after the connection type exists.
    spec_object.field :related, spec_object.connection_type, null: true, description: 'Related objects.' do
      argument :search, GraphQL::Types::String, required: false, description: 'A search argument.'
    end

    spec_object_create = Class.new(::Mutations::BaseMutation) do
      graphql_name 'ObjectCreate'
      description 'Creates an object.'

      argument :name, GraphQL::Types::String, required: true, description: 'Name of the object.'
      argument :options, spec_input_object, required: false, description: 'Options for the object.'

      field :object, spec_object, null: true, description: 'Created object.'
      field :related, spec_object.connection_type, null: true, description: 'Related objects.'
    end

    spec_deprecated_mutation = Class.new(::Mutations::BaseMutation) do
      graphql_name 'DeprecatedMutation'
      description 'A deprecated mutation.'
    end

    spec_experimental_mutation = Class.new(::Mutations::BaseMutation) do
      graphql_name 'ExperimentalMutation'
      description 'An experimental mutation.'
    end

    spec_mutation_without_arguments = Class.new(::Mutations::BaseMutation) do
      graphql_name 'MutationWithoutArguments'
    end

    Class.new(GraphQL::Schema) do
      directive(spec_directive)

      orphan_types spec_alpha_implementor, spec_connection_interface_implementor,
        spec_interface_without_description_implementor

      query(Class.new(::Types::BaseObject) do
        graphql_name 'Query'

        field :scalar_field, spec_scalar
        field :enum_field, spec_enum
        field :object_field, spec_object
        field :object_without_description, spec_object_without_description
        field :objects, spec_object.connection_type, null: true, description: 'A connection.'
        field :objects_with_extra, spec_connection_with_extra, null: true,
          description: 'A connection with an extra field.'
        field :interfaces, spec_interface.connection_type, null: true,
          description: 'A connection over an interface node.'
        field :interface_without_implementations, spec_interface_without_implementations, null: true,
          description: 'A field returning an interface with no implementations.'
        field :object_with_union_field, spec_object_with_union_field, null: true
        field :unions, spec_union.connection_type, null: true, description: 'A connection over a union node.'
        field :union_without_description, spec_union_without_description, null: true
        field :union_without_members, spec_union_without_members, null: true
        field :input_field, spec_scalar do
          argument :input, spec_input_object, required: false, description: 'An input.'
        end
        field :find_object, spec_object, null: true, description: 'Find an object.' do
          argument :name, GraphQL::Types::String, required: true, description: 'Name of the object.'
        end
        field :searchable_objects, spec_object.connection_type, null: true, description: 'A searchable connection.' do
          argument :search, GraphQL::Types::String, required: false, description: 'A search argument.'
        end
        field :deprecated_query, GraphQL::Types::String, null: true,
          description: 'A deprecated query.',
          deprecated: { milestone: '1.0', reason: 'Use findObject instead' }
        field :experimental_query, GraphQL::Types::String, null: true,
          description: 'An experimental query.',
          experiment: { milestone: '2.0' }
        field :list_query, [GraphQL::Types::String], null: false, description: 'A list query.'
      end)

      mutation(Class.new(::Types::BaseObject) do
        graphql_name 'Mutation'

        field :object_create, mutation: spec_object_create
        field :deprecated_mutation, mutation: spec_deprecated_mutation,
          deprecated: { milestone: '1.0', reason: 'Use objectCreate instead' }
        field :experimental_mutation, mutation: spec_experimental_mutation,
          experiment: { milestone: '2.0' }
        field :mutation_without_arguments, mutation: spec_mutation_without_arguments
      end)
    end
  end

  subject(:pages) { described_class.new(schema: mock_schema).execute }

  def page(filename)
    pages.find { |compiled_doc| compiled_doc.filename.to_s.end_with?(filename) }
  end

  describe 'the mutations page' do
    subject(:doc) { page('mutations.md').doc }

    def section(name)
      doc[/^## `#{name}`\n.*?(?=\n## |\z)/m]
    end

    it 'renders a mutation with its description, input type, arguments, and fields' do
      expect(section('objectCreate')).to eq(
        <<~MD
          ## `objectCreate`

          Creates an object.

          **Input type:** `ObjectCreateInput`

          ### Arguments {.no_toc}

          | Name | Type | Description |
          | ---- | ---- | ----------- |
          | `name` | [`String!`](scalars.md#string) | Name of the object. |
          | `options` | [`InputObject`](input_objects.md#inputobject) | Options for the object. |

          ### Fields {.no_toc}

          | Name | Type | Description |
          | ---- | ---- | ----------- |
          | `errors` | [`[String!]!`](scalars.md#string) | Errors encountered during the mutation. |
          | `object` | [`Object`](objects.md#object) | Created object. |
          | `related` | [`ObjectConnection`](objects.md#objectconnection) | Related objects. This field is a [connection](objects.md#connections-and-pagination) and accepts the four standard pagination arguments: `before`, `after`, `first`, `last`. |
        MD
      )
    end

    it 'renders a mutation without a description or arguments' do
      expect(section('mutationWithoutArguments')).to eq(
        <<~MD
          ## `mutationWithoutArguments`

          **Input type:** `MutationWithoutArgumentsInput`

          ### Fields {.no_toc}

          | Name | Type | Description |
          | ---- | ---- | ----------- |
          | `errors` | [`[String!]!`](scalars.md#string) | Errors encountered during the mutation. |
        MD
      )
    end

    it 'omits clientMutationId from the arguments and fields of every mutation' do
      expect(doc).not_to match(/^\| `clientMutationId` \|/)
    end

    it 'renders the deprecation and experiment status of a mutation', :aggregate_failures do
      expect(section('deprecatedMutation')).to include('Deprecated in GitLab 1.0. Use objectCreate instead.')
      expect(section('experimentalMutation'))
        .to include("Status: Experiment. Introduced in GitLab 2.0.\n\nAn experimental mutation.")
    end

    it 'lists mutations in alphabetical order' do
      expect(doc.scan(/^## `(\w+)`/).flatten)
        .to eq(%w[deprecatedMutation experimentalMutation mutationWithoutArguments objectCreate])
    end

    it 'explains how to call a mutation, and clientMutationId, before the mutations', :aggregate_failures do
      first_mutation = doc.index('## `deprecatedMutation`')

      expect(doc.index("## Calling a mutation\n")).to be < first_mutation
      expect(doc.index("### `clientMutationId` {.no_toc}\n")).to be < first_mutation
    end

    it 'shows the deprecation warning before the first section' do
      expect(doc.index('WARNING:')).to be < doc.index("## Calling a mutation\n")
    end

    it 'does not include introspection types' do
      expect(doc).not_to include('__')
    end
  end

  describe 'the queries page' do
    subject(:doc) { page('queries.md').doc }

    def section(name)
      doc[/^## `#{name}`\n.*?(?=\n## |\z)/m]
    end

    it 'renders a query with its description, return type, and arguments' do
      expect(doc).to include(
        <<~MD
          ## `findObject`

          Find an object.

          **Returns:** [`Object`](objects.md#object)

          ### Arguments {.no_toc}

          | Name | Type | Description |
          | ---- | ---- | ----------- |
          | `name` | [`String!`](scalars.md#string) | Name of the object. |
        MD
      )
    end

    it 'renders a query without a description' do
      expect(section('scalarField')).to eq(
        <<~MD
          ## `scalarField`

          **Returns:** [`Scalar`](scalars.md#scalar)
        MD
      )
    end

    it 'links the connection note of a connection query across to the objects page' do
      expect(section('objects')).to include(
        'A connection. This field is a [connection](objects.md#connections-and-pagination) and accepts the ' \
          'four standard pagination arguments: `before`, `after`, `first`, `last`.'
      )
    end

    it 'omits the arguments section for a connection query with only pagination arguments' do
      expect(section('objects')).not_to include('### Arguments')
    end

    it 'lists only the non-pagination arguments of a connection query' do
      expect(section('searchableObjects').scan(/^\| `(\w+)` \|/).flatten).to eq(%w[search])
    end

    it 'renders the deprecation and experiment status of a query', :aggregate_failures do
      expect(section('deprecatedQuery')).to include('Deprecated in GitLab 1.0. Use findObject instead.')
      expect(section('experimentalQuery'))
        .to include("Status: Experiment. Introduced in GitLab 2.0.\n\nAn experimental query.")
    end

    it 'renders the full type signature of the return type' do
      expect(section('listQuery')).to include('**Returns:** [`[String!]!`](scalars.md#string)')
    end

    it 'lists queries in alphabetical order' do
      expect(doc.scan(/^## `(\w+)`/).flatten).to eq(doc.scan(/^## `(\w+)`/).flatten.sort)
    end

    it 'does not include introspection types' do
      expect(doc).not_to include('__')
    end
  end

  describe 'the objects page' do
    subject(:doc) { page('objects.md').doc }

    it 'renders the object with its fields, type links, and deprecation/experiment status' do
      expect(doc).to include(
        <<~MD
          ## `Object`

          An object.

          **Implements:** [`ExampleInterface`](interfaces.md#exampleinterface)

          ### Fields {.no_toc}

          | Name | Type | Description |
          | ---- | ---- | ----------- |
          | `deprecatedField` | [`String`](scalars.md#string) | Deprecated in GitLab 1.0. Use scalarField instead. |
          | `experimentalField` | [`String`](scalars.md#string) | Status: Experiment. Introduced in GitLab 2.0.<br/><br/>An experimental field. |
          | `id` | [`ID`](scalars.md#id) | ID. |
        MD
      )
    end

    it 'appends the connection note and non-pagination arguments to a connection field description' do
      expect(doc).to include(
        '| `related` | [`ObjectConnection`](#objectconnection) | Related objects. ' \
          'This field is a [connection](#connections-and-pagination) and accepts the ' \
          'four standard pagination arguments: `before`, `after`, `first`, `last`. ' \
          '<br><br> <strong>Arguments for `related`:</strong> ' \
          '<dl><dt>`search` ([`String`](scalars.md#string))</dt><dd>A search argument.</dd></dl> |'
      )
    end

    it 'omits the pagination arguments from a connection field arguments block' do
      section = doc[/## `Object`.*?(?=\n## )/m]
      related_row = section[/^\| `related` \|.*$/]

      expect(related_row).to include('Arguments for `related`')
      expect(related_row).not_to match(/<dt>`(before|after|first|last)`/)
    end

    it 'renders a scalar field with its arguments' do
      expect(doc).to include(
        '| `scalarField` | [`String`](scalars.md#string) | A scalar field. ' \
          '<br><br> <strong>Arguments for `scalarField`:</strong> ' \
          '<dl><dt>`filter` ([`String`](scalars.md#string))</dt><dd>A filter argument.</dd></dl> |'
      )
    end

    it 'lists fields in alphabetical order' do
      section = doc[/## `Object`.*?(?=\n## )/m]

      expect(section.scan(/^\| `(\w+)` \|/).flatten).to eq(%w[deprecatedField experimentalField id related scalarField])
    end

    it 'renders a connection object with a summary linking to its node type' do
      expect(doc).to include(
        <<~MD
          ## `ObjectConnection`

          Paginated collection of [`Object`](#object). See [Standard connection fields](#standard-connection-fields) for the fields available on every connection.
        MD
      )
    end

    it 'renders a connection with extra fields beyond the standard set' do
      section = doc[/## `ObjectWithExtraConnection`.*?(?=\n## )/m]

      expect(section).to include('### Extra fields {.no_toc}')
      expect(section).to include('| `total` | [`Int`](scalars.md#int) | Total count. |')
    end

    it 'renders an object without a description' do
      expect(doc).to include(
        <<~MD
          ## `ObjectWithoutDescription`

          ### Fields {.no_toc}
        MD
      )
    end

    it 'renders a connection over an interface node linking to the interfaces page' do
      expect(doc).to include(
        <<~MD
          ## `ExampleInterfaceConnection`

          Paginated collection of [`ExampleInterface`](interfaces.md#exampleinterface). See [Standard connection fields](#standard-connection-fields) for the fields available on every connection.
        MD
      )
    end

    it 'renders a connection over a union node linking to the unions page' do
      expect(doc).to include(
        <<~MD
          ## `UnionConnection`

          Paginated collection of [`Union`](unions.md#union). See [Standard connection fields](#standard-connection-fields) for the fields available on every connection.
        MD
      )
    end

    it 'links a union-typed field to the unions page' do
      expect(doc).to include('| `unionField` | [`Union`](unions.md#union) | A union field. |')
    end

    it 'does not include introspection types' do
      expect(doc).not_to include('__')
    end

    it 'excludes mutation payload types' do
      expect(doc).not_to include('## `ObjectCreatePayload`')
    end

    it 'includes the connections section' do
      expect(doc).to include('## Connections and pagination')
    end
  end

  describe 'the scalars page' do
    subject(:doc) { page('scalars.md').doc }

    it 'renders a heading and description for each scalar' do
      expect(doc).to include(
        <<~MD
          ## `Scalar`

          A scalar.
        MD
      )
    end

    it 'does not include introspection types' do
      expect(doc).not_to include('__')
    end
  end

  describe 'the interfaces page' do
    subject(:doc) { page('interfaces.md').doc }

    it 'renders the interface with its implementations and fields' do
      expect(doc).to include(
        <<~MD
          ## `ExampleInterface`

          An interface.

          ### Implementations {.no_toc}

          - [`AlphaImplementor`](objects.md#alphaimplementor)
          - [`Object`](objects.md#object)

          ### Fields {.no_toc}

          | Name | Type | Description |
          | ---- | ---- | ----------- |
          | `id` | [`ID`](scalars.md#id) | ID. |
        MD
      )
    end

    it 'lists implementations in alphabetical order' do
      section = doc[/## `ExampleInterface`.*?(?=\n## |\z)/m]

      expect(section.scan(/^- \[`(\w+)`\]/).flatten).to eq(%w[AlphaImplementor Object])
    end

    it 'renders an interface without a description' do
      expect(doc).to include(
        <<~MD
          ## `InterfaceWithoutDescription`

          ### Implementations {.no_toc}
        MD
      )
    end

    it 'omits the implementations section for an interface without implementations' do
      expect(doc).to include(
        <<~MD
          ## `InterfaceWithoutImplementations`

          An interface without implementations.

          ### Fields {.no_toc}
        MD
      )
    end

    it 'links a connection field note across to the objects page' do
      section = doc[/## `ConnectionInterface`.*?(?=\n## )/m]

      expect(section).to include('[connection](objects.md#connections-and-pagination)')
    end

    it 'lists interfaces in alphabetical order' do
      expect(doc.scan(/^## `(\w+)`/).flatten).to eq(doc.scan(/^## `(\w+)`/).flatten.sort)
    end

    it 'does not include introspection types' do
      expect(doc).not_to include('__')
    end
  end

  describe 'the unions page' do
    subject(:doc) { page('unions.md').doc }

    it 'renders the union with its linked member types' do
      expect(doc).to include(
        <<~MD
          ## `Union`

          A union.

          ### Member types {.no_toc}

          - [`Object`](objects.md#object)
          - [`ObjectWithoutDescription`](objects.md#objectwithoutdescription)
        MD
      )
    end

    it 'lists member types in alphabetical order' do
      section = doc[/## `Union`\n.*?(?=\n## |\z)/m]

      expect(section.scan(/^- \[`(\w+)`\]/).flatten).to eq(%w[Object ObjectWithoutDescription])
    end

    it 'renders a union without a description' do
      expect(doc).to include(
        <<~MD
          ## `UnionWithoutDescription`

          ### Member types {.no_toc}
        MD
      )
    end

    it 'omits the member types section for a union without members' do
      section = doc[/## `UnionWithoutMembers`\n.*?(?=\n## |\z)/m]

      expect(section).to include('A union without members.')
      expect(section).not_to include('### Member types')
    end

    it 'lists unions in alphabetical order' do
      expect(doc.scan(/^## `(\w+)`/).flatten).to eq(%w[Union UnionWithoutDescription UnionWithoutMembers])
    end

    it 'does not include introspection types' do
      expect(doc).not_to include('__')
    end
  end

  describe 'the input_objects page' do
    subject(:doc) { page('input_objects.md').doc }

    it 'renders the input object with its arguments, type links, defaults, and deprecation/experiment status' do
      expect(doc).to include(
        <<~MD
          ## `InputObject`

          An input object.

          ### Arguments {.no_toc}

          | Name | Type | Description | Default |
          | ---- | ---- | ----------- | ------- |
          | `deprecatedArg` | [`String`](scalars.md#string) | Deprecated in GitLab 1.0. Use scalarArg instead. |  |
          | `experimentalArg` | [`String`](scalars.md#string) | Status: Experiment. Introduced in GitLab 2.0.<br/><br/>An experimental argument. |  |
          | `scalarArg` | [`String`](scalars.md#string) | A scalar argument. | `"the default"` |
        MD
      )
    end

    it 'excludes mutation input objects' do
      expect(doc.scan(/^## `(\w+)`/).flatten).to eq(%w[InputObject])
    end

    it 'lists arguments in alphabetical order' do
      expect(doc.scan(/^\| `(\w+)` \|/).flatten).to eq(%w[deprecatedArg experimentalArg scalarArg])
    end

    it 'does not include introspection types' do
      expect(doc).not_to include('__')
    end
  end

  describe 'the directives page' do
    subject(:doc) { page('directives.md').doc }

    it 'renders the directive with its locations, repeatable note, and arguments' do
      expect(doc).to include(
        <<~MD
          ## `Directive`

          A directive.

          ### Locations {.no_toc}

          - `FIELD`
          - `INLINE_FRAGMENT`

          This is a repeatable directive and can be used with different arguments at the same location.

          ### Arguments {.no_toc}

          | Name | Type | Description |
          | ---- | ---- | ----------- |
          | `directiveArg` | [`String`](scalars.md#string) | A directive argument. |
        MD
      )
    end

    it 'lists directives in alphabetical order' do
      expect(doc.scan(/^## `(\w+)`/).flatten).to eq(doc.scan(/^## `(\w+)`/).flatten.sort)
    end
  end

  describe 'the enums page' do
    subject(:doc) { page('enums.md').doc }

    it 'renders a heading and values table for the enum' do
      expect(doc).to include(
        <<~MD
          ## `Enum`

          An enum.

          | Value | Description |
          | ----- | ----------- |
          | `DEPRECATED` | Deprecated in GitLab 1.0. Use PLAIN instead. |
          | `EXPERIMENTAL` | Status: Experiment. Introduced in GitLab 2.0.<br/><br/>An experimental value. |
          | `PLAIN` | A plain value. |
        MD
      )
    end

    it 'lists values in alphabetical order' do
      expect(doc.scan(/^\| `(\w+)` \|/).flatten).to eq(%w[DEPRECATED EXPERIMENTAL PLAIN])
    end
  end
end
