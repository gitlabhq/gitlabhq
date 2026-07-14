# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillModelFeaturesAccessLevel, feature_category: :mlops do
  let(:connection) { ApplicationRecord.connection }

  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:project_features) { table(:project_features) }

  # Featurable / VisibilityLevel constants
  let(:disabled) { 0 }
  let(:private_level) { 10 }
  let(:enabled) { 20 }
  let(:private_visibility) { 0 }
  let(:internal_visibility) { 10 }
  let(:public_visibility) { 20 }

  let(:organization) { organizations.create!(name: 'org', path: 'org') }
  let(:namespace) { namespaces.create!(name: 'ns', path: 'ns', organization_id: organization.id) }

  # Should be backfilled to PRIVATE
  let!(:private_enabled) do
    create_project_feature(visibility_level: private_visibility, model_registry: enabled, model_experiments: enabled)
  end

  let!(:internal_enabled) do
    create_project_feature(visibility_level: internal_visibility, model_registry: enabled, model_experiments: enabled)
  end

  # Only the ENABLED column is changed; the other is left as-is
  let!(:private_mixed) do
    create_project_feature(visibility_level: private_visibility, model_registry: enabled, model_experiments: disabled)
  end

  # Left untouched
  let!(:public_enabled) do
    create_project_feature(visibility_level: public_visibility, model_registry: enabled, model_experiments: enabled)
  end

  let!(:private_already_private) do
    create_project_feature(visibility_level: private_visibility, model_registry: private_level,
      model_experiments: private_level)
  end

  let!(:private_disabled) do
    create_project_feature(visibility_level: private_visibility, model_registry: disabled, model_experiments: disabled)
  end

  let(:migration) do
    described_class.new(
      start_cursor: [project_features.minimum(:id)],
      end_cursor: [project_features.maximum(:id)],
      batch_table: :project_features,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: connection
    )
  end

  def create_project(visibility_level:)
    suffix = namespaces.count
    pns = namespaces.create!(name: "pns#{suffix}", path: "pns#{suffix}", organization_id: organization.id)
    projects.create!(
      namespace_id: namespace.id,
      project_namespace_id: pns.id,
      organization_id: organization.id,
      visibility_level: visibility_level
    )
  end

  def create_project_feature(visibility_level:, model_registry:, model_experiments:)
    project = create_project(visibility_level: visibility_level)
    project_features.create!(
      project_id: project.id,
      pages_access_level: enabled,
      model_registry_access_level: model_registry,
      model_experiments_access_level: model_experiments
    )
  end

  def model_levels(project_feature)
    project_feature.reload.slice(:model_registry_access_level, :model_experiments_access_level)
  end

  describe '#perform' do
    it 'sets ENABLED model access levels to PRIVATE on non-public projects', :aggregate_failures do
      migration.perform

      expect(private_enabled.reload).to have_attributes(
        model_registry_access_level: private_level, model_experiments_access_level: private_level
      )
      expect(internal_enabled.reload).to have_attributes(
        model_registry_access_level: private_level, model_experiments_access_level: private_level
      )
    end

    it 'only changes the ENABLED column, leaving other levels intact' do
      migration.perform

      expect(private_mixed.reload).to have_attributes(
        model_registry_access_level: private_level, model_experiments_access_level: disabled
      )
    end

    it 'leaves public projects untouched' do
      expect { migration.perform }.not_to change { model_levels(public_enabled) }
    end

    it 'leaves already-private and disabled levels untouched', :aggregate_failures do
      migration.perform

      expect(private_already_private.reload).to have_attributes(
        model_registry_access_level: private_level, model_experiments_access_level: private_level
      )
      expect(private_disabled.reload).to have_attributes(
        model_registry_access_level: disabled, model_experiments_access_level: disabled
      )
    end

    it 'is idempotent' do
      migration.perform

      expect { migration.perform }.not_to change {
        project_features.order(:id).pluck(:model_registry_access_level, :model_experiments_access_level)
      }
    end
  end
end
