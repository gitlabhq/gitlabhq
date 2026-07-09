# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::UpdateDuoSecretDetectionFpEnabledToFalse, feature_category: :vulnerability_management do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:project_settings) { table(:project_settings) }
  let(:ai_catalog_items) { table(:ai_catalog_items) }
  let(:enabled_foundational_flows) { table(:enabled_foundational_flows) }

  let(:schema_migrations) { table(:schema_migrations) }
  let(:flip_finished_at) { Time.zone.parse('2026-05-01 00:00:00 UTC') }
  let(:cutoff) { flip_finished_at }
  let(:before_cutoff) { cutoff - 1.day }
  let(:after_cutoff) { cutoff + 1.day }

  let!(:organization) { organizations.create!(name: 'Organization', path: 'organization') }
  let!(:secret_fp_item) { create_catalog_item('secrets_fp_detection/v1') }
  let!(:other_flow_item) { create_catalog_item('sast_fp_detection/v1') }

  subject(:migration) do
    described_class.new(
      start_cursor: [0],
      end_cursor: [project_settings.maximum(:project_id)],
      batch_table: :project_settings,
      batch_column: :project_id,
      sub_batch_size: 10,
      pause_ms: 0,
      connection: ::ApplicationRecord.connection
    )
  end

  # The cutoff is read from schema_migrations.finished_at for the 18.11 default-flip migration
  # (described_class#cutoff). The row already exists in the test DB; pin it deterministically.
  before do
    schema_migrations
      .where(version: described_class::DEFAULT_FLIP_MIGRATION_VERSION)
      .update_all(finished_at: flip_finished_at)
  end

  describe '#perform' do
    context 'when around the cutoff' do
      it 'resets rows created before the cutoff and leaves rows created at or after it' do
        pre_cutoff = create_project_with_setting(
          group: create_group, duo_secret_detection_fp_enabled: true, at: cutoff - 1.second
        )
        at_cutoff = create_project_with_setting(
          group: create_group, duo_secret_detection_fp_enabled: true, at: cutoff
        )
        post_cutoff = create_project_with_setting(
          group: create_group, duo_secret_detection_fp_enabled: true, at: after_cutoff
        )

        expect { migration.perform }
          .to change { pre_cutoff.reload.duo_secret_detection_fp_enabled }.to(false)
          .and not_change { at_cutoff.reload.duo_secret_detection_fp_enabled }.from(true)
          .and not_change { post_cutoff.reload.duo_secret_detection_fp_enabled }.from(true)
      end
    end

    context 'when the instance flipped the default after the GitLab.com date' do
      it 'uses the per-instance schema_migrations.finished_at, not DEFAULT_CHANGED_AT' do
        # created_at is after DEFAULT_CHANGED_AT but before this instance's flip_finished_at, so it
        # is accidental on this instance and must be reset
        row = create_project_with_setting(
          group: create_group,
          duo_secret_detection_fp_enabled: true,
          at: Time.zone.parse(described_class::DEFAULT_CHANGED_AT) + 1.day
        )

        expect { migration.perform }
          .to change { row.reload.duo_secret_detection_fp_enabled }.to(false)
      end
    end

    context 'when the flip migration has no recorded finished_at' do
      before do
        schema_migrations
          .where(version: described_class::DEFAULT_FLIP_MIGRATION_VERSION)
          .update_all(finished_at: nil)
      end

      it 'falls back to DEFAULT_CHANGED_AT' do
        fallback = Time.zone.parse(described_class::DEFAULT_CHANGED_AT)
        pre_fallback = create_project_with_setting(
          group: create_group, duo_secret_detection_fp_enabled: true, at: fallback - 1.second
        )
        post_fallback = create_project_with_setting(
          group: create_group, duo_secret_detection_fp_enabled: true, at: fallback + 1.day
        )

        expect { migration.perform }
          .to change { pre_fallback.reload.duo_secret_detection_fp_enabled }.to(false)
          .and not_change { post_fallback.reload.duo_secret_detection_fp_enabled }.from(true)
      end
    end

    context 'with an already-false row' do
      it 'leaves it false' do
        project_setting = create_project_with_setting(group: create_group, duo_secret_detection_fp_enabled: false)

        expect { migration.perform }
          .not_to change { project_setting.reload.duo_secret_detection_fp_enabled }.from(false)
      end
    end

    context 'when the secret-FP flow is enabled for the project' do
      it 'preserves the project' do
        project_setting = create_project_with_setting(
          group: create_group, duo_secret_detection_fp_enabled: true, project_flows: :secret_fp
        )

        expect { migration.perform }
          .not_to change { project_setting.reload.duo_secret_detection_fp_enabled }.from(true)
      end
    end

    context 'when only a different flow is enabled for the project' do
      it 'resets' do
        project_setting = create_project_with_setting(
          group: create_group, duo_secret_detection_fp_enabled: true, project_flows: :other
        )

        expect { migration.perform }
          .to change { project_setting.reload.duo_secret_detection_fp_enabled }.to(false)
      end
    end

    # Enablement is read only from the project's own (materialised) enabled_foundational_flows
    # rows. The ancestor recursion is intentionally dropped: enabling the flow at a group cascades
    # a per-project row to every descendant project, so the project row exists for genuine opt-ins,
    # and we accept missing the rare project whose cascade is stale ( project transfers and synchronisation window )
    context 'when the flow is enabled at the group but not materialised on the project' do
      it 'resets, because the materialised-only check intentionally ignores ancestor rows' do
        project_setting = create_project_with_setting(
          group: create_group(foundational_flows: :secret_fp), duo_secret_detection_fp_enabled: true
        )

        expect { migration.perform }
          .to change { project_setting.reload.duo_secret_detection_fp_enabled }.to(false)
      end
    end

    context 'when no flow records exist' do
      it 'resets' do
        project_setting = create_project_with_setting(group: create_group, duo_secret_detection_fp_enabled: true)

        expect { migration.perform }
          .to change { project_setting.reload.duo_secret_detection_fp_enabled }.to(false)
      end
    end

    context 'when the materialised secret-FP catalog item is soft-deleted' do
      it 'resets, because deleted catalog items are ignored' do
        secret_fp_item.update!(deleted_at: before_cutoff)
        project_setting = create_project_with_setting(
          group: create_group, duo_secret_detection_fp_enabled: true, project_flows: :secret_fp
        )

        expect { migration.perform }
          .to change { project_setting.reload.duo_secret_detection_fp_enabled }.to(false)
      end
    end
  end

  def create_catalog_item(reference, organization_id: organization.id)
    ai_catalog_items.create!(
      organization_id: organization_id,
      item_type: 2, # :flow
      name: "flow-#{SecureRandom.hex(4)}",
      description: 'Foundational flow test item',
      foundational_flow_reference: reference
    )
  end

  # foundational_flows: nil -> group has NO enabled_foundational_flows rows;
  #   :secret_fp -> a namespace row pointing at the secret-FP item (ignored by the materialised
  #   project-level check); :other -> a namespace row pointing at the decoy.
  def create_group(foundational_flows: nil, parent: nil)
    name = "grp-#{SecureRandom.hex(4)}"
    group = namespaces.create!(
      name: name, path: name, type: 'Group', organization_id: organization.id, parent_id: parent&.id
    )
    group.update!(traversal_ids: Array(parent&.traversal_ids) + [group.id])
    add_flow_row(kind: foundational_flows, namespace_id: group.id)

    group
  end

  def create_project_with_setting(group:, duo_secret_detection_fp_enabled:, at: before_cutoff, project_flows: nil)
    suffix = SecureRandom.hex(4)
    project_namespace = namespaces.create!(
      name: "pns-#{suffix}", path: "pns-#{suffix}", type: 'Project', organization_id: organization.id
    )
    project = projects.create!(
      namespace_id: group.id, project_namespace_id: project_namespace.id,
      organization_id: organization.id, name: "proj-#{suffix}", path: "proj-#{suffix}"
    )
    add_flow_row(kind: project_flows, project_id: project.id)

    project_settings.create!(
      project_id: project.id,
      duo_secret_detection_fp_enabled: duo_secret_detection_fp_enabled,
      created_at: at
    )
  end

  def add_flow_row(kind:, namespace_id: nil, project_id: nil)
    return if kind.nil?

    item = kind == :secret_fp ? secret_fp_item : other_flow_item
    enabled_foundational_flows.create!(catalog_item_id: item.id, namespace_id: namespace_id, project_id: project_id)
  end
end
