# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../rubocop/node_pattern_helper'

RSpec.describe RuboCop::NodePatternHelper, feature_category: :tooling do
  include described_class

  describe '#const_pattern' do
    it 'returns nested const node patterns' do
      expect(const_pattern('Foo')).to eq('(const {nil? cbase} :Foo)')
      expect(const_pattern('Foo::Bar')).to eq('(const (const {nil? cbase} :Foo) :Bar)')
    end

    it 'returns nested const node patterns with custom parent' do
      expect(const_pattern('Foo::Bar', parent: 'nil?')).to eq('(const (const nil? :Foo) :Bar)')
    end
  end
end
