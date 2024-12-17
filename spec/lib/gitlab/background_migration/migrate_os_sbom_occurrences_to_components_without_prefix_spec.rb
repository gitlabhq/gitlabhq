# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::MigrateOsSbomOccurrencesToComponentsWithoutPrefix, feature_category: :software_composition_analysis do
  before(:all) do
    # This migration will not work if a sec database is configured. It should be finalized and removed prior to
    # sec db rollout.
    # Consult https://gitlab.com/gitlab-org/gitlab/-/merge_requests/171707 for more info.
    skip_if_multiple_databases_are_setup(:sec)
  end

  let(:organizations) { table(:organizations) }
  let(:projects) { table(:projects) }
  let(:namespaces) { table(:namespaces) }
  let(:sbom_components) { table(:sbom_components) }
  let(:sbom_component_versions) { table(:sbom_component_versions) }
  let(:sbom_occurrences) { table(:sbom_occurrences) }

  let(:organization) { organizations.create!(name: 'organization', path: 'organization') }

  let(:namespace) { namespaces.create!(name: 'gitlab', path: 'gitlab', organization_id: organization.id) }
  let(:project_namespace) do
    namespaces.create!(name: 'project-1', path: 'project', type: 'Project',
      parent_id: namespace.id, organization_id: organization.id)
  end

  let(:project) do
    projects.create!(name: 'project-1', path: 'project-1', project_namespace_id: project_namespace.id,
      namespace_id: namespace.id, organization_id: organization.id)
  end

  def create_sbom_occurrence(src_component, src_component_version)
    params = {
      project_id: project.id,
      component_id: src_component.id,
      component_name: src_component.name,
      component_version_id: src_component_version&.id,
      uuid: SecureRandom.uuid,
      commit_sha: SecureRandom.hex(20)
    }

    sbom_occurrences.create!(params)
  end

  context 'when sbom occurrence belongs to sbom component with os prefix' do
    let(:alpine_src_component) do
      sbom_components.create!(name: 'alpine/curl', purl_type: 9, component_type: 0, organization_id: 1)
    end

    let(:alpine_src_version) do
      sbom_component_versions.create!(version: '1.0.0', component_id: alpine_src_component.id,
        source_package_name: 'curl', organization_id: 1)
    end

    let(:redhat_src_component) do
      sbom_components.create!(name: 'redhat/curl', purl_type: 10, component_type: 0, organization_id: 1)
    end

    let(:redhat_src_version) do
      sbom_component_versions.create!(version: '1.0.0', component_id: redhat_src_component.id,
        source_package_name: 'curl', organization_id: 1)
    end

    let(:debian_src_component) do
      sbom_components.create!(name: 'debian/curl', purl_type: 11, component_type: 0, organization_id: 1)
    end

    let(:debian_src_version) do
      sbom_component_versions.create!(version: '1.0.0', component_id: debian_src_component.id,
        source_package_name: 'curl', organization_id: 1)
    end

    subject(:perform_migration) do
      described_class.new(
        start_id: sbom_components.first.id,
        end_id: sbom_components.last.id,
        batch_table: :sbom_components,
        batch_column: :id,
        sub_batch_size: sbom_components.count,
        pause_ms: 0,
        connection: ActiveRecord::Base.connection
      ).perform
    end

    it 'migrates the data correctly' do
      alpine_dst_component = sbom_components.create!(name: 'curl', purl_type: 9, component_type: 0, organization_id: 1)
      alpine_occurrence = create_sbom_occurrence(alpine_src_component, alpine_src_version)

      redhat_dst_component = sbom_components.create!(name: 'curl', purl_type: 10, component_type: 0, organization_id: 1)
      redhat_occurrence = create_sbom_occurrence(redhat_src_component, redhat_src_version)

      debian_dst_component = sbom_components.create!(name: 'curl', purl_type: 11, component_type: 0, organization_id: 1)
      debian_occurrence = create_sbom_occurrence(debian_src_component, debian_src_version)

      perform_migration

      alpine_dst_version = sbom_component_versions.find_by(component_id: alpine_dst_component.id)
      redhat_dst_version = sbom_component_versions.find_by(component_id: redhat_dst_component.id)
      debian_dst_version = sbom_component_versions.find_by(component_id: debian_dst_component.id)

      expect(alpine_occurrence.reload).to have_attributes(component_id: alpine_dst_component.id,
        component_name: alpine_dst_component.name, component_version_id: alpine_dst_version.id)

      expect(redhat_occurrence.reload).to have_attributes(component_id: redhat_dst_component.id,
        component_name: redhat_dst_component.name, component_version_id: redhat_dst_version.id)

      expect(debian_occurrence.reload).to have_attributes(component_id: debian_dst_component.id,
        component_name: debian_dst_component.name, component_version_id: debian_dst_version.id)
    end

    context 'when components have no versions' do
      let(:src_component) do
        sbom_components.create!(name: 'alpine/curl', purl_type: 9, component_type: 0, organization_id: 1)
      end

      it 'does not raise error' do
        occurrence = create_sbom_occurrence(src_component, nil)
        dst_component = sbom_components.create!(name: 'curl', purl_type: 9, component_type: 0, organization_id: 1)

        expect { perform_migration }.not_to raise_error

        expect(occurrence.reload).to have_attributes(component_id: dst_component.id, component_name: dst_component.name,
          component_version_id: nil
        )
      end
    end

    context 'when components have no occurrences' do
      it 'does not raise an error' do
        sbom_components.create!(name: 'alpine/curl', purl_type: 9, component_type: 0, organization_id: 1)

        expect { perform_migration }.not_to raise_error
      end
    end
  end
end
