# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::StaticSiteEditor::Config::CombinedConfig do
  subject(:config) { described_class.new(repository, ref, path, return_url) }

  let(:repository) { double(:repository) }
  let(:ref) { double(:ref) }
  let(:path) { double(:path) }
  let(:return_url) { double(:return_url) }
  let(:generated_data) { { generated: true } }
  let(:file_data) { { file: true } }

  describe '#data' do
    subject { config.data }

    before do
      allow_next_instance_of(Gitlab::StaticSiteEditor::Config::GeneratedConfig) do |config|
        allow(config).to receive(:data) { generated_data }
      end
      allow_next_instance_of(Gitlab::StaticSiteEditor::Config::FileConfig) do |config|
        allow(config).to receive(:data) { file_data }
      end
    end

    it 'returns merged generated data and config file data' do
      is_expected.to eq({ generated: true, file: true })
    end

    it 'raises an exception if any keys would be overwritten by the merge' do
      generated_data[:duplicate_key] = true
      file_data[:duplicate_key] = true
      expect { subject }.to raise_error(StandardError, /duplicate key.*duplicate_key.*found/i)
    end
  end
end
