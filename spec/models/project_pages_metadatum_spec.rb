# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectPagesMetadatum do
  describe '.only_on_legacy_storage' do
    it 'returns only deployed records without deployment' do
      create(:project) # without pages deployed

      legacy_storage_project = create(:project)
      legacy_storage_project.mark_pages_as_deployed

      project_with_deployment = create(:project)
      deployment = create(:pages_deployment, project: project_with_deployment)
      project_with_deployment.mark_pages_as_deployed
      project_with_deployment.update_pages_deployment!(deployment)

      expect(described_class.only_on_legacy_storage).to eq([legacy_storage_project.pages_metadatum])
    end
  end

  it_behaves_like 'cleanup by a loose foreign key' do
    let!(:model) do
      artifacts_archive = create(:ci_job_artifact, :legacy_archive)
      metadatum = artifacts_archive.project.pages_metadatum
      metadatum.artifacts_archive = artifacts_archive
      metadatum
    end

    let!(:parent) { model.artifacts_archive }
  end
end
