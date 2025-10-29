# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillPackagesProtectionRules, feature_category: :package_registry do
  describe '#perform' do
    let(:project) do
      organization = table(:organizations).create!(name: "Organization", path: "organization")
      namespace = table(:namespaces).create!(name: 'Test', path: 'test', organization_id: organization.id)
      table(:projects).create!(
        name: 'project',
        path: 'project',
        namespace_id: namespace.id,
        project_namespace_id: namespace.id,
        organization_id: organization.id
      )
    end

    let(:protection_rules) do
      records = Array.new(10).map.with_index do |_, idx|
        {
          project_id: project.id,
          package_name_pattern: "#{package_name_pattern}-#{idx}",
          package_type: 2,
          minimum_access_level_for_delete: 1,
          minimum_access_level_for_push: 2,
          pattern: nil,
          pattern_type: nil,
          target_field: nil
        }
      end

      table(:packages_protection_rules).create!(records)
    end

    let(:connection) { ApplicationRecord.connection }
    let(:package_name_pattern) { '@my_scope/my_package' }

    subject(:perform) do
      described_class.new(
        start_id: protection_rules[0].id,
        end_id: protection_rules[-1].id,
        batch_table: :packages_protection_rules,
        batch_column: :id,
        sub_batch_size: 100,
        pause_ms: 0,
        connection: connection
      ).perform
    end

    around do |example|
      connection.execute("ALTER TABLE packages_protection_rules ALTER COLUMN pattern_type DROP NOT NULL")
      connection.execute("ALTER TABLE packages_protection_rules ALTER COLUMN target_field DROP NOT NULL")

      example.run

      connection.execute("ALTER TABLE packages_protection_rules ALTER COLUMN pattern_type SET NOT NULL")
      connection.execute("ALTER TABLE packages_protection_rules ALTER COLUMN target_field SET NOT NULL")
    end

    before do
      # We need to trigger the creation to let the records created inside `around` block
      protection_rules
    end

    it 'updates package protection rules to have pattern, pattern_type and target_field', :aggregate_failures do
      perform

      expect(protection_rules.map(&:reload)).to all(have_attributes(
        pattern: start_with(package_name_pattern),
        pattern_type: 0,
        target_field: 0
      ))
    end
  end
end
