# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::CopyFieldDescription do
  subject { Class.new.include(described_class) }

  describe '.copy_field_description' do
    let(:type) do
      Class.new(Types::BaseObject) do
        graphql_name "TestType"

        field :field_name, GraphQL::Types::String, null: true, description: 'Foo.'
        field :deprecated_field_name, GraphQL::Types::String, null: true, description: 'Bar.',
          deprecated: { reason: 'My reason', milestone: '16.7' }
        field :experimental_field_name, GraphQL::Types::String, null: true, description: 'Baz.',
          experiment: { milestone: '16.7' }
      end
    end

    it 'returns the field description' do
      expect(subject.copy_field_description(type, :field_name)).to eq('Foo.')
    end

    it 'returns the original description when the field is deprecated' do
      expect(subject.copy_field_description(type, :deprecated_field_name)).to eq('Bar.')
    end

    it 'returns the original description when the field is experimental' do
      expect(subject.copy_field_description(type, :experimental_field_name)).to eq('Baz.')
    end
  end
end
