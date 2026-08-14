# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::External::Mapper::Filter, feature_category: :pipeline_composition do
  let_it_be(:variables) do
    Gitlab::Ci::Variables::Collection.new.tap do |variables|
      variables.append(key: 'VARIABLE1', value: 'hello')
    end
  end

  let(:context) do
    Gitlab::Ci::Config::External::Context.new(variables: variables)
  end

  subject(:filter) { described_class.new(context) }

  describe '#process' do
    let(:locations) do
      [
        { local: 'config/.gitlab-ci.yml', rules: [{ if: '$VARIABLE1' }] },
        { remote: 'https://testing.com/.gitlab-ci.yml', rules: [{ if: '$VARIABLE1', when: 'never' }] },
        { remote: 'https://example.com/.gitlab-ci.yml', rules: [{ if: '$VARIABLE2' }] }
      ]
    end

    subject(:process) { filter.process(locations) }

    it 'filters locations according to rules' do
      is_expected.to eq(
        [{ local: 'config/.gitlab-ci.yml', rules: [{ if: '$VARIABLE1' }] }]
      )
    end

    it 'does not mark the context when some locations survive' do
      process

      expect(context.any_includes_fully_filtered_by_rules?).to be false
    end

    context 'when all locations are filtered out' do
      let(:locations) do
        [
          { local: 'config/.gitlab-ci.yml', rules: [{ if: '$VARIABLE1', when: 'never' }] },
          { remote: 'https://example.com/.gitlab-ci.yml', rules: [{ if: '$VARIABLE2' }] }
        ]
      end

      it 'marks the context' do
        process

        expect(context.any_includes_fully_filtered_by_rules?).to be true
      end
    end

    context 'when no locations are filtered out' do
      let(:locations) do
        [{ local: 'config/.gitlab-ci.yml', rules: [{ if: '$VARIABLE1' }] }]
      end

      it 'does not mark the context' do
        process

        expect(context.any_includes_fully_filtered_by_rules?).to be false
      end
    end

    context 'when locations are empty' do
      let(:locations) { [] }

      it 'does not mark the context' do
        process

        expect(context.any_includes_fully_filtered_by_rules?).to be false
      end
    end
  end
end
