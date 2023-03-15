# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BackgroundMigration::CiDatabaseWorker, :clean_gitlab_redis_shared_state, if: Gitlab::Database.has_config?(:ci), feature_category: :database do
  it_behaves_like 'it runs background migration jobs', 'ci'
end
