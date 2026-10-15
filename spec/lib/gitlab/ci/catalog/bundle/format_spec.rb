# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Catalog::Bundle::Format, feature_category: :pipeline_composition do
  describe '.dump' do
    let(:files) do
      {
        'templates/plan.yml' => "spec:\n  inputs:\n    as:\n---\nplan:\n  script: tofu plan  \n",
        'templates/base.yml' => "'$[[ inputs.as ]]':\n\tscript: !reference [.base, script]"
      }
    end

    subject(:bundle) do
      Gitlab::Json::SafeParser.parse(
        described_class.dump(
          name: 'plan', version: 'v1.2.0', sha: 'abc123', entry_path: 'templates/plan.yml', files: files
        )
      )
    end

    it 'records the format version and metadata' do
      expect(bundle).to include(
        'format_version' => 1,
        'name' => 'plan',
        'version' => 'v1.2.0',
        'sha' => 'abc123',
        'entry_path' => 'templates/plan.yml'
      )
    end

    it 'keeps every file byte for byte' do
      expect(bundle['files']).to eq(files)
    end
  end

  describe '.load' do
    let(:files) { { 'templates/plan.yml' => "plan:\n  script: tofu plan  \n" } }
    let(:document) do
      described_class.dump(
        name: 'plan', version: 'v1.2.0', sha: 'abc123', entry_path: 'templates/plan.yml', files: files
      )
    end

    subject(:bundle) { described_class.load(document) }

    it 'returns the metadata and the files' do
      expect(bundle).to have_attributes(
        name: 'plan', version: 'v1.2.0', sha: 'abc123', entry_path: 'templates/plan.yml', files: files
      )
    end

    context 'when the format version is unknown' do
      let(:document) { Gitlab::Json.dump(format_version: 2, files: {}) }

      it 'raises an error naming the version' do
        expect { bundle }.to raise_error(described_class::UnsupportedVersionError, /format version `2`/)
      end
    end
  end
end
