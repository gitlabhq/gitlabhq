# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Database::BackgroundOperation::SecOrchestratorCellLocalWorker,
  :clean_gitlab_redis_shared_state,
  feature_category: :database do
  it_behaves_like 'background operations orchestrator worker'
end
