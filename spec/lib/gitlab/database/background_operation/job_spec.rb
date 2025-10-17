# frozen_string_literal: true

require 'spec_helper'
require_relative 'job_shared_examples'

RSpec.describe Gitlab::Database::BackgroundOperation::Job, type: :model, feature_category: :database do
  it_behaves_like 'background operation job functionality', :background_operation_job, :background_operation_worker

  specify do
    expect(described_class::TIMEOUT_EXCEPTIONS).to contain_exactly(
      ActiveRecord::StatementTimeout,
      ActiveRecord::ConnectionTimeoutError,
      ActiveRecord::AdapterTimeout,
      ActiveRecord::LockWaitTimeout,
      ActiveRecord::QueryCanceled
    )
  end
end
