# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/MultipleMemoizedHelpers -- Polymorphic table used by many models requires complex setup
RSpec.describe Gitlab::BackgroundMigration::BackfillPartitionedUploads, :aggregate_failures,
  :migration_with_transaction,
  feature_category: :database do
  let(:uploads_table) { table(:uploads) }
  let(:partitioned_uploads_table) { table(:uploads_9ba88c4165) }

  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:users) { table(:users) }
  let(:abuse_reports) { table(:abuse_reports) }
  let(:achievements) { table(:achievements) }
  let(:ai_vectorizable_files) { table(:ai_vectorizable_files) }
  let(:alert_management_alerts) { table(:alert_management_alerts) }
  let(:alert_management_alert_metric_images) { table(:alert_management_alert_metric_images) }
  let(:appearances) { table(:appearances) }
  let(:dependency_list_exports) { table(:dependency_list_exports, database: :sec) }
  let(:import_export_uploads) { table(:import_export_uploads) }
  let(:issuable_metric_images) { table(:issuable_metric_images) }
  let(:organization_details) { table(:organization_details) }
  let(:topics) { table(:topics) }
  let(:snippets) { table(:snippets) }
  let(:user_permission_export_uploads) { table(:user_permission_export_uploads) }
  let(:dependency_list_export_parts) { table(:dependency_list_export_parts, database: :sec) }
  let(:vulnerability_exports) { table(:vulnerability_exports, database: :sec) }
  let(:vulnerability_export_parts) { table(:vulnerability_export_parts, database: :sec) }
  let(:vulnerability_remediations) { table(:vulnerability_remediations, database: :sec) }
  let(:vulnerability_archive_exports) { table(:vulnerability_archive_exports, database: :sec) }
  let(:project_export_jobs) { table(:project_export_jobs) }
  let(:project_relation_exports) { table(:project_relation_exports) }
  let(:project_relation_export_uploads) { table(:project_relation_export_uploads) }
  let(:design_management_designs) { table(:design_management_designs) }
  let(:design_management_versions) { table(:design_management_versions) }
  let(:design_management_designs_versions) { table(:design_management_designs_versions) }
  let(:bulk_import_exports) { table(:bulk_import_exports) }
  let(:bulk_import_export_uploads) { table(:bulk_import_export_uploads) }

  let(:connection) { ApplicationRecord.connection }

  describe '#perform' do
    before do
      # Partitioned table vulnerability_archive_exports is registered only for GitLab EE,
      # when running tests for FOSS_ONLY we need at least one partition to be able to
      # create the parent record.
      SecApplicationRecord.connection.execute <<~SQL
         CREATE TABLE _test_vulnerability_archive_exports_default
         PARTITION OF vulnerability_archive_exports DEFAULT
      SQL
    end

    it 'backfill missing uploads' do
      # Uploads to be_truthy copied
      abuse_report_upload_to_be_synced = create_abuse_report_upload
      appearance_upload_to_be_synced = create_appearance_upload
      achievement_1 = create_achievement
      achievement_upload_to_be_synced = create_achievement_upload(model: achievement_1)
      ai_vectorizable_file_1 = create_ai_vectorizable_file
      ai_vectorizable_file_upload_to_be_synced = create_ai_vectorizable_file_upload(model: ai_vectorizable_file_1)
      alert_metric_image_1 = create_alert_metric_image
      alert_metric_image_upload_to_be_synced = create_alert_metric_image_upload(model: alert_metric_image_1)
      dependency_list_export_1 = create_dependency_list_export
      dependency_list_export_upload_to_be_synced = create_dependency_list_export_upload(model: dependency_list_export_1)
      dependency_list_export_part_1 = create_dependency_list_export_part
      dependency_list_export_part_upload_to_be_synced = create_dependency_list_export_part_upload(
        model: dependency_list_export_part_1)
      import_export_upload_1 = create_import_export_upload
      import_export_upload_upload_to_be_synced = create_import_export_upload_upload(model: import_export_upload_1)
      issuable_metric_image_1 = create_issuable_metric_image
      issuable_metric_image_upload_to_be_synced = create_issuable_metric_image_upload(model: issuable_metric_image_1)
      organization_detail_1 = create_organization_detail
      organization_detail_upload_to_be_synced = create_organization_detail_upload(model: organization_detail_1)
      topic_1 = create_topic
      topic_upload_to_be_synced = create_topic_upload(model: topic_1)
      snippet_1 = create_snippet
      snippet_upload_to_be_synced = create_snippet_upload(model: snippet_1)
      user_permission_export_upload_1 = create_user_permission_export_upload
      user_permission_export_upload_upload_to_be_synced = create_user_permission_export_upload_upload(
        model: user_permission_export_upload_1)
      user_1 = create_user(organization_id: create_organization.id)
      user_upload_to_be_synced = create_user_upload(model: user_1)
      vulnerability_export_1 = create_vulnerability_export
      vulnerability_export_upload_to_be_synced = create_vulnerability_export_upload(model: vulnerability_export_1)
      vulnerability_export_part_1 = create_vulnerability_export_part
      vulnerability_export_part_upload_to_be_synced = create_vulnerability_export_part_upload(
        model: vulnerability_export_part_1)
      vulnerability_remediation_1 = create_vulnerability_remediation
      vulnerability_remediation_upload_to_be_synced = create_vulnerability_remediation_upload(
        model: vulnerability_remediation_1)
      vulnerability_archive_export_1 = create_vulnerability_archive_export
      vulnerability_archive_export_upload_to_be_synced = create_vulnerability_archive_export_upload(
        model: vulnerability_archive_export_1)
      project_1 = create_project
      project_upload_to_be_synced = create_project_upload(model: project_1)
      namespace_1 = create_namespace
      namespace_upload_to_be_synced = create_namespace_upload(model: namespace_1)
      project_relation_export_upload_1 = create_project_relation_export_upload
      project_relation_export_upload_upload_to_be_synced = create_project_relation_export_upload_upload(
        model: project_relation_export_upload_1)
      designs_version_1 = create_designs_version
      designs_version_upload_to_be_synced = create_designs_version_upload(model: designs_version_1)
      bulk_import_export_upload_1 = create_bulk_import_export_upload
      bulk_import_export_upload_upload_to_be_synced = create_bulk_import_export_upload_upload(
        model: bulk_import_export_upload_1)

      # Parentless uploads not to be back-filled
      abuse_report_upload_to_be_removed = create_abuse_report_upload(delete_model: true)
      appearance_upload_to_be_removed = create_appearance_upload(delete_model: true)
      achievement_upload_to_be_removed = create_achievement_upload(delete_model: true)
      ai_vectorizable_file_upload_to_be_removed = create_ai_vectorizable_file_upload(delete_model: true)
      alert_metric_image_upload_to_be_removed = create_alert_metric_image_upload(delete_model: true)
      dependency_list_export_upload_to_be_removed = create_dependency_list_export_upload(delete_model: true)
      dependency_list_export_part_upload_to_be_removed = create_dependency_list_export_part_upload(delete_model: true)
      import_export_upload_upload_to_be_removed = create_import_export_upload_upload(delete_model: true)
      issuable_metric_image_upload_to_be_removed = create_issuable_metric_image_upload(delete_model: true)
      organization_detail_upload_to_be_removed = create_organization_detail_upload(delete_model: true)
      topic_upload_to_be_removed = create_topic_upload(delete_model: true)
      snippet_upload_to_be_removed = create_snippet_upload(delete_model: true)
      user_permission_export_upload_upload_to_be_removed = create_user_permission_export_upload_upload(
        delete_model: true)
      user_upload_to_be_removed = create_user_upload(delete_model: true)
      vulnerability_export_upload_to_be_removed = create_vulnerability_export_upload(delete_model: true)
      vulnerability_export_part_upload_to_be_removed = create_vulnerability_export_part_upload(delete_model: true)
      vulnerability_remediation_upload_to_be_removed = create_vulnerability_remediation_upload(delete_model: true)
      vulnerability_archive_export_upload_to_be_removed = create_vulnerability_archive_export_upload(delete_model: true)
      project_upload_to_be_removed = create_project_upload(delete_model: true)
      namespace_upload_to_be_removed = create_namespace_upload(delete_model: true)
      project_relation_export_upload_upload_to_be_removed = create_project_relation_export_upload_upload(
        delete_model: true)
      designs_version_upload_to_be_removed = create_designs_version_upload(delete_model: true)
      bulk_import_export_upload_upload_to_be_removed = create_bulk_import_export_upload_upload(delete_model: true)

      connection.truncate(partitioned_uploads_table.table_name)

      # Uploads already copied
      abuse_report_upload_synced = create_abuse_report_upload
      appearance_upload_synced = create_appearance_upload
      achievement_2 = create_achievement
      achievement_upload_synced = create_achievement_upload(model: achievement_2)
      ai_vectorizable_file_2 = create_ai_vectorizable_file
      ai_vectorizable_file_upload_synced = create_ai_vectorizable_file_upload(model: ai_vectorizable_file_2)
      alert_metric_image_2 = create_alert_metric_image
      alert_metric_image_upload_synced = create_alert_metric_image_upload(model: alert_metric_image_2)
      dependency_list_export_2 = create_dependency_list_export
      dependency_list_export_upload_synced = create_dependency_list_export_upload(model: dependency_list_export_2)
      dependency_list_export_part_2 = create_dependency_list_export_part
      dependency_list_export_part_upload_synced = create_dependency_list_export_part_upload(
        model: dependency_list_export_part_2)
      import_export_upload_2 = create_import_export_upload
      import_export_upload_upload_synced = create_import_export_upload_upload(model: import_export_upload_2)
      issuable_metric_image_2 = create_issuable_metric_image
      issuable_metric_image_upload_synced = create_issuable_metric_image_upload(model: issuable_metric_image_2)
      organization_detail_2 = create_organization_detail
      organization_detail_upload_synced = create_organization_detail_upload(model: organization_detail_2)
      topic_2 = create_topic
      topic_upload_synced = create_topic_upload(model: topic_2)
      snippet_2 = create_snippet
      snippet_upload_synced = create_snippet_upload(model: snippet_2)
      user_permission_export_upload_2 = create_user_permission_export_upload
      user_permission_export_upload_upload_synced = create_user_permission_export_upload_upload(
        model: user_permission_export_upload_2)
      user_2 = create_user(organization_id: create_organization.id)
      user_upload_synced = create_user_upload(model: user_2)
      vulnerability_export_2 = create_vulnerability_export
      vulnerability_export_upload_synced = create_vulnerability_export_upload(model: vulnerability_export_2)
      vulnerability_export_part_2 = create_vulnerability_export_part
      vulnerability_export_part_upload_synced = create_vulnerability_export_part_upload(
        model: vulnerability_export_part_2)
      vulnerability_remediation_2 = create_vulnerability_remediation
      vulnerability_remediation_upload_synced = create_vulnerability_remediation_upload(
        model: vulnerability_remediation_2)
      vulnerability_archive_export_2 = create_vulnerability_archive_export
      vulnerability_archive_export_upload_synced = create_vulnerability_archive_export_upload(
        model: vulnerability_archive_export_2)
      project_2 = create_project
      project_upload_synced = create_project_upload(model: project_2)
      namespace_2 = create_namespace
      namespace_upload_synced = create_namespace_upload(model: namespace_2)
      project_relation_export_upload_2 = create_project_relation_export_upload
      project_relation_export_upload_upload_synced = create_project_relation_export_upload_upload(
        model: project_relation_export_upload_2)
      designs_version_2 = create_designs_version
      designs_version_upload_synced = create_designs_version_upload(model: designs_version_2)
      bulk_import_export_upload_2 = create_bulk_import_export_upload
      bulk_import_export_upload_upload_synced = create_bulk_import_export_upload_upload(
        model: bulk_import_export_upload_2)

      expect(uploads_table.find_by_id(abuse_report_upload_to_be_removed.id)).to be_truthy
      expect(find_partitioned_upload(abuse_report_upload_to_be_removed.id)).not_to be_truthy
      expect(find_partitioned_upload(abuse_report_upload_synced.id)).to be_truthy

      expect(uploads_table.find_by_id(appearance_upload_to_be_removed.id)).to be_truthy
      expect(find_partitioned_upload(appearance_upload_to_be_removed.id)).not_to be_truthy
      expect(find_partitioned_upload(appearance_upload_synced.id)).to be_truthy

      expect(uploads_table.find_by_id(achievement_upload_to_be_removed.id)).to be_truthy
      expect(find_partitioned_upload(achievement_upload_to_be_removed.id)).not_to be_truthy
      expect(find_partitioned_upload(achievement_upload_synced.id)).to be_truthy

      expect(uploads_table.find_by_id(ai_vectorizable_file_upload_to_be_removed.id)).to be_truthy
      expect(find_partitioned_upload(ai_vectorizable_file_upload_to_be_removed.id)).not_to be_truthy
      expect(find_partitioned_upload(ai_vectorizable_file_upload_synced.id)).to be_truthy

      expect(uploads_table.find_by_id(alert_metric_image_upload_to_be_removed.id)).to be_truthy
      expect(find_partitioned_upload(alert_metric_image_upload_to_be_removed.id)).not_to be_truthy
      expect(find_partitioned_upload(alert_metric_image_upload_synced.id)).to be_truthy

      expect(uploads_table.find_by_id(dependency_list_export_upload_to_be_removed.id)).to be_truthy
      expect(find_partitioned_upload(dependency_list_export_upload_to_be_removed.id)).not_to be_truthy
      expect(find_partitioned_upload(dependency_list_export_upload_synced.id)).to be_truthy

      expect(uploads_table.find_by_id(dependency_list_export_part_upload_to_be_removed.id)).to be_truthy
      expect(find_partitioned_upload(dependency_list_export_part_upload_to_be_removed.id)).not_to be_truthy
      expect(find_partitioned_upload(dependency_list_export_part_upload_synced.id)).to be_truthy

      expect(uploads_table.find_by_id(import_export_upload_upload_to_be_removed.id)).to be_truthy
      expect(find_partitioned_upload(import_export_upload_upload_to_be_removed.id)).not_to be_truthy
      expect(find_partitioned_upload(import_export_upload_upload_synced.id)).to be_truthy

      expect(uploads_table.find_by_id(issuable_metric_image_upload_to_be_removed.id)).to be_truthy
      expect(find_partitioned_upload(issuable_metric_image_upload_to_be_removed.id)).not_to be_truthy
      expect(find_partitioned_upload(issuable_metric_image_upload_synced.id)).to be_truthy

      expect(uploads_table.find_by_id(organization_detail_upload_to_be_removed.id)).to be_truthy
      expect(find_partitioned_upload(organization_detail_upload_to_be_removed.id)).not_to be_truthy
      expect(find_partitioned_upload(organization_detail_upload_synced.id)).to be_truthy

      expect(uploads_table.find_by_id(snippet_upload_to_be_removed.id)).to be_truthy
      expect(find_partitioned_upload(snippet_upload_to_be_removed.id)).not_to be_truthy
      expect(find_partitioned_upload(snippet_upload_synced.id)).to be_truthy

      expect(uploads_table.find_by_id(user_permission_export_upload_upload_to_be_removed.id)).to be_truthy
      expect(find_partitioned_upload(user_permission_export_upload_upload_to_be_removed.id)).not_to be_truthy
      expect(find_partitioned_upload(user_permission_export_upload_upload_synced.id)).to be_truthy

      expect(uploads_table.find_by_id(user_upload_to_be_removed.id)).to be_truthy
      expect(find_partitioned_upload(user_upload_to_be_removed.id)).not_to be_truthy
      expect(find_partitioned_upload(user_upload_synced.id)).to be_truthy

      expect(uploads_table.find_by_id(vulnerability_export_upload_to_be_removed.id)).to be_truthy
      expect(find_partitioned_upload(vulnerability_export_upload_to_be_removed.id)).not_to be_truthy
      expect(find_partitioned_upload(vulnerability_export_upload_synced.id)).to be_truthy

      expect(uploads_table.find_by_id(vulnerability_export_part_upload_to_be_removed.id)).to be_truthy
      expect(find_partitioned_upload(vulnerability_export_part_upload_to_be_removed.id)).not_to be_truthy
      expect(find_partitioned_upload(vulnerability_export_part_upload_synced.id)).to be_truthy

      expect(uploads_table.find_by_id(vulnerability_remediation_upload_to_be_removed.id)).to be_truthy
      expect(find_partitioned_upload(vulnerability_remediation_upload_to_be_removed.id)).not_to be_truthy
      expect(find_partitioned_upload(vulnerability_remediation_upload_synced.id)).to be_truthy

      expect(uploads_table.find_by_id(vulnerability_archive_export_upload_to_be_removed.id)).to be_truthy
      expect(find_partitioned_upload(vulnerability_archive_export_upload_to_be_removed.id)).not_to be_truthy
      expect(find_partitioned_upload(vulnerability_archive_export_upload_synced.id)).to be_truthy

      expect(uploads_table.find_by_id(project_upload_to_be_removed.id)).to be_truthy
      expect(find_partitioned_upload(project_upload_to_be_removed.id)).not_to be_truthy
      expect(find_partitioned_upload(project_upload_synced.id)).to be_truthy

      expect(uploads_table.find_by_id(namespace_upload_to_be_removed.id)).to be_truthy
      expect(find_partitioned_upload(namespace_upload_to_be_removed.id)).not_to be_truthy
      expect(find_partitioned_upload(namespace_upload_synced.id)).to be_truthy

      expect(uploads_table.find_by_id(project_relation_export_upload_upload_to_be_removed.id)).to be_truthy
      expect(find_partitioned_upload(project_relation_export_upload_upload_to_be_removed.id)).not_to be_truthy
      expect(find_partitioned_upload(project_relation_export_upload_upload_synced.id)).to be_truthy

      expect(uploads_table.find_by_id(designs_version_upload_to_be_removed.id)).to be_truthy
      expect(find_partitioned_upload(designs_version_upload_to_be_removed.id)).not_to be_truthy
      expect(find_partitioned_upload(designs_version_upload_synced.id)).to be_truthy

      expect(uploads_table.find_by_id(bulk_import_export_upload_upload_to_be_removed.id)).to be_truthy
      expect(find_partitioned_upload(bulk_import_export_upload_upload_to_be_removed.id)).not_to be_truthy
      expect(find_partitioned_upload(bulk_import_export_upload_upload_synced.id)).to be_truthy

      expect do
        described_class.new(
          start_id: uploads_table.minimum(:id),
          end_id: uploads_table.maximum(:id),
          batch_table: :uploads,
          batch_column: :id,
          sub_batch_size: 100,
          pause_ms: 0,
          connection: connection
        ).perform
      end.not_to raise_error

      expect(find_partitioned_upload(abuse_report_upload_to_be_synced.id)).to be_truthy
      expect(find_partitioned_upload(abuse_report_upload_synced.id)).to be_truthy
      expect(find_partitioned_upload(abuse_report_upload_to_be_removed.id)).not_to be_truthy

      expect(find_partitioned_upload(appearance_upload_to_be_synced.id)).to be_truthy
      expect(find_partitioned_upload(appearance_upload_synced.id)).to be_truthy
      expect(find_partitioned_upload(appearance_upload_to_be_removed.id)).not_to be_truthy

      expect(find_partitioned_upload(achievement_upload_to_be_synced.id).namespace_id)
        .to eq(achievement_1.namespace_id)
      expect(find_partitioned_upload(achievement_upload_synced.id).namespace_id)
        .to eq(achievement_2.namespace_id)
      expect(find_partitioned_upload(achievement_upload_to_be_removed.id)).not_to be_truthy

      expect(find_partitioned_upload(ai_vectorizable_file_upload_to_be_synced.id).project_id)
        .to eq(ai_vectorizable_file_1.project_id)
      expect(find_partitioned_upload(ai_vectorizable_file_upload_synced.id).project_id)
        .to eq(ai_vectorizable_file_2.project_id)
      expect(find_partitioned_upload(ai_vectorizable_file_upload_to_be_removed.id)).not_to be_truthy

      expect(find_partitioned_upload(alert_metric_image_upload_to_be_synced.id).project_id)
        .to eq(alert_metric_image_1.project_id)
      expect(find_partitioned_upload(alert_metric_image_upload_synced.id).project_id)
        .to eq(alert_metric_image_2.project_id)
      expect(find_partitioned_upload(alert_metric_image_upload_to_be_removed.id)).not_to be_truthy

      expect(find_partitioned_upload(dependency_list_export_upload_to_be_synced.id).namespace_id)
        .to eq(dependency_list_export_1.group_id)
      expect(find_partitioned_upload(dependency_list_export_upload_synced.id).namespace_id)
        .to eq(dependency_list_export_2.group_id)
      expect(find_partitioned_upload(dependency_list_export_upload_to_be_removed.id)).not_to be_truthy

      expect(find_partitioned_upload(dependency_list_export_part_upload_to_be_synced.id).organization_id)
        .to eq(dependency_list_export_part_1.organization_id)
      expect(find_partitioned_upload(dependency_list_export_part_upload_synced.id).organization_id)
        .to eq(dependency_list_export_part_2.organization_id)
      expect(find_partitioned_upload(dependency_list_export_part_upload_to_be_removed.id)).not_to be_truthy

      expect(find_partitioned_upload(import_export_upload_upload_to_be_synced.id).namespace_id)
        .to eq(import_export_upload_1.group_id)
      expect(find_partitioned_upload(import_export_upload_upload_synced.id).namespace_id)
        .to eq(import_export_upload_2.group_id)
      expect(find_partitioned_upload(import_export_upload_upload_to_be_removed.id)).not_to be_truthy

      expect(find_partitioned_upload(issuable_metric_image_upload_to_be_synced.id).namespace_id)
        .to eq(issuable_metric_image_1.namespace_id)
      expect(find_partitioned_upload(issuable_metric_image_upload_synced.id).namespace_id)
        .to eq(issuable_metric_image_2.namespace_id)
      expect(find_partitioned_upload(issuable_metric_image_upload_to_be_removed.id)).not_to be_truthy

      expect(find_partitioned_upload(organization_detail_upload_to_be_synced.id).organization_id)
        .to eq(organization_detail_1.organization_id)
      expect(find_partitioned_upload(organization_detail_upload_synced.id).organization_id)
        .to eq(organization_detail_2.organization_id)
      expect(find_partitioned_upload(organization_detail_upload_to_be_removed.id)).not_to be_truthy

      expect(find_partitioned_upload(topic_upload_to_be_synced.id).organization_id).to eq(topic_1.organization_id)
      expect(find_partitioned_upload(topic_upload_synced.id).organization_id).to eq(topic_2.organization_id)
      expect(find_partitioned_upload(topic_upload_to_be_removed.id)).not_to be_truthy

      expect(find_partitioned_upload(snippet_upload_to_be_synced.id).organization_id).to eq(snippet_1.organization_id)
      expect(find_partitioned_upload(snippet_upload_synced.id).organization_id).to eq(snippet_2.organization_id)
      expect(find_partitioned_upload(snippet_upload_to_be_removed.id)).not_to be_truthy

      expect(find_partitioned_upload(user_permission_export_upload_upload_to_be_synced.id)).to be_truthy
      expect(find_partitioned_upload(user_permission_export_upload_upload_synced.id)).to be_truthy
      expect(find_partitioned_upload(user_permission_export_upload_upload_to_be_removed.id)).not_to be_truthy

      expect(find_partitioned_upload(user_upload_to_be_synced.id)).to be_truthy
      expect(find_partitioned_upload(user_upload_synced.id)).to be_truthy
      expect(find_partitioned_upload(user_upload_to_be_removed.id)).not_to be_truthy

      expect(find_partitioned_upload(vulnerability_export_upload_to_be_synced.id).organization_id)
        .to eq(vulnerability_export_1.organization_id)
      expect(find_partitioned_upload(vulnerability_export_upload_synced.id).organization_id)
        .to eq(vulnerability_export_2.organization_id)
      expect(find_partitioned_upload(vulnerability_export_upload_to_be_removed.id)).not_to be_truthy

      expect(find_partitioned_upload(vulnerability_export_part_upload_to_be_synced.id).organization_id)
        .to eq(vulnerability_export_part_1.organization_id)
      expect(find_partitioned_upload(vulnerability_export_part_upload_synced.id).organization_id)
        .to eq(vulnerability_export_part_2.organization_id)
      expect(find_partitioned_upload(vulnerability_export_part_upload_to_be_removed.id)).not_to be_truthy

      expect(find_partitioned_upload(vulnerability_remediation_upload_to_be_synced.id).project_id)
        .to eq(vulnerability_remediation_1.project_id)
      expect(find_partitioned_upload(vulnerability_remediation_upload_synced.id).project_id)
        .to eq(vulnerability_remediation_2.project_id)
      expect(find_partitioned_upload(vulnerability_remediation_upload_to_be_removed.id)).not_to be_truthy

      expect(find_partitioned_upload(vulnerability_archive_export_upload_to_be_synced.id).project_id)
        .to eq(vulnerability_archive_export_1.project_id)
      expect(find_partitioned_upload(vulnerability_archive_export_upload_synced.id).project_id)
        .to eq(vulnerability_archive_export_2.project_id)
      expect(find_partitioned_upload(vulnerability_archive_export_upload_to_be_removed.id)).not_to be_truthy

      expect(find_partitioned_upload(project_upload_to_be_synced.id).project_id).to eq(project_1.id)
      expect(find_partitioned_upload(project_upload_synced.id).project_id).to eq(project_2.id)
      expect(find_partitioned_upload(project_upload_to_be_synced.id).namespace_id).to be_nil
      expect(find_partitioned_upload(project_upload_synced.id).namespace_id).to be_nil
      expect(find_partitioned_upload(project_upload_to_be_removed.id)).not_to be_truthy

      expect(find_partitioned_upload(namespace_upload_to_be_synced.id).namespace_id).to eq(namespace_1.id)
      expect(find_partitioned_upload(namespace_upload_synced.id).namespace_id).to eq(namespace_2.id)
      expect(find_partitioned_upload(namespace_upload_to_be_synced.id).organization_id).to be_nil
      expect(find_partitioned_upload(namespace_upload_synced.id).organization_id).to be_nil
      expect(find_partitioned_upload(namespace_upload_to_be_removed.id)).not_to be_truthy

      expect(find_partitioned_upload(project_relation_export_upload_upload_to_be_synced.id).project_id)
        .to eq(project_relation_export_upload_1.project_id)
      expect(find_partitioned_upload(project_relation_export_upload_upload_synced.id).project_id)
        .to eq(project_relation_export_upload_2.project_id)
      expect(find_partitioned_upload(project_relation_export_upload_upload_to_be_removed.id)).not_to be_truthy

      expect(find_partitioned_upload(designs_version_upload_to_be_synced.id).namespace_id)
        .to eq(designs_version_1.namespace_id)
      expect(find_partitioned_upload(designs_version_upload_synced.id).namespace_id)
        .to eq(designs_version_2.namespace_id)
      expect(find_partitioned_upload(designs_version_upload_to_be_removed.id)).not_to be_truthy

      expect(find_partitioned_upload(bulk_import_export_upload_upload_to_be_synced.id).namespace_id)
        .to eq(bulk_import_export_upload_1.group_id)
      expect(find_partitioned_upload(bulk_import_export_upload_upload_synced.id).namespace_id)
        .to eq(bulk_import_export_upload_2.group_id)
      expect(find_partitioned_upload(bulk_import_export_upload_upload_to_be_removed.id)).not_to be_truthy
    end
  end

  def find_partitioned_upload(id)
    partitioned_uploads_table.find_by_id(id)
  end

  def create_organization
    suffix = SecureRandom.base64
    organizations.create!(name: 'Organization', path: "organization-#{suffix}")
  end

  def create_namespace
    organization = create_organization
    namespaces.create!(
      name: 'gitlab-org',
      path: 'gitlab-org',
      type: 'Group',
      organization_id: organization.id
    )
  end

  def create_project
    namespace = create_namespace
    projects.create!(
      namespace_id: namespace.id,
      organization_id: namespace.organization_id,
      project_namespace_id: namespace.id,
      name: 'Project',
      path: 'project'
    )
  end

  def create_user(organization_id:)
    users.create!(username: SecureRandom.base64, email: "#{SecureRandom.base64}@gitlab.com", projects_limit: 1,
      organization_id: organization_id)
  end

  def create_upload(model_type, model, delete_model: false)
    model_id = Array.wrap(model.id).first
    uploads_table.create!(model_type: model_type, model_id: model_id, size: 42, path: '/some/path',
      uploader: 'FileUploader', created_at: Time.current).tap do
      model.delete if delete_model
    end
  end

  def create_achievement
    namespace = create_namespace
    achievements.create!(namespace_id: namespace.id, name: SecureRandom.base64)
  end

  def create_abuse_report_upload(delete_model: false)
    model = abuse_reports.create!
    create_upload('AbuseReport', model, delete_model: delete_model)
  end

  def create_appearance_upload(delete_model: false)
    model = appearances.create!(title: 'foo', description: 'bar')
    create_upload('Appearance', model, delete_model: delete_model)
  end

  def create_achievement_upload(model: nil, delete_model: false)
    model ||= create_achievement
    create_upload('Achievements::Achievement', model, delete_model: delete_model)
  end

  def create_ai_vectorizable_file
    project = create_project
    ai_vectorizable_files.create!(project_id: project.id, name: 'ai_file', file: 'ai_file')
  end

  def create_ai_vectorizable_file_upload(model: nil, delete_model: false)
    model ||= create_ai_vectorizable_file
    create_upload('Ai::VectorizableFile', model, delete_model: delete_model)
  end

  def create_alert
    project = create_project
    alert_management_alerts.create!(started_at: Time.current, iid: 1, project_id: project.id, title: 'High Alert!')
  end

  def create_alert_metric_image
    alert = create_alert
    alert_management_alert_metric_images.create!(alert_id: alert.id, project_id: alert.project_id, file: 'alert file')
  end

  def create_alert_metric_image_upload(model: nil, delete_model: false)
    model ||= create_alert_metric_image
    create_upload('AlertManagement::MetricImage', model, delete_model: delete_model)
  end

  def create_dependency_list_export
    group = create_namespace
    dependency_list_exports.create!(group_id: group.id)
  end

  def create_dependency_list_export_upload(model: nil, delete_model: false)
    model ||= create_dependency_list_export
    create_upload('Dependencies::DependencyListExport', model, delete_model: delete_model)
  end

  def create_dependency_list_export_part
    organization = create_organization
    dependency_list_export = create_dependency_list_export
    dependency_list_export_parts.create!(organization_id: organization.id,
      dependency_list_export_id: dependency_list_export.id, start_id: 1, end_id: 9)
  end

  def create_dependency_list_export_part_upload(model: nil, delete_model: false)
    model ||= create_dependency_list_export_part
    create_upload('Dependencies::DependencyListExport::Part', model, delete_model: delete_model)
  end

  def create_import_export_upload
    group = create_namespace
    import_export_uploads.create!(group_id: group.id)
  end

  def create_import_export_upload_upload(model: nil, delete_model: false)
    model ||= create_import_export_upload
    create_upload('ImportExportUpload', model, delete_model: delete_model)
  end

  def create_issuable_metric_image
    namespace = create_namespace
    issue_work_item_type_id = table(:work_item_types).find_by(name: 'Issue').id
    issue = table(:issues).create!(
      namespace_id: namespace.id,
      lock_version: 1,
      work_item_type_id: issue_work_item_type_id
    )
    issuable_metric_images.create!(namespace_id: namespace.id, issue_id: issue.id, file: 'some_file')
  end

  def create_issuable_metric_image_upload(model: nil, delete_model: false)
    model ||= create_import_export_upload
    create_upload('IssuableMetricImage', model, delete_model: delete_model)
  end

  def create_organization_detail
    organization = create_organization
    organization_details.create!(organization_id: organization.id)
  end

  def create_organization_detail_upload(model: nil, delete_model: false)
    model ||= create_organization_detail
    create_upload('Organizations::OrganizationDetail', model, delete_model: delete_model)
  end

  def create_topic
    organization = create_organization
    topics.create!(organization_id: organization.id, name: SecureRandom.base64)
  end

  def create_topic_upload(model: nil, delete_model: false)
    model ||= create_topic
    create_upload('Projects::Topic', model, delete_model: delete_model)
  end

  def create_snippet
    organization = create_organization
    user = create_user(organization_id: organization.id)
    snippets.create!(organization_id: organization.id, author_id: user.id)
  end

  def create_snippet_upload(model: nil, delete_model: false)
    model ||= create_snippet
    create_upload('Snippet', model, delete_model: delete_model)
  end

  def create_user_permission_export_upload
    organization = create_organization
    user = create_user(organization_id: organization.id)
    user_permission_export_uploads.create!(user_id: user.id)
  end

  def create_user_permission_export_upload_upload(model: nil, delete_model: false)
    model ||= create_user_permission_export_upload
    create_upload('UserPermissionExportUpload', model, delete_model: delete_model)
  end

  def create_user_upload(model: nil, delete_model: false)
    model ||= begin
      organization = create_organization
      create_user(organization_id: organization.id)
    end
    create_upload('User', model, delete_model: delete_model)
  end

  def create_vulnerability_export
    organization = create_organization
    user = create_user(organization_id: organization.id)
    vulnerability_exports.create!(organization_id: organization.id, author_id: user.id, status: 'open')
  end

  def create_vulnerability_export_upload(model: nil, delete_model: false)
    model ||= create_vulnerability_export
    create_upload('Vulnerabilities::Export', model, delete_model: delete_model)
  end

  def create_vulnerability_export_part
    organization = create_organization
    vulnerability_export = create_vulnerability_export
    vulnerability_export_parts.create!(organization_id: organization.id,
      vulnerability_export_id: vulnerability_export.id, start_id: 1, end_id: 100)
  end

  def create_vulnerability_export_part_upload(model: nil, delete_model: false)
    model ||= create_vulnerability_export_part
    create_upload('Vulnerabilities::Export::Part', model, delete_model: delete_model)
  end

  def create_vulnerability_remediation
    project = create_project
    vulnerability_remediations.create!(project_id: project.id, summary: 'summary', file: 'some_file', checksum: '123')
  end

  def create_vulnerability_remediation_upload(model: nil, delete_model: false)
    model ||= create_vulnerability_remediation
    create_upload('Vulnerabilities::Remediation', model, delete_model: delete_model)
  end

  def create_vulnerability_archive_export
    project = create_project
    user = create_user(organization_id: project.organization_id)
    vulnerability_archive_exports.create!(project_id: project.id, author_id: user.id,
      date_range: Time.current.yesterday..Time.current)
  end

  def create_vulnerability_archive_export_upload(model: nil, delete_model: false)
    model ||= create_vulnerability_archive_export
    create_upload('Vulnerabilities::ArchiveExport', model, delete_model: delete_model)
  end

  def create_project_upload(model: nil, delete_model: false)
    model ||= create_project
    create_upload('Project', model, delete_model: delete_model).tap do |u|
      u.update!(namespace_id: model.namespace_id)
    end
  end

  def create_namespace_upload(model: nil, delete_model: false)
    model ||= create_namespace
    create_upload('Namespace', model, delete_model: delete_model).tap do |u|
      u.update!(organization_id: model.organization_id)
    end
  end

  def create_project_relation_export_upload
    project = create_project
    project_export_job = project_export_jobs.create!(project_id: project.id, jid: SecureRandom.base64)
    project_relation_export = project_relation_exports.create!(project_id: project.id,
      project_export_job_id: project_export_job.id, relation: 'rel')
    project_relation_export_uploads.create!(project_id: project.id,
      project_relation_export_id: project_relation_export.id, export_file: 'export.file')
  end

  def create_project_relation_export_upload_upload(model: nil, delete_model: false)
    model ||= create_project_relation_export_upload
    create_upload('Projects::ImportExport::RelationExportUpload', model, delete_model: delete_model)
  end

  def create_designs_version
    namespace = create_namespace
    project = create_project
    design = design_management_designs.create!(project_id: project.id, namespace_id: namespace.id,
      filename: 'file.name', iid: 1)
    version = design_management_versions.create!(namespace_id: namespace.id, sha: SecureRandom.base64)

    design_management_designs_versions.create!(namespace_id: namespace.id, design_id: design.id, version_id: version.id)
  end

  def create_designs_version_upload(model: nil, delete_model: false)
    model ||= create_designs_version
    create_upload('DesignManagement::Action', model, delete_model: delete_model)
  end

  def create_bulk_import_export
    namespace = create_namespace
    bulk_import_exports.create!(group_id: namespace.id, status: 1, relation: 'rel')
  end

  def create_bulk_import_export_upload
    export = create_bulk_import_export
    bulk_import_export_uploads.create!(export_id: export.id, group_id: export.group_id)
  end

  def create_bulk_import_export_upload_upload(model: nil, delete_model: false)
    model ||= create_bulk_import_export_upload
    create_upload('BulkImports::ExportUpload', model, delete_model: delete_model)
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
