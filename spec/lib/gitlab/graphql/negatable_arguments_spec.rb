# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::NegatableArguments do
  let(:test_resolver) do
    Class.new(Resolvers::BaseResolver).tap do |klass|
      klass.extend described_class
      allow(klass).to receive(:name).and_return('Resolvers::TestResolver')
    end
  end

  describe '#negated' do
    it 'defines :not argument' do
      test_resolver.negated {}

      expect(test_resolver.arguments['not'].type.name).to eq "Types::TestResolverNegatedParamsType"
    end

    it 'defines any arguments passed as block' do
      test_resolver.negated do
        argument :foo, GraphQL::STRING_TYPE, required: false
      end

      expect(test_resolver.arguments['not'].type.arguments.keys).to match_array(['foo'])
    end

    it 'defines all arguments passed as block even if called multiple times' do
      test_resolver.negated do
        argument :foo, GraphQL::STRING_TYPE, required: false
      end
      test_resolver.negated do
        argument :bar, GraphQL::STRING_TYPE, required: false
      end

      expect(test_resolver.arguments['not'].type.arguments.keys).to match_array(%w[foo bar])
    end

    it 'allows to specify custom argument name' do
      test_resolver.negated(param_key: :negative) {}

      expect(test_resolver.arguments).to include('negative')
    end
  end
end
