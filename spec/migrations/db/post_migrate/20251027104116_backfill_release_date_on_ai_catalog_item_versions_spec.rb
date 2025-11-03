# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillReleaseDateOnAiCatalogItemVersions, migration: :gitlab_main, feature_category: :workflow_catalog do
  let(:ai_catalog_items) { table(:ai_catalog_items) }
  let(:ai_catalog_item_versions) { table(:ai_catalog_item_versions) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:organizations) { table(:organizations) }

  context 'when Gitlab.ee?', if: Gitlab.ee? do
    let(:organization) { organizations.create!(name: 'Organization 1', path: 'organization-1') }
    let(:namespace) { namespaces.create!(name: 'namespace', path: 'namespace', organization_id: organization.id) }
    let(:project) do
      projects.create!(name: 'project', namespace_id: namespace.id, project_namespace_id: namespace.id,
        organization_id: organization.id)
    end

    let!(:catalog_item) do
      ai_catalog_items.create!(
        name: 'Test Item',
        description: 'A test AI catalog item',
        public: true,
        project_id: project.id,
        organization_id: organization.id,
        item_type: 0
      )
    end

    let!(:version_without_release_date) do
      ai_catalog_item_versions.create!(
        ai_catalog_item_id: catalog_item.id,
        version: '1.0.0',
        release_date: nil,
        organization_id: organization.id,
        schema_version: Ai::Catalog::ItemVersion::AGENT_SCHEMA_VERSION,
        created_at: 10.days.ago
      )
    end

    let!(:version_with_existing_release_date) do
      ai_catalog_item_versions.create!(
        ai_catalog_item_id: catalog_item.id,
        version: '2.0.0',
        release_date: 3.days.ago,
        organization_id: organization.id,
        schema_version: Ai::Catalog::ItemVersion::AGENT_SCHEMA_VERSION,
        created_at: 12.days.ago
      )
    end

    it 'backfills release_date for versions where release_date is NULL', :aggregate_failures do
      existing_release_date = version_with_existing_release_date.release_date

      expect { migrate! }.to change {
        version_without_release_date.reload.release_date
      }.from(nil)

      # Version with NULL release_date should be backfilled with created_at
      version_without_release_date.reload
      expect(version_without_release_date.release_date).to be_within(1.second)
        .of(version_without_release_date.created_at)

      # Version with existing release date should remain unchanged
      version_with_existing_release_date.reload
      expect(version_with_existing_release_date.release_date).to be_within(1.second).of(existing_release_date)
    end

    context 'when migration is run multiple times' do
      it 'is idempotent and does not change already backfilled data' do
        migrate!

        first_run_state = ai_catalog_item_versions.pluck(:id, :release_date).to_h

        migrate!

        second_run_state = ai_catalog_item_versions.pluck(:id, :release_date).to_h
        expect(second_run_state).to eq(first_run_state)
      end
    end
  end

  context 'when not Gitlab.ee?', unless: Gitlab.ee? do
    it 'does not fail' do
      expect { migrate! }.not_to raise_error
    end
  end
end
