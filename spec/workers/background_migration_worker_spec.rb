# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BackgroundMigrationWorker, :clean_gitlab_redis_shared_state,
  feature_category: :database do
  it_behaves_like 'it runs background migration jobs', 'main'
end
