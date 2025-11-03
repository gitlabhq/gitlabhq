# frozen_string_literal: true

require 'spec_helper'
require_relative 'job_shared_examples'

RSpec.describe Gitlab::Database::BackgroundOperation::Job, type: :model, feature_category: :database do
  it_behaves_like 'background operation job functionality', :background_operation_job, :background_operation_worker
end
