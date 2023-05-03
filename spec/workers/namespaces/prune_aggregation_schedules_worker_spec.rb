# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::PruneAggregationSchedulesWorker, '#perform', :clean_gitlab_redis_shared_state, feature_category: :source_code_management do
  include ExclusiveLeaseHelpers

  let(:namespaces) { create_list(:namespace, 5, :with_aggregation_schedule) }

  subject(:worker) { described_class.new }

  before do
    allow(Namespaces::RootStatisticsWorker)
      .to receive(:perform_async).and_return(nil)

    allow(Namespaces::RootStatisticsWorker)
      .to receive(:perform_in).and_return(nil)

    namespaces.each do |namespace|
      lease_key = "namespace:namespaces_root_statistics:#{namespace.id}"
      stub_exclusive_lease(lease_key, timeout: namespace.aggregation_schedule.default_lease_timeout)
    end
  end

  it 'schedules a worker per pending aggregation' do
    expect(Namespaces::RootStatisticsWorker)
      .to receive(:perform_async).exactly(5).times

    expect(Namespaces::RootStatisticsWorker)
      .to receive(:perform_in).exactly(5).times

    worker.perform
  end
end
