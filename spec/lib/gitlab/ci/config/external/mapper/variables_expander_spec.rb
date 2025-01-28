# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::External::Mapper::VariablesExpander, feature_category: :ci_variables do
  let_it_be(:variables) do
    Gitlab::Ci::Variables::Collection.new.tap do |variables|
      variables.append(key: 'VARIABLE1', value: 'hello')
    end
  end

  let_it_be(:context) do
    Gitlab::Ci::Config::External::Context.new(variables: variables)
  end

  subject(:variables_expander) { described_class.new(context) }

  describe '#process' do
    subject(:process) { variables_expander.process(locations) }

    context 'when locations are strings' do
      let(:locations) { ['$VARIABLE1.gitlab-ci.yml'] }

      it 'expands variables' do
        is_expected.to eq(['hello.gitlab-ci.yml'])
      end
    end

    context 'when locations are hashes' do
      let(:locations) { [{ local: '$VARIABLE1.gitlab-ci.yml' }] }

      it 'expands variables' do
        is_expected.to eq([{ local: 'hello.gitlab-ci.yml' }])
      end
    end

    context 'when locations are arrays' do
      let(:locations) { [{ local: ['$VARIABLE1.gitlab-ci.yml'] }] }

      it 'expands variables' do
        is_expected.to eq([{ local: ['hello.gitlab-ci.yml'] }])
      end
    end
  end
end
