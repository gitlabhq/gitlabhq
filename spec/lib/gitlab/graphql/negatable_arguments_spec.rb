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
        argument :foo, GraphQL::Types::String, required: false
      end

      expect(test_resolver.arguments['not'].type.arguments.keys).to match_array(['foo'])
    end

    # TODO: suffers from the `DuplicateNamesError` error. skip until we upgrade
    # to the graphql 2.0 gem https://gitlab.com/gitlab-org/gitlab/-/issues/363131
    xit 'defines all arguments passed as block even if called multiple times' do
      test_resolver.negated do
        argument :foo, GraphQL::Types::String, required: false
      end
      test_resolver.negated do
        argument :bar, GraphQL::Types::String, required: false
      end

      expect(test_resolver.arguments['not'].type.arguments.keys).to match_array(%w[foo bar])
    end

    it 'allows to specify custom argument name' do
      test_resolver.negated(param_key: :negative) {}

      expect(test_resolver.arguments).to include('negative')
    end
  end
end
