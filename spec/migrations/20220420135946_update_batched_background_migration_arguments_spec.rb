# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe UpdateBatchedBackgroundMigrationArguments, feature_category: :database do
  let(:batched_migrations) { table(:batched_background_migrations) }

  before do
    common_attributes = {
      max_value: 10,
      batch_size: 5,
      sub_batch_size: 2,
      interval: 2.minutes,
      table_name: 'events',
      column_name: 'id'
    }

    batched_migrations.create!(common_attributes.merge(job_class_name: 'Job1', job_arguments: '[]'))
    batched_migrations.create!(common_attributes.merge(job_class_name: 'Job2', job_arguments: '["some_argument"]'))
    batched_migrations.create!(common_attributes.merge(job_class_name: 'Job3', job_arguments: '[]'))
  end

  describe '#up' do
    it 'updates batched migration arguments to have an empty jsonb array' do
      expect { migrate! }
        .to change { batched_migrations.where("job_arguments = '[]'").count }.from(0).to(2)
        .and change { batched_migrations.where("job_arguments = '\"[]\"'").count }.from(2).to(0)
    end
  end

  describe '#down' do
    before do
      migrate!
    end

    it 'reverts batched migration arguments to have the previous default' do
      expect { schema_migrate_down! }
        .to change { batched_migrations.where("job_arguments = '\"[]\"'").count }.from(0).to(2)
        .and change { batched_migrations.where("job_arguments = '[]'").count }.from(2).to(0)
    end
  end
end
