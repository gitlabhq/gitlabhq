# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Database::BatchedBackgroundMigration::CiDatabaseWorker, :clean_gitlab_redis_shared_state do
  it_behaves_like 'it runs batched background migration jobs', 'ci', feature_flag: :execute_batched_migrations_on_schedule_ci_database
end
