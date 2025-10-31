# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Database::BackgroundOperation::CiSchedulerCellLocalWorker, feature_category: :database do
  it_behaves_like 'it schedules background operation workers', :background_operation_worker_cell_local
end
