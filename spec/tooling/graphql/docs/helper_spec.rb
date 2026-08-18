# frozen_string_literal: true

require 'spec_helper'

require Rails.root.join('tooling/graphql/docs/helper')
require Rails.root.join('tooling/graphql/docs/schema/enum')

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
