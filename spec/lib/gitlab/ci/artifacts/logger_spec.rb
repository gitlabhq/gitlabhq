# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Artifacts::Logger do
  before do
    Gitlab::ApplicationContext.push(feature_category: 'test', caller_id: 'caller')
  end

  describe '.log_created' do
    it 'logs information about created artifact' do
      artifact_1 = create(:ci_job_artifact, :archive)
      artifact_2 = create(:ci_job_artifact, :metadata)
      artifacts = [artifact_1, artifact_2]

      artifacts.each do |artifact|
        expect(Gitlab::AppLogger).to receive(:info).with(
          hash_including(
            message: 'Artifact created',
            job_artifact_id: artifact.id,
            size: artifact.size,
            file_type: artifact.file_type,
            build_id: artifact.job_id,
            project_id: artifact.project_id,
            'correlation_id' => an_instance_of(String),
            'meta.feature_category' => 'test',
            'meta.caller_id' => 'caller'
          )
        )
      end

      described_class.log_created(artifacts)
    end
  end

  describe '.log_deleted' do
    it 'logs information about deleted artifacts' do
      artifact_1 = create(:ci_job_artifact, :archive, :expired)
      artifact_2 = create(:ci_job_artifact, :archive)
      artifacts = [artifact_1, artifact_2]
      method = 'Foo#method'

      artifacts.each do |artifact|
        expect(Gitlab::AppLogger).to receive(:info).with(
          hash_including(
            message: 'Artifact deleted',
            job_artifact_id: artifact.id,
            expire_at: artifact.expire_at,
            size: artifact.size,
            file_type: artifact.file_type,
            build_id: artifact.job_id,
            project_id: artifact.project_id,
            method: method,
            'correlation_id' => an_instance_of(String),
            'meta.feature_category' => 'test',
            'meta.caller_id' => 'caller'
          )
        )
      end

      described_class.log_deleted(artifacts, method)
    end
  end
end
