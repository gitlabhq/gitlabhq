# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Database::BatchedBackgroundMigration::SecDatabaseWorker, :clean_gitlab_redis_shared_state,
  feature_category: :database do
  before do
    skip_if_shared_database(:sec)
  end

  it_behaves_like 'it runs batched background migration jobs', :sec, :vulnerabilities
end
