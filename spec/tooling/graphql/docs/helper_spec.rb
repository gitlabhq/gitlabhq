# frozen_string_literal: true

require 'spec_helper'

require Rails.root.join('tooling/graphql/docs/helper')
require Rails.root.join('tooling/graphql/docs/schema/enum')
require Rails.root.join('tooling/graphql/docs/schema/scalar')
require Rails.root.join('tooling/graphql/docs/schema/temp_undocumented')

RSpec.describe Tooling::Graphql::Docs::Helper, feature_category: :api do
  let(:helper) do
    Class.new do
      include Tooling::Graphql::Docs::Helper
    end.new
  end

  let_it_be(:mock_enum) do
    Class.new(Types::BaseEnum) do
      graphql_name 'MockEnum'

      value 'PLAIN', 'A plain value.'
      value 'EXPERIMENTAL', 'An experimental value.', experiment: { milestone: '16.0' }
      value 'DEPRECATED', 'A deprecated value.', deprecated: { milestone: '16.0', reason: 'Deprecated' }
    end
  end

  let(:enum_values) { mock_enum.enum_values }

  def value(name)
    Tooling::Graphql::Docs::Schema::EnumValue.new(
      enum_values.find { |enum_value| enum_value.graphql_name == name }
    )
  end

  describe '#name' do
    it 'returns the name in backticks' do
      expect(helper.name(value('PLAIN'))).to eq('`PLAIN`')
    end
  end

  describe '#sorted_by_name' do
    it 'sorts a collection by name' do
      sorted = helper.sorted_by_name([value('PLAIN'), value('DEPRECATED'), value('EXPERIMENTAL')])

      expect(sorted.map(&:name)).to eq(%w[DEPRECATED EXPERIMENTAL PLAIN])
    end
  end

  describe '#type' do
    let(:fake_graphql_type) { Struct.new(:graphql_name, :description) }
    let(:item_struct) { Struct.new(:type, :type_signature) }

    it 'returns a linked type signature for a known type' do
      scalar = Tooling::Graphql::Docs::Schema::Scalar.new(fake_graphql_type.new('String', nil))
      item = item_struct.new(scalar, 'String')

      expect(helper.type(item)).to eq('[`String`](scalars.md#string)')
    end

    it 'returns an unlinked type signature for a TempUndocumented type' do
      temp = Tooling::Graphql::Docs::Schema::TempUndocumented.new(fake_graphql_type.new('SomeObject', nil))
      item = item_struct.new(temp, 'SomeObject')

      expect(helper.type(item)).to eq('`SomeObject`')
    end
  end

  describe '#description' do
    it 'renders a plain description' do
      expect(helper.description(value('PLAIN'))).to eq('A plain value.')
    end

    it 'renders the experiment status and milestone for experimental items' do
      expect(helper.description(value('EXPERIMENTAL')))
        .to start_with('Status: Experiment. Introduced in GitLab 16.0.')
    end

    it 'renders the deprecation milestone for deprecated items' do
      expect(helper.description(value('DEPRECATED')))
        .to start_with('Deprecated in GitLab 16.0.')
    end
  end
end
