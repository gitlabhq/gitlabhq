# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Ci::Config::Entry::Include, feature_category: :pipeline_composition do
  subject(:include_entry) { described_class.new(config) }

  # Test all common include validations shared with Header::Include
  it_behaves_like 'basic include validations'
  it_behaves_like 'integrity validation for includes'

  describe 'Entry::Include specific validations' do
    before do
      include_entry.compose!
    end

    context 'when using "template"' do
      let(:config) { { template: 'test.yml' } }

      it { is_expected.to be_valid }
    end

    context 'when using "component"' do
      let(:config) { { component: 'path/to/component@1.0' } }

      it { is_expected.to be_valid }
    end

    context 'when using "project" with "ref"' do
      let(:config) { { project: 'my-group/my-pipeline-library', ref: 'master', file: 'test.yml' } }

      it { is_expected.to be_valid }
    end

    context 'when using "artifact"' do
      context 'and specifying "job"' do
        let(:config) { { artifact: 'test.yml', job: 'generator' } }

        it { is_expected.to be_valid }
      end

      context 'without "job"' do
        let(:config) { { artifact: 'test.yml' } }

        it { is_expected.not_to be_valid }

        it 'has specific error' do
          expect(include_entry.errors)
            .to include('include config must specify the job where to fetch the artifact from')
        end
      end
    end

    context 'when using with "rules"' do
      let(:config) { { local: 'test.yml', rules: [{ if: '$VARIABLE' }] } }

      it { is_expected.to be_valid }

      context 'when also using "inputs"' do
        let(:config) { { local: 'test.yml', inputs: { stage: 'test' }, rules: [{ if: '$VARIABLE' }] } }

        it { is_expected.to be_valid }
      end

      context 'when rules is not an array of hashes' do
        let(:config) { { local: 'test.yml', rules: ['$VARIABLE'] } }

        it { is_expected.not_to be_valid }

        it 'has specific error' do
          expect(include_entry.errors).to include('include rules should be an array of hashes')
        end
      end
    end
  end

  describe '#value' do
    subject(:value) { include_entry.value }

    context 'when config is a string' do
      let(:config) { 'test.yml' }

      it { is_expected.to eq('test.yml') }
    end

    context 'when config is a hash' do
      let(:config) { { local: 'test.yml' } }

      it { is_expected.to eq(local: 'test.yml') }
    end

    context 'when config has "rules"' do
      let(:config) { { local: 'test.yml', rules: [{ if: '$VARIABLE' }] } }

      it { is_expected.to eq(local: 'test.yml', rules: [{ if: '$VARIABLE' }]) }
    end
  end
end
