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

    Class.new(GraphQL::Schema) do
      directive(spec_directive)

      query(Class.new(::Types::BaseObject) do
        graphql_name 'Query'

        field :scalar_field, spec_scalar
        field :enum_field, spec_enum
        field :input_field, spec_scalar do
          argument :input, spec_input_object, required: false, description: 'An input.'
        end
      end)
    end
  end

  subject(:pages) { described_class.new(schema: mock_schema).execute }

  def page(filename)
    pages.find { |compiled_doc| compiled_doc.filename.to_s.end_with?(filename) }
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
