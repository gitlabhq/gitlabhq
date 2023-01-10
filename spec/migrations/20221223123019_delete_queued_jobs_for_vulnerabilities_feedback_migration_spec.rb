# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DeleteQueuedJobsForVulnerabilitiesFeedbackMigration, feature_category: :vulnerability_management do
  let!(:migration) { described_class.new }
  let(:batched_background_migrations) { table(:batched_background_migrations) }

  before do
    batched_background_migrations.create!(
      max_value: 10,
      batch_size: 250,
      sub_batch_size: 50,
      interval: 300,
      job_class_name: 'MigrateVulnerabilitiesFeedbackToVulnerabilitiesStateTransition',
      table_name: 'vulnerability_feedback',
      column_name: 'id',
      job_arguments: [],
      gitlab_schema: "gitlab_main"
    )
  end

  describe "#up" do
    it "deletes all batched migration records" do
      expect(batched_background_migrations.count).to eq(1)

      migration.up

      expect(batched_background_migrations.count).to eq(0)
    end
  end
end
