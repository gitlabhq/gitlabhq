# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Entry::AutoCancel, feature_category: :pipeline_composition do
  subject(:config) { described_class.new(config_hash) }

  context 'with on_new_commit' do
    let(:config_hash) do
      { on_new_commit: 'interruptible' }
    end

    it { is_expected.to be_valid }

    it 'returns value correctly' do
      expect(config.value).to eq(config_hash)
    end

    context 'when on_new_commit is invalid' do
      let(:config_hash) do
        { on_new_commit: 'invalid' }
      end

      it { is_expected.not_to be_valid }

      it 'returns errors' do
        expect(config.errors)
          .to include('auto cancel on new commit must be one of: conservative, interruptible, none')
      end
    end
  end

  context 'with on_job_failure' do
    ['all', 'none', nil].each do |value|
      context 'when the `on_job_failure` value is valid' do
        let(:config_hash) { { on_job_failure: value } }

        it { is_expected.to be_valid }

        it 'returns value correctly' do
          expect(config.value).to eq(on_job_failure: value)
        end
      end
    end

    context 'when on_job_failure is invalid' do
      let(:config_hash) do
        { on_job_failure: 'invalid' }
      end

      it { is_expected.not_to be_valid }

      it 'returns errors' do
        expect(config.errors)
          .to include('auto cancel on job failure must be one of: none, all')
      end
    end
  end

  context 'with invalid key' do
    let(:config_hash) do
      { invalid: 'interruptible' }
    end

    it { is_expected.not_to be_valid }

    it 'returns errors' do
      expect(config.errors)
        .to include('auto cancel config contains unknown keys: invalid')
    end
  end
end
