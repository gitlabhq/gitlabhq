# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillCatalogResourceVersionSemVer, feature_category: :pipeline_composition do
  let(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }
  let(:namespace) { table(:namespaces).create!(name: 'name', path: 'path', organization_id: organization.id) }
  let(:project) do
    table(:projects).create!(
      namespace_id: namespace.id,
      project_namespace_id: namespace.id,
      organization_id: organization.id
    )
  end

  let(:resource) { table(:catalog_resources).create!(project_id: project.id) }

  let(:releases_table) { table(:releases) }
  let(:versions_table) { table(:catalog_resource_versions) }

  let(:tag_to_expected_semver) do
    {
      '2.0.5' => [2, 0, 5, nil],
      '1.2.3-alpha' => [1, 2, 3, 'alpha'],
      '4.5.6-beta+12345' => [4, 5, 6, 'beta'],
      '1' => [1, 0, 0, nil],
      'v1.2' => [1, 2, 0, nil],
      '1.3-alpha' => [1, 3, 0, 'alpha'],
      '4.0+123' => [4, 0, 0, nil],
      '0.5-beta+123' => [0, 5, 0, 'beta'],
      '1.2.3.4' => [1, 2, 3, nil],
      'v123.34.5.6-beta' => [123, 34, 5, 'beta'],
      'test-name' => [nil, nil, nil, nil],
      'semver_already_exists' => [2, 1, 0, nil]
    }
  end

  before do
    tag_to_expected_semver.each_key do |tag|
      releases_table.create!(project_id: project.id, tag: tag, released_at: Time.zone.now)
    end

    releases_table.find_each do |release|
      versions_table.create!(release_id: release.id, catalog_resource_id: resource.id, project_id: project.id)
    end

    # Pre-set the semver values for one version to ensure they're not modified by the backfill.
    release = releases_table.find_by(tag: 'semver_already_exists')
    versions_table.find_by(release_id: release.id).update!(semver_major: 2, semver_minor: 1, semver_patch: 0)
  end

  subject(:perform_migration) do
    described_class.new(
      start_id: versions_table.minimum(:id),
      end_id: versions_table.maximum(:id),
      batch_table: :catalog_resource_versions,
      batch_column: :id,
      sub_batch_size: 3,
      pause_ms: 0,
      connection: ActiveRecord::Base.connection
    ).perform
  end

  it 'updates the semver columns with the expected values' do
    perform_migration

    query = versions_table
              .joins('INNER JOIN releases ON releases.id = catalog_resource_versions.release_id')
              .select('catalog_resource_versions.*, releases.tag')

    results = query.each_with_object({}) do |row, obj|
      obj[row.tag] = [row.semver_major, row.semver_minor, row.semver_patch, row.semver_prerelease]
    end

    expect(results).to eq(tag_to_expected_semver)
  end
end
