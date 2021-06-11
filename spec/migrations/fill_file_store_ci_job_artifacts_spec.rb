# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FillFileStoreCiJobArtifacts do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:builds) { table(:ci_builds) }
  let(:job_artifacts) { table(:ci_job_artifacts) }

  before do
    namespaces.create!(id: 123, name: 'sample', path: 'sample')
    projects.create!(id: 123, name: 'sample', path: 'sample', namespace_id: 123)
    builds.create!(id: 1)
  end

  context 'when file_store is nil' do
    it 'updates file_store to local' do
      job_artifacts.create!(project_id: 123, job_id: 1, file_type: 1, file_store: nil)
      job_artifact = job_artifacts.find_by(project_id: 123, job_id: 1)

      expect { migrate! }.to change { job_artifact.reload.file_store }.from(nil).to(1)
    end
  end

  context 'when file_store is set to local' do
    it 'does not update file_store' do
      job_artifacts.create!(project_id: 123, job_id: 1, file_type: 1, file_store: 1)
      job_artifact = job_artifacts.find_by(project_id: 123, job_id: 1)

      expect { migrate! }.not_to change { job_artifact.reload.file_store }
    end
  end

  context 'when file_store is set to object storage' do
    it 'does not update file_store' do
      job_artifacts.create!(project_id: 123, job_id: 1, file_type: 1, file_store: 2)
      job_artifact = job_artifacts.find_by(project_id: 123, job_id: 1)

      expect { migrate! }.not_to change { job_artifact.reload.file_store }
    end
  end
end
