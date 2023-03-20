# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Releases::CreateEvidenceWorker, feature_category: :release_evidence do
  let(:project) { create(:project, :repository) }
  let(:release) { create(:release, project: project) }
  let(:pipeline) { create(:ci_empty_pipeline, sha: release.sha, project: project) }

  # support old scheduled workers without pipeline
  it 'creates a new Evidence record' do
    expect_next_instance_of(::Releases::CreateEvidenceService, release, pipeline: nil) do |service|
      expect(service).to receive(:execute).and_call_original
    end

    expect { described_class.new.perform(release.id) }.to change { Releases::Evidence.count }.by(1)
  end

  it 'creates a new Evidence record with pipeline' do
    expect_next_instance_of(::Releases::CreateEvidenceService, release, pipeline: pipeline) do |service|
      expect(service).to receive(:execute).and_call_original
    end

    expect { described_class.new.perform(release.id, pipeline.id) }.to change { Releases::Evidence.count }.by(1)
  end
end
