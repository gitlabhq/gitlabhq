# frozen_string_literal: true

require 'spec_helper'
require_relative 'worker_shared_examples'

RSpec.describe Gitlab::Database::BackgroundOperation::WorkerCellLocal, type: :model, feature_category: :database do
  it_behaves_like 'background operation worker functionality',
    :background_operation_worker_cell_local,
    :background_operation_job_cell_local
end
