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
end
