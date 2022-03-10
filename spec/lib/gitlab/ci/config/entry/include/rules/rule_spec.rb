# frozen_string_literal: true

require 'fast_spec_helper'
require_dependency 'active_model'

RSpec.describe Gitlab::Ci::Config::Entry::Include::Rules::Rule do
  let(:factory) do
    Gitlab::Config::Entry::Factory.new(described_class)
                                  .value(config)
  end

  subject(:entry) { factory.create! }

  describe '.new' do
    shared_examples 'an invalid config' do |error_message|
      it { is_expected.not_to be_valid }

      it 'has errors' do
        expect(entry.errors).to include(error_message)
      end
    end

    context 'when specifying an if: clause' do
      let(:config) { { if: '$THIS || $THAT' } }

      it { is_expected.to be_valid }
    end

    context 'when specifying an exists: clause' do
      let(:config) { { exists: './this.md' } }

      it { is_expected.to be_valid }
    end

    context 'using a list of multiple expressions' do
      let(:config) { { if: ['$MY_VAR == "this"', '$YOUR_VAR == "that"'] } }

      it_behaves_like 'an invalid config', /invalid expression syntax/
    end

    context 'when specifying an invalid if: clause expression' do
      let(:config) { { if: ['$MY_VAR =='] } }

      it_behaves_like 'an invalid config', /invalid expression syntax/
    end

    context 'when specifying an if: clause expression with an invalid token' do
      let(:config) { { if: ['$MY_VAR == 123'] } }

      it_behaves_like 'an invalid config', /invalid expression syntax/
    end

    context 'when using invalid regex in an if: clause' do
      let(:config) { { if: ['$MY_VAR =~ /some ( thing/'] } }

      it_behaves_like 'an invalid config', /invalid expression syntax/
    end

    context 'when using an if: clause with lookahead regex character "?"' do
      let(:config) { { if: '$CI_COMMIT_REF =~ /^(?!master).+/' } }

      it_behaves_like 'an invalid config', /invalid expression syntax/
    end

    context 'when specifying unknown policy' do
      let(:config) { { invalid: :something } }

      it_behaves_like 'an invalid config', /unknown keys: invalid/
    end

    context 'when clause is empty' do
      let(:config) { {} }

      it_behaves_like 'an invalid config', /can't be blank/
    end

    context 'when policy strategy does not match' do
      let(:config) { 'string strategy' }

      it_behaves_like 'an invalid config', /should be a hash/
    end
  end

  describe '#value' do
    subject(:value) { entry.value }

    context 'when specifying an if: clause' do
      let(:config) { { if: '$THIS || $THAT' } }

      it 'returns the config' do
        expect(subject).to eq(if: '$THIS || $THAT')
      end
    end

    context 'when specifying an exists: clause' do
      let(:config) { { exists: './test.md' } }

      it 'returns the config' do
        expect(subject).to eq(exists: './test.md')
      end
    end
  end
end
