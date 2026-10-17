# frozen_string_literal: true

RSpec.shared_examples 'refreshes authorizations under the per-user lock' do
  context 'with the per-user refresh lock', :clean_gitlab_redis_shared_state, :clean_gitlab_redis_queues_metadata do
    include ExclusiveLeaseHelpers

    let(:lock_key) { "project_authorizations:user_refresh:#{user.id}" }

    subject(:perform) { described_class.new.perform(*job_args) }

    before_all do
      project.add_developer(user)
      user.project_authorizations.delete_all
    end

    context 'when feature flag `lock_auth_refresh_jobs_per_user` is disabled' do
      before do
        stub_feature_flags(lock_auth_refresh_jobs_per_user: false)
        stub_exclusive_lease_taken(lock_key, timeout: 5.minutes)
      end

      it 'refreshes authorizations even when the lock is held' do
        expect { perform }.to change { user.project_authorizations.reload.size }.by(1)
        expect(described_class.jobs).to be_empty
      end
    end

    context 'when feature flag `lock_auth_refresh_jobs_per_user` is enabled' do
      before do
        stub_feature_flags(lock_auth_refresh_jobs_per_user: user)
      end

      it 'refreshes authorizations and releases the lock' do
        lease = stub_exclusive_lease(lock_key, timeout: 5.minutes)

        expect(lease).to receive(:cancel)
        expect { perform }.to change { user.project_authorizations.reload.size }.by(1)
      end

      context 'when another job holds the lock' do
        before do
          stub_exclusive_lease_taken(lock_key, timeout: 5.minutes)
        end

        it 'does not refresh authorizations' do
          expect { perform }.not_to change { user.project_authorizations.reload.size }
        end

        it 'reschedules itself as a deferred job despite holding its own deduplication key' do
          freeze_time do
            described_class.perform_async(*job_args)

            expect { perform }.to change { described_class.jobs.size }.by(1)

            rescheduled_job = described_class.jobs.last

            expect(rescheduled_job['args']).to eq(job_args)
            expect(rescheduled_job['deferred_by']).to eq('lock_contention')
            expect(rescheduled_job['at']).to eq(20.seconds.from_now.to_f)
          end
        end

        it 'logs the reschedule' do
          expect(Sidekiq.logger).to receive(:info).with(hash_including(
            class: described_class.name,
            message: "Couldn't obtain the lock. Rescheduling the job.",
            job_args: Array(job_args)
          ))

          perform
        end
      end
    end
  end
end
