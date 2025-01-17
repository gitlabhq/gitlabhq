# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FinalizeMigrateSoftwareLicenseWithoutSpdxIdentifierToCustomLicenses, feature_category: :security_policy_management do
  it 'finalizes FinalizeMigrateRemainingSoftwareLicenseWithoutSpdxIdentifierToCustomLicenses migration' do
    expect_next_instance_of(described_class) do |instance|
      expect(instance).to receive(:ensure_batched_background_migration_is_finished).with(
        job_class_name: 'MigrateRemainingSoftwareLicenseWithoutSpdxIdentifierToCustomLicenses',
        table_name: :software_license_policies,
        column_name: :id,
        job_arguments: [],
        finalize: true
      )
    end

    migrate!
  end
end
