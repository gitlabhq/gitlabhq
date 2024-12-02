# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillPackagesTagsProjectId,
  feature_category: :package_registry,
  schema: 20231030051837 do # schema before we introduced the invalid not-null constraint
  let!(:organization) { table(:organizations).create!(name: 'my organization', path: 'my-orgainzation') }
  let!(:tags_without_project_id) do
    (0...13).map do |i|
      namespace = table(:namespaces).create!(name: 'my namespace', path: 'my namespace',
        organization_id: organization.id)
      project = table(:projects).create!(name: 'my project', path: 'my project', namespace_id: namespace.id,
        project_namespace_id: namespace.id, organization_id: organization.id)
      package = table(:packages_packages).create!(project_id: project.id, created_at: Time.current,
        updated_at: Time.current, name: "Package #{i}", package_type: 1, status: 1)
      table(:packages_tags).create!(package_id: package.id, name: "Tag #{i}", created_at: Time.current,
        updated_at: Time.current, project_id: nil)
    end
  end

  let!(:starting_id) { table(:packages_tags).pluck(:id).min }
  let!(:end_id) { table(:packages_tags).pluck(:id).max }

  let!(:migration) do
    described_class.new(
      start_id: starting_id,
      end_id: end_id,
      batch_table: :packages_tags,
      batch_column: :id,
      sub_batch_size: 10,
      pause_ms: 2,
      connection: ::ApplicationRecord.connection
    )
  end

  it 'backfills the missing project_id for the batch' do
    expect do
      migration.perform
    end.to change { table(:packages_tags).where(project_id: nil).count }
      .from(13)
      .to(0)
  end
end
