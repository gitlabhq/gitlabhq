# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UserProjectAccessChangedService, feature_category: :system_access do
  describe '#execute' do
    it 'permits high-priority operation' do
      expect(AuthorizedProjectsWorker).to receive(:bulk_perform_async)
        .with([[1], [2]])

      described_class.new([1, 2]).execute
    end

    context 'for low priority operation' do
      context 'when the feature flag `do_not_run_safety_net_auth_refresh_jobs` is disabled' do
        before do
          stub_feature_flags(do_not_run_safety_net_auth_refresh_jobs: false)
        end

        it 'permits low-priority operation' do
          expect(AuthorizedProjectUpdate::UserRefreshFromReplicaWorker).to(
            receive(:bulk_perform_in).with(
              described_class::DELAY,
              [[1], [2]],
              { batch_delay: 30.seconds, batch_size: 100 }
            )
          )

          described_class.new([1, 2]).execute(priority: described_class::LOW_PRIORITY)
        end
      end

      it 'does not perform low-priority operation' do
        expect(AuthorizedProjectUpdate::UserRefreshFromReplicaWorker).not_to receive(:bulk_perform_in)

        described_class.new([1, 2]).execute(priority: described_class::LOW_PRIORITY)
      end
    end

    it 'permits medium-priority operation' do
      expect(AuthorizedProjectUpdate::UserRefreshWithLowUrgencyWorker).to(
        receive(:bulk_perform_in).with(
          1.minute,
          [[1], [2]],
          { batch_delay: 30.seconds, batch_size: 100 }
        )
      )

      described_class.new([1, 2]).execute(priority: described_class::MEDIUM_PRIORITY)
    end

    it 'sets the current caller_id as related_class in the context of all the enqueued jobs' do
      Gitlab::ApplicationContext.with_context(caller_id: 'Foo') do
        described_class.new([1, 2]).execute(priority: described_class::LOW_PRIORITY)
      end

      expect(AuthorizedProjectUpdate::UserRefreshFromReplicaWorker.jobs).to all(
        include(Labkit::Context.log_key(:related_class) => 'Foo')
      )
    end
  end

  context 'with load balancing enabled' do
    let(:service) { described_class.new([1, 2]) }

    before do
      expect(AuthorizedProjectsWorker).to receive(:bulk_perform_async)
                                            .with([[1], [2]])
                                            .and_return(10)
    end

    it 'sticks all the updated users and returns the original result', :aggregate_failures do
      expect(ApplicationRecord.sticking).to receive(:bulk_stick).with(:user, [1, 2])

      expect(service.execute).to eq(10)
    end

    it 'avoids N+1 cached queries', :use_sql_query_cache, :request_store do
      # Run this once to establish a baseline
      control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        service.execute
      end

      service = described_class.new([1, 2, 3, 4, 5])

      allow(AuthorizedProjectsWorker).to receive(:bulk_perform_async)
                                            .with([[1], [2], [3], [4], [5]])
                                            .and_return(10)

      expect { service.execute }.not_to exceed_all_query_limit(control)
    end
  end
end
