# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillOccurrenceIdToSbomOccurrencesVulnerabilities,
  feature_category: :vulnerability_management do
  let(:sbom_components) { table(:sbom_components, database: :sec) }
  let(:sbom_occurrences) { table(:sbom_occurrences, database: :sec) }

  it_behaves_like 'backfills occurrence id from vulnerabilities' do
    let(:batch_table) { :sbom_occurrences_vulnerabilities }

    let(:sbom_component) do
      sbom_components.create!(
        created_at: now,
        updated_at: now,
        name: 'activerecord',
        component_type: 0,
        organization_id: organization.id
      )
    end

    let(:sbom_occurrence) do
      sbom_occurrences.create!(
        created_at: now,
        updated_at: now,
        project_id: project.id,
        component_id: sbom_component.id,
        commit_sha: SecureRandom.hex(20),
        uuid: SecureRandom.uuid
      )
    end

    let!(:record) do
      model.create!(
        created_at: now,
        updated_at: now,
        sbom_occurrence_id: sbom_occurrence.id,
        vulnerability_id: vulnerability.id,
        project_id: project.id
      )
    end
  end
end
