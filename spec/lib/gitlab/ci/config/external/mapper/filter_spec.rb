# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::External::Mapper::Filter, feature_category: :pipeline_composition do
  let_it_be(:variables) do
    Gitlab::Ci::Variables::Collection.new.tap do |variables|
      variables.append(key: 'VARIABLE1', value: 'hello')
    end
  end

  let_it_be(:context) do
    Gitlab::Ci::Config::External::Context.new(variables: variables)
  end

  subject(:filter) { described_class.new(context) }

  describe '#process' do
    let(:locations) do
      [{ local: 'config/.gitlab-ci.yml', rules: [{ if: '$VARIABLE1' }] },
       { remote: 'https://testing.com/.gitlab-ci.yml', rules: [{ if: '$VARIABLE1', when: 'never' }] },
       { remote: 'https://example.com/.gitlab-ci.yml', rules: [{ if: '$VARIABLE2' }] }]
    end

    subject(:process) { filter.process(locations) }

    it 'filters locations according to rules' do
      is_expected.to eq(
        [{ local: 'config/.gitlab-ci.yml', rules: [{ if: '$VARIABLE1' }] }]
      )
    end

    context 'when FF `ci_support_include_rules_when_never` is disabled' do
      before do
        stub_feature_flags(ci_support_include_rules_when_never: false)
      end

      it 'filters locations according to rules ignoring when:' do
        is_expected.to eq(
          [{ local: 'config/.gitlab-ci.yml', rules: [{ if: '$VARIABLE1' }] },
           { remote: 'https://testing.com/.gitlab-ci.yml', rules: [{ if: '$VARIABLE1', when: 'never' }] }]
        )
      end
    end
  end
end
