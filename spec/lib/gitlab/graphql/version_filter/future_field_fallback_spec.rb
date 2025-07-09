# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::VersionFilter::FutureFieldFallback, feature_category: :shared do
  # mock the super class behavior based on the field name for test purposes
  let_it_be(:test_parent_class) do
    Class.new do
      def self.get_field(field_name, _context = nil)
        case field_name
        when 'existing_field'
          Struct.new(:name).new('existing_field')
        when 'future_field'
          nil
        when '__introspection_field'
          nil
        end
      end

      def self.name
        'TestClass'
      end
    end
  end

  let_it_be(:test_class) do
    Class.new(test_parent_class) do
      include Gitlab::Graphql::VersionFilter::FutureFieldFallback
    end
  end

  describe '.get_field' do
    context 'when field exists in parent' do
      it 'returns the field from parent' do
        field = test_class.get_field('existing_field')

        expect(field).not_to be_nil
        expect(field.name).to eq('existing_field')
      end
    end

    context 'when context has contain_future_fields set to false' do
      let(:context) { { contain_future_fields: false } }

      it 'does not return fallback field' do
        field = test_class.get_field('future_field', context)

        expect(field).to be_nil
      end
    end

    context 'when field does not exist and context contains future fields' do
      let(:context) { { contain_future_fields: true } }

      it 'returns a fallback field for missing field' do
        field = test_class.get_field('future_field', context)

        expect(field).to be_a(GraphQL::Schema::Field)
        expect(field.name).to eq('futureField')
        expect(field.type).to eq(GraphQL::Types::Boolean)
        expect(field.instance_variable_get(:@fallback_value)).to be_nil
        expect(field.owner).to eq(test_class)
      end

      it 'does not return fallback for fields starting with double underscore' do
        field = test_class.get_field('__typename', context)

        expect(field).to be_nil
      end
    end
  end
end
