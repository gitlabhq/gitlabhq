# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Database::BatchedBackgroundMigration::CiDatabaseWorker, :clean_gitlab_redis_shared_state,
  feature_category: :database do
  it_behaves_like 'it runs batched background migration jobs', :ci, :ci_builds
end
