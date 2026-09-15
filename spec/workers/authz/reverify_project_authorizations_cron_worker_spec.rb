# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authz::ReverifyProjectAuthorizationsCronWorker, feature_category: :permissions do
  let(:worker) { described_class.new }

  it_behaves_like 'an idempotent worker'

  it 'has the `until_executing` deduplicate strategy' do
    expect(described_class.get_deduplicate_strategy).to eq(:until_executing)
  end

  it 'allows at most 5 concurrent executions' do
    expect(described_class.get_concurrency_limit).to eq(5)
  end

  describe '#perform' do
    subject(:perform) { worker.perform }

    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, developers: user) }

    before do
      ProjectAuthorization.where(user: user.id, project: project.id).delete_all
    end

    context 'when a queued user is missing a project authorization' do
      let_it_be(:reverification) do
        create(:project_authorization_reverification, :to_be_processed, user: user)
      end

      it 'restores the project authorization and removes the queued record' do
        expect { perform }
          .to change { authorized? }.from(false).to(true)
          .and change { queued? }.from(true).to(false)
      end

      it 'records the refresh against the safety-net counter' do
        counter = Gitlab::Metrics.counter(:gitlab_authorized_projects_safety_net_refresh_rows_total, 'test')

        allow(Gitlab::Metrics).to receive(:counter).and_call_original
        allow(Gitlab::Metrics).to receive(:counter)
          .with(:gitlab_authorized_projects_safety_net_refresh_rows_total, anything)
          .and_return(counter)

        expect(counter).to receive(:increment)
          .with(hash_including(trigger: described_class.name, direction: 'added'), 1)

        perform
      end

      it 'logs the number of users processed' do
        expect(worker).to receive(:log_extra_metadata_on_done).with(:users_processed, 1)
        expect(worker).to receive(:log_extra_metadata_on_done).with(:queue_drained, true)

        perform
      end
    end

    context 'when a queued user was added less than MIN_AGE ago' do
      let_it_be(:reverification) { create(:project_authorization_reverification, user: user) }

      it 'leaves the record pending without refreshing the user' do
        expect { perform }
          .to not_change { authorized? }.from(false)
          .and not_change { reverification.reload.status }.from('pending')
      end
    end

    context 'when the feature flag `use_db_to_queue_safety_net_auth_refresh` is disabled' do
      let_it_be(:reverification) do
        create(:project_authorization_reverification, :to_be_processed, user: user)
      end

      before do
        stub_feature_flags(use_db_to_queue_safety_net_auth_refresh: false)
      end

      it 'leaves the record pending without refreshing the user' do
        expect { perform }
          .to not_change { authorized? }.from(false)
          .and not_change { reverification.reload.status }.from('pending')
      end
    end

    context 'when a record was abandoned by a previous run' do
      let_it_be(:reverification) do
        create(:project_authorization_reverification, :abandoned, :to_be_processed, user: user)
      end

      it 'reclaims the record, refreshes the user and removes the record' do
        expect { perform }
          .to change { authorized? }.from(false).to(true)
          .and change { queued? }.from(true).to(false)
      end
    end

    context 'when a record is still being processed by another worker' do
      let_it_be(:reverification) do
        create(:project_authorization_reverification, :processing, user: user)
      end

      it 'does not requeue or process the record' do
        expect { perform }.not_to change { reverification.reload.status }.from('processing')
      end
    end

    context 'when refreshing a queued user fails' do
      let_it_be(:reverification) do
        create(:project_authorization_reverification, :to_be_processed, user: user)
      end

      before do
        allow_next_instance_of(Users::RefreshAuthorizedProjectsService) do |service|
          allow(service).to receive(:execute).and_raise(StandardError)
        end
      end

      it 'tracks the error and leaves the record claimed for the abandoned sweep' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception)
          .with(an_instance_of(StandardError), user_id: user.id)

        expect { perform }.to change { reverification.reload.status }.from('pending').to('processing')
      end
    end

    context 'when the runtime limit is reached before the queue is drained' do
      let_it_be(:reverification) do
        create(:project_authorization_reverification, :to_be_processed, user: user)
      end

      before do
        allow_next_instance_of(Gitlab::Metrics::RuntimeLimiter) do |limiter|
          allow(limiter).to receive(:over_time?).and_return(true)
        end
      end

      it 'finishes the claimed batch and reports the queue as not drained' do
        expect(worker).to receive(:log_extra_metadata_on_done).with(:users_processed, 1)
        expect(worker).to receive(:log_extra_metadata_on_done).with(:queue_drained, false)

        expect { perform }.to change { queued? }.from(true).to(false)
      end
    end

    context 'when the queue is empty' do
      it 'reports an empty queue as drained' do
        expect(worker).to receive(:log_extra_metadata_on_done).with(:users_processed, 0)
        expect(worker).to receive(:log_extra_metadata_on_done).with(:queue_drained, true)

        perform
      end
    end

    context 'when the user is re-queued while being processed' do
      let_it_be(:reverification) { create(:project_authorization_reverification, :to_be_processed) }

      before do
        allow_next_instance_of(Gitlab::Metrics::RuntimeLimiter) do |limiter|
          allow(limiter).to receive(:over_time?).and_return(true)
        end
      end

      it 'refreshes the user and keeps the re-queued record' do
        expect_next_instance_of(Users::RefreshAuthorizedProjectsService) do |service|
          expect(service).to receive(:execute) do
            Authz::ProjectAuthorizationReverification.queue_users([reverification.user_id])
          end
        end

        expect { perform }
          .to change { reverification.reload.status }.from('pending').to('requeued')
          .and not_change { queued? }.from(true)
      end
    end

    def authorized?
      ProjectAuthorization.exists?(user_id: user.id, project_id: project.id)
    end

    def queued?
      Authz::ProjectAuthorizationReverification.id_in(reverification.id).exists?
    end
  end
end
