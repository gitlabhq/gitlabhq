require 'spec_helper'

describe BuildArtifactEntity do
  let(:build) { create(:ci_build, name: 'test:build') }

  let(:entity) do
    described_class.new(build, request: double)
  end

  describe '#as_json' do
    subject { entity.as_json }

    it 'contains build name' do
      expect(subject[:name]).to eq 'test:build'
    end

    it 'contains path to the artifacts' do
      expect(subject[:path])
        .to include "builds/#{build.id}/artifacts/download"
    end
  end
end
