# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddGitlabSchemaToBatchedBackgroundMigrations, feature_category: :database do
  it 'sets gitlab_schema for existing methods to "gitlab_main" and default to NULL' do
    batched_migrations = table(:batched_background_migrations)
    batched_migration = batched_migrations.create!(
      id: 1, created_at: Time.now, updated_at: Time.now,
      max_value: 100, batch_size: 100, sub_batch_size: 10, interval: 120,
      job_class_name: 'TestJob', table_name: '_test', column_name: 'id'
    )

    reversible_migration do |migration|
      migration.before -> {
        batched_migrations.reset_column_information
        column = batched_migrations.columns.find { |column| column.name == 'gitlab_schema' }

        expect(column).to be_nil
      }

      migration.after -> {
        expect(batched_migration.reload.gitlab_schema).to eq('gitlab_main')

        batched_migrations.reset_column_information
        column = batched_migrations.columns.find { |column| column.name == 'gitlab_schema' }

        expect(column).to be
        expect(column.default).to be_nil
      }
    end
  end
end
