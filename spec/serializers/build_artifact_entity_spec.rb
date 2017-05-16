require 'spec_helper'

describe BuildArtifactEntity do
  let(:job) { create(:ci_build, name: 'test:job') }

  let(:entity) do
    described_class.new(job, request: double)
  end

  describe '#as_json' do
    subject { entity.as_json }

    it 'contains job name' do
      expect(subject[:name]).to eq 'test:job'
    end

    it 'contains path to the artifacts' do
      expect(subject[:path])
        .to include "jobs/#{job.id}/artifacts/download"
    end
  end
end
