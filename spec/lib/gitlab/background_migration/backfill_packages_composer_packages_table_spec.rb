# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillPackagesComposerPackagesTable, feature_category: :package_registry do
  let!(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }

  let!(:namespace) do
    table(:namespaces).create!(name: 'group-1', path: 'group-1', type: 'Group', organization_id: organization.id)
  end

  let!(:project) do
    table(:projects).create!(name: 'project 2', path: 'project-1', project_namespace_id: namespace.id,
      namespace_id: namespace.id, organization_id: organization.id)
  end

  let(:timestamp) { Time.current.beginning_of_day }

  let!(:package_1) do
    table(:packages_packages).create!(name: 'test 1', version: '1.0.0', package_type: 6, project_id: project.id,
      created_at: timestamp, updated_at: timestamp)
  end

  let!(:package_2) do
    table(:packages_packages).create!(name: 'test 2', version: '1.0.0', package_type: 6, project_id: project.id,
      created_at: timestamp, updated_at: timestamp)
  end

  let!(:package_1_metadatum) do
    table(:packages_composer_metadata).create!(package_id: package_1.id, project_id: project.id,
      target_sha: SecureRandom.hex(32), composer_json: { 'name' => FFaker::Lorem.word, 'version' => '1.0.1' })
  end

  let!(:starting_id) { table(:packages_packages).minimum(:id) }
  let!(:end_id) { table(:packages_packages).maximum(:id) }

  subject(:migration) do
    described_class.new(
      start_id: starting_id,
      end_id: end_id,
      batch_table: :packages_packages,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: ::ApplicationRecord.connection
    )
  end

  before do
    # Delete all rows from packages_composer_packages inserted with the database triggers
    table(:packages_composer_packages).delete_all
  end

  it 'creates entries in packages_composer_packages table', :aggregate_failures do
    migration.perform

    expect(table(:packages_composer_packages).count).to eq(2)

    composer_package_1 = table(:packages_composer_packages).find(package_1.id)
    composer_package_2 = table(:packages_composer_packages).find(package_2.id)

    expect(composer_package_1.attributes).to eq(
      package_1.attributes.except('package_type').merge(
        package_1_metadatum.attributes.except('package_id')
      )
    )

    expect(composer_package_2.attributes).to include(
      package_2.attributes.except('package_type').merge('composer_json' => {})
    )
  end
end
