# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Entry::Caches, feature_category: :pipeline_composition do
  using RSpec::Parameterized::TableSyntax

  subject(:entry) { described_class.new(config) }

  let(:max_caches_per_job) { 4 }

  before do
    allow(Gitlab::CurrentSettings.current_application_settings)
      .to receive(:ci_max_caches_per_job).and_return(max_caches_per_job)
    entry.compose!
  end

  describe '#valid?' do
    context 'with an empty hash as cache' do
      let(:config) { {} }

      it 'is valid' do
        expect(entry).to be_valid
      end
    end

    context 'when configuration is valid with a single cache' do
      let(:config)  { { key: 'key', paths: ["logs/"], untracked: true } }

      it 'is valid' do
        expect(entry).to be_valid
      end
    end

    context 'when configuration is valid with multiple caches' do
      let(:config) do
        [
          { key: 'key', paths: ["logs/"], untracked: true },
          { key: 'key2', paths: ["logs/"], untracked: true },
          { key: 'key3', paths: ["logs/"], untracked: true }
        ]
      end

      it 'is valid' do
        expect(entry).to be_valid
      end
    end

    context 'when configuration is not a Hash or Array' do
      let(:config) { 'invalid' }

      it 'is invalid' do
        expect(entry).not_to be_valid
      end
    end

    context 'when entry values contain more than four caches' do
      let(:config) do
        [
          { key: 'key', paths: ["logs/"], untracked: true },
          { key: 'key2', paths: ["logs/"], untracked: true },
          { key: 'key3', paths: ["logs/"], untracked: true },
          { key: 'key4', paths: ["logs/"], untracked: true },
          { key: 'key5', paths: ["logs/"], untracked: true }
        ]
      end

      it 'is invalid' do
        expect(entry.errors).to eq(["caches config no more than 4 caches can be created"])
        expect(entry).not_to be_valid
      end

      context 'when an admin has raised ci_max_caches_per_job' do
        let(:max_caches_per_job) { 5 }

        it 'allows up to the configured limit' do
          expect(entry).to be_valid
        end
      end
    end
  end
end
