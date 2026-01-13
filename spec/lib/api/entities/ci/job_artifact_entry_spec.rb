# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::Ci::JobArtifactEntry, feature_category: :job_artifacts do
  let(:entry) { instance_double(Gitlab::Ci::Build::Artifacts::Metadata::Entry) }
  let(:entity) { described_class.new(entry) }

  subject(:json) { entity.as_json }

  before do
    allow(entry).to receive_messages(
      name: 'test.txt',
      path: 'path/to/test.txt',
      directory?: false,
      file?: true,
      metadata: metadata
    )
  end

  describe '#mode' do
    context 'when mode is present in metadata' do
      let(:metadata) { { mode: 33188, size: 1234 } }

      it 'returns mode as zero-padded string' do
        expect(json[:mode]).to eq('033188')
      end
    end

    context 'when mode is a short string' do
      let(:metadata) { { mode: '644', size: 1234 } }

      it 'returns mode as zero-padded string' do
        expect(json[:mode]).to eq('000644')
      end
    end

    context 'when mode is nil in metadata' do
      let(:metadata) { { size: 1234 } }

      it 'returns nil for mode' do
        expect(json[:mode]).to be_nil
      end
    end

    context 'when metadata is empty' do
      let(:metadata) { {} }

      it 'returns nil for mode' do
        expect(json[:mode]).to be_nil
      end
    end
  end
end
