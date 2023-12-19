# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BackgroundMigration::CiDatabaseWorker, :clean_gitlab_redis_shared_state,
  feature_category: :database do
  before do
    skip_if_shared_database(:ci)
  end

  it_behaves_like 'it runs background migration jobs', 'ci'
end
