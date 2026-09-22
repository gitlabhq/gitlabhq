# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UserProjectAccessChangedService, feature_category: :system_access do
  describe '#execute' do
    let_it_be(:users) { create_list(:user, 2) }
    let_it_be(:user_ids) { users.map(&:id) }

    subject(:execute) { described_class.new(user_ids).execute(priority: priority) }

    context 'for high priority operation' do
      let(:priority) { described_class::HIGH_PRIORITY }

      it 'permits high-priority operation' do
        expect(AuthorizedProjectsWorker).to receive(:bulk_perform_async)
          .with(user_ids.map { |id| [id] })

        execute
      end

      it 'sticks all the updated users' do
        expect(ApplicationRecord.sticking).to receive(:bulk_stick).with(:user, user_ids)

        execute
      end
    end

    context 'for low priority operation' do
      let(:priority) { described_class::LOW_PRIORITY }

      it 'does not stick the updated users' do
        expect(ApplicationRecord.sticking).not_to receive(:bulk_stick)

        execute
      end

      context 'when the feature flag `do_not_run_safety_net_auth_refresh_jobs` is enabled' do
        before do
          stub_feature_flags(do_not_run_safety_net_auth_refresh_jobs: true)
        end

        it 'does not queue users for reverification' do
          expect { execute }.not_to change { Authz::ProjectAuthorizationReverification.count }
        end

        it 'does not enqueue safety net jobs' do
          expect(AuthorizedProjectUpdate::UserRefreshFromReplicaWorker).not_to receive(:bulk_perform_in)

          execute
        end
      end

      context 'when the feature flag `do_not_run_safety_net_auth_refresh_jobs` is disabled' do
        before do
          stub_feature_flags(do_not_run_safety_net_auth_refresh_jobs: false)
        end

        context 'when the feature flag `use_db_to_queue_safety_net_auth_refresh` is enabled' do
          it 'queues the users for reverification' do
            expect { execute }
              .to change { Authz::ProjectAuthorizationReverification.where(user: users).count }.by(2)
          end

          it 'does not enqueue safety net jobs' do
            expect(AuthorizedProjectUpdate::UserRefreshFromReplicaWorker).not_to receive(:bulk_perform_in)

            execute
          end
        end

        context 'when the feature flag `use_db_to_queue_safety_net_auth_refresh` is enabled for some of the users',
          :clean_gitlab_redis_queues do
          let_it_be(:enabled_user) { create(:user) }
          let_it_be(:disabled_user) { create(:user) }
          let_it_be(:user_ids) { [enabled_user.id, disabled_user.id] }

          before do
            stub_feature_flags(use_db_to_queue_safety_net_auth_refresh: enabled_user)
          end

          it 'queues the enabled users and enqueues safety net jobs for the rest' do
            execute

            expect(Authz::ProjectAuthorizationReverification.pluck(:user_id)).to contain_exactly(enabled_user.id)
            expect(AuthorizedProjectUpdate::UserRefreshFromReplicaWorker.jobs.pluck('args'))
              .to contain_exactly([disabled_user.id])
          end

          it 'does not query users to check the feature flag', :use_sql_query_cache, :request_store do
            control = ActiveRecord::QueryRecorder.new(skip_cached: false) { execute }

            more_users = create_list(:user, 3)
            stub_feature_flags(use_db_to_queue_safety_net_auth_refresh: [enabled_user, *more_users])

            expect { described_class.new([*user_ids, *more_users.map(&:id)]).execute(priority: priority) }
              .not_to exceed_all_query_limit(control)
          end
        end

        context 'when the feature flag `use_db_to_queue_safety_net_auth_refresh` is disabled' do
          before do
            stub_feature_flags(use_db_to_queue_safety_net_auth_refresh: false)
          end

          it 'does not queue users for reverification' do
            expect { execute }.not_to change { Authz::ProjectAuthorizationReverification.count }
          end

          it 'enqueues safety net jobs' do
            expect(AuthorizedProjectUpdate::UserRefreshFromReplicaWorker).to(
              receive(:bulk_perform_in).with(
                described_class::DELAY,
                user_ids.map { |id| [id] },
                { batch_delay: 30.seconds, batch_size: 100 }
              )
            )

            execute
          end

          it 'sets the current caller_id as related_class in the context of all the enqueued jobs' do
            Gitlab::ApplicationContext.with_context(caller_id: 'Foo') do
              execute
            end

            expect(AuthorizedProjectUpdate::UserRefreshFromReplicaWorker.jobs).to all(
              include(Labkit::Context.log_key(:related_class) => 'Foo')
            )
          end

          it 'tags jobs with the safety-net refresh purpose' do
            execute

            expect(AuthorizedProjectUpdate::UserRefreshFromReplicaWorker.jobs).to all(
              include(
                Labkit::Context.log_key(:authorized_projects_refresh_purpose) =>
                  described_class::SAFETY_NET_REFRESH_PURPOSE
              )
            )
          end
        end
      end
    end

    context 'for medium priority operation' do
      let(:priority) { described_class::MEDIUM_PRIORITY }

      it 'permits medium-priority operation' do
        expect(AuthorizedProjectUpdate::UserRefreshWithLowUrgencyWorker).to(
          receive(:bulk_perform_in).with(
            1.minute,
            user_ids.map { |id| [id] },
            { batch_delay: 30.seconds, batch_size: 100 }
          )
        )

        execute
      end

      it 'does not stick the updated users' do
        expect(ApplicationRecord.sticking).not_to receive(:bulk_stick)

        execute
      end
    end
  end

  context 'with load balancing enabled' do
    let(:service) { described_class.new([1, 2]) }

    before do
      expect(AuthorizedProjectsWorker).to receive(:bulk_perform_async)
                                            .with([[1], [2]])
                                            .and_return(10)
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
