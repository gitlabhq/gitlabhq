# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WebHooks::LogExecutionWorker, feature_category: :webhooks do
  it_behaves_like 'worker with data consistency', described_class, data_consistency: :delayed
end
