# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Database::BatchedBackgroundMigration::SecExecutionWorker,
  :clean_gitlab_redis_shared_state,
  feature_category: :database do
    it_behaves_like 'batched background migrations execution worker'
  end
