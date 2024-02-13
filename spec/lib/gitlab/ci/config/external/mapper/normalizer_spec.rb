# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::External::Mapper::Normalizer, feature_category: :pipeline_composition do
  let_it_be(:variables) do
    Gitlab::Ci::Variables::Collection.new.tap do |variables|
      variables.append(key: 'VARIABLE1', value: 'config')
      variables.append(key: 'VARIABLE2', value: 'https://example.com')
    end
  end

  let_it_be(:context) do
    Gitlab::Ci::Config::External::Context.new(variables: variables)
  end

  subject(:normalizer) { described_class.new(context) }

  describe '#process' do
    let(:locations) do
      ['https://example.com/.gitlab-ci.yml',
       'config/.gitlab-ci.yml',
       { local: 'config/.gitlab-ci.yml' },
       { remote: 'https://example.com/.gitlab-ci.yml' },
       { template: 'Template.gitlab-ci.yml' },
       '$VARIABLE1/.gitlab-ci.yml',
       '$VARIABLE2/.gitlab-ci.yml']
    end

    subject(:process) { normalizer.process(locations) }

    it 'converts locations to canonical form' do
      is_expected.to eq(
        [{ remote: 'https://example.com/.gitlab-ci.yml' },
         { local: 'config/.gitlab-ci.yml' },
         { local: 'config/.gitlab-ci.yml' },
         { remote: 'https://example.com/.gitlab-ci.yml' },
         { template: 'Template.gitlab-ci.yml' },
         { local: 'config/.gitlab-ci.yml' },
         { remote: 'https://example.com/.gitlab-ci.yml' }]
      )
    end

    context 'when the location value is an invalid type' do
      let(:locations) { [123] }

      it 'raises an error' do
        expect { process }.to raise_error(
          Gitlab::Ci::Config::External::Mapper::InvalidTypeError, /Each include must be a hash or a string/)
      end
    end
  end
end
