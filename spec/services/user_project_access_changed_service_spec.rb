# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UserProjectAccessChangedService do
  describe '#execute' do
    it 'schedules the user IDs' do
      expect(AuthorizedProjectsWorker).to receive(:bulk_perform_and_wait)
        .with([[1], [2]])

      described_class.new([1, 2]).execute
    end

    it 'permits non-blocking operation' do
      expect(AuthorizedProjectsWorker).to receive(:bulk_perform_async)
        .with([[1], [2]])

      described_class.new([1, 2]).execute(blocking: false)
    end

    it 'permits low-priority operation' do
      expect(AuthorizedProjectUpdate::UserRefreshFromReplicaWorker).to(
        receive(:bulk_perform_in).with(
          described_class::DELAY,
          [[1], [2]],
          { batch_delay: 30.seconds, batch_size: 100 }
        )
      )

      described_class.new([1, 2]).execute(blocking: false,
                                          priority: described_class::LOW_PRIORITY)
    end

    it 'sets the current caller_id as related_class in the context of all the enqueued jobs' do
      Gitlab::ApplicationContext.with_context(caller_id: 'Foo') do
        described_class.new([1, 2]).execute(blocking: false,
                                            priority: described_class::LOW_PRIORITY)
      end

      expect(AuthorizedProjectUpdate::UserRefreshFromReplicaWorker.jobs).to all(
        include(Labkit::Context.log_key(:related_class) => 'Foo')
      )
    end
  end

  context 'with load balancing enabled' do
    let(:service) { UserProjectAccessChangedService.new([1, 2]) }

    before do
      allow(Gitlab::Database::LoadBalancing).to receive(:enable?).and_return(true)

      expect(AuthorizedProjectsWorker).to receive(:bulk_perform_and_wait)
                                            .with([[1], [2]])
                                            .and_return(10)
    end

    it 'sticks all the updated users and returns the original result', :aggregate_failures do
      expect(Gitlab::Database::LoadBalancing::Sticking).to receive(:bulk_stick).with(:user, [1, 2])

      expect(service.execute).to eq(10)
    end

    it 'avoids N+1 cached queries', :use_sql_query_cache, :request_store do
      # Run this once to establish a baseline
      control_count = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        service.execute
      end

      service = UserProjectAccessChangedService.new([1, 2, 3, 4, 5])

      allow(AuthorizedProjectsWorker).to receive(:bulk_perform_and_wait)
                                            .with([[1], [2], [3], [4], [5]])
                                            .and_return(10)

      expect { service.execute }.not_to exceed_all_query_limit(control_count.count)
    end
  end
end
