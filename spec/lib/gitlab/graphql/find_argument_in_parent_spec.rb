# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Graphql::FindArgumentInParent do
  describe '#find' do
    def build_node(parent = nil, args: {})
      props = { irep_node: double(arguments: args) }
      props[:parent] = parent if parent # The root node shouldn't respond to parent

      double(props)
    end

    let(:parent) do
      build_node(
        build_node(
          build_node(
            build_node,
            args: { myArg: 1 }
          )
        )
      )
    end
    let(:arg_name) { :my_arg }

    it 'searches parents and returns the argument' do
      expect(described_class.find(parent, :my_arg)).to eq(1)
    end

    it 'can find argument when passed in as both Ruby and GraphQL-formatted symbols and strings' do
      [:my_arg, :myArg, 'my_arg', 'myArg'].each do |arg|
        expect(described_class.find(parent, arg)).to eq(1)
      end
    end

    it 'returns nil if no arguments found in parents' do
      expect(described_class.find(parent, :bar)).to eq(nil)
    end

    it 'can limit the depth it searches to' do
      expect(described_class.find(parent, :my_arg, limit_depth: 1)).to eq(nil)
    end
  end
end
