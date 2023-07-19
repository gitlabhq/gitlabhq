# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FinalizeUserTypeMigration, feature_category: :devops_reports do
  it 'finalizes MigrateHumanUserType migration' do
    expect_next_instance_of(described_class) do |instance|
      expect(instance).to receive(:ensure_batched_background_migration_is_finished).with(
        job_class_name: 'MigrateHumanUserType',
        table_name: :users,
        column_name: :id,
        job_arguments: []
      )
    end

    migrate!
  end
end
