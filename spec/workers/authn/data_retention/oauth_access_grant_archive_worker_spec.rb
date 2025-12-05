# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::DataRetention::OauthAccessGrantArchiveWorker, feature_category: :system_access do
  describe '#perform' do
    subject(:worker) { described_class.new }

    let(:cutoff_date) { 1.month.ago.beginning_of_day }

    let_it_be_with_reload(:very_old_revoked_grant) do
      create(:oauth_access_grant, created_at: 3.years.ago, revoked_at: 2.years.ago)
    end

    let_it_be_with_reload(:old_revoked_grant) do
      create(:oauth_access_grant, created_at: 3.months.ago, revoked_at: 2.months.ago)
    end

    let_it_be_with_reload(:old_revoked_grant_after_cutoff) do
      create(:oauth_access_grant,
        created_at: 1.month.ago.beginning_of_day + 1.hour, revoked_at: 1.week.ago)
    end

    let_it_be_with_reload(:recent_revoked_grant) do
      create(:oauth_access_grant, created_at: 2.weeks.ago, revoked_at: 1.week.ago)
    end

    let_it_be_with_reload(:active_grant) do
      create(:oauth_access_grant, revoked_at: nil)
    end

    # The `oauth_access_grant_archived_records` table is only used by the archive jobs. We want to discourage its
    # use throughout the app as it is meant to be a temporary table and will be removed from the codebase soon. Rather
    # than define a full ActiveRecord model with factory and spec, let's just mock a model class for test purposes.
    let(:oauth_access_grant_archived_record_model) do
      Class.new(ApplicationRecord) { self.table_name = 'oauth_access_grant_archived_records' }
    end

    before do
      stub_application_setting(authn_data_retention_cleanup_enabled: true)
    end

    it_behaves_like 'an idempotent worker'

    context 'when application setting is disabled' do
      before do
        stub_application_setting(authn_data_retention_cleanup_enabled: false)
      end

      it 'does not archive any grants' do
        expect { worker.perform }.not_to change { oauth_access_grant_archived_record_model.count }
        expect(OauthAccessGrant.count).to eq(5)
      end

      it 'does not enqueue another job' do
        expect(described_class).not_to receive(:perform_in)
        worker.perform
      end
    end

    context 'when the feature flag :archive_revoked_access_grants is disabled' do
      before do
        stub_feature_flags(archive_revoked_access_grants: false)
      end

      it 'does not archive any grants' do
        expect { worker.perform }.not_to change { oauth_access_grant_archived_record_model.count }
        expect(OauthAccessGrant.count).to eq(5)
      end

      it 'does not enqueue another job' do
        expect(described_class).not_to receive(:perform_in)
        worker.perform
      end
    end

    context 'when the feature flag :archive_revoked_access_grants is enabled', :freeze_time do
      context 'when there are revoked grants to archive' do
        it 'archives only revoked grants created before cutoff date' do
          old_grant_id = old_revoked_grant.id
          very_old_grant_id = very_old_revoked_grant.id

          expect { worker.perform }
            .to change { oauth_access_grant_archived_record_model.count }.by(2)
            .and change { OauthAccessGrant.count }.by(-2)

          expect(oauth_access_grant_archived_record_model.pluck(:id))
            .to contain_exactly(old_grant_id, very_old_grant_id)

          expect(OauthAccessGrant.pluck(:id))
            .to contain_exactly(old_revoked_grant_after_cutoff.id, recent_revoked_grant.id, active_grant.id)
        end

        it 'archives grants exactly at cutoff boundary' do
          grant_at_boundary = create(:oauth_access_grant, revoked_at: cutoff_date, created_at: cutoff_date - 1.month)

          expect { worker.perform }.to change { OauthAccessGrant.exists?(grant_at_boundary.id) }.from(true).to(false)
        end

        it 'logs the sub batch archived count' do
          expect(Gitlab::AppLogger).to receive(:info).with(
            class: described_class.name,
            message: "Archived OAuth grants sub-batch",
            sub_batch_archived: 2,
            cutoff_date: cutoff_date
          )

          worker.perform
        end

        it 'logs the archived count' do
          expect(worker)
            .to receive(:log_extra_metadata_on_done)
                  .with(:result, hash_including(
                    over_time: false,
                    total_archived: 2,
                    cutoff_date: cutoff_date
                  ))

          worker.perform
        end

        it 'preserves all attributes in archived records' do
          original_attributes = old_revoked_grant.attributes

          worker.perform

          archived_record = oauth_access_grant_archived_record_model.find(old_revoked_grant.id)

          expect(archived_record).to have_attributes(
            id: original_attributes['id'],
            resource_owner_id: original_attributes['resource_owner_id'],
            application_id: original_attributes['application_id'],
            token: original_attributes['token'],
            expires_in: original_attributes['expires_in'],
            redirect_uri: original_attributes['redirect_uri'],
            revoked_at: original_attributes['revoked_at'],
            created_at: original_attributes['created_at'],
            scopes: original_attributes['scopes'],
            organization_id: original_attributes['organization_id'],
            code_challenge: original_attributes['code_challenge'],
            code_challenge_method: original_attributes['code_challenge_method']
          )
          expect(archived_record.archived_at).to be_present
        end

        context 'with large batch processing' do
          before do
            stub_const("#{described_class}::BATCH_SIZE", 10)
            stub_const("#{described_class}::SUB_BATCH_SIZE", 5)

            create_list(:oauth_access_grant, 10,
              revoked_at: 2.months.ago,
              created_at: 3.months.ago)
          end

          it 'processes grants in batches' do
            expect(ApplicationRecord.connection)
              .to receive(:execute)
                    .with(a_string_matching(/WITH deleted AS/))
                    .at_least(3).times
                    .and_call_original

            worker.perform

            expect(OauthAccessGrant.where(created_at: ..cutoff_date).count).to eq(0)
          end
        end

        context 'when the runtime limit is reached' do
          before do
            stub_const("#{described_class}::BATCH_SIZE", 4)
            stub_const("#{described_class}::SUB_BATCH_SIZE", 2)

            allow_next_instance_of(Gitlab::Metrics::RuntimeLimiter) do |runtime_limiter|
              allow(runtime_limiter).to receive_messages(over_time?: true, was_over_time?: true)
            end

            create(:oauth_access_grant, created_at: 1.year.ago, revoked_at: 10.months.ago)
          end

          it 'reschedules the worker' do
            expect(described_class).to receive(:perform_in).with(3.minutes, an_instance_of(Integer))
            worker.perform
          end

          it 'stops processing when limit reached' do
            worker.perform

            remaining = OauthAccessGrant.where(revoked_at: ..cutoff_date).count
            expect(remaining).to be 1
          end

          it 'exposes the correct traceability metrics' do
            expect(worker)
              .to receive(:log_extra_metadata_on_done)
                    .with(:result, hash_including(
                      over_time: true,
                      total_archived: 2
                    ))

            worker.perform
          end
        end

        context 'when there is a database error' do
          before do
            allow(ApplicationRecord.connection)
              .to receive(:execute).with(a_string_matching(/WITH deleted AS/))
                                   .and_raise(ActiveRecord::StatementInvalid.new('Failed to execute'))
          end

          it 'skip logs and raises the error' do
            expect(Gitlab::AppLogger).not_to receive(:info)

            expect { worker.perform }.to raise_error(ActiveRecord::StatementInvalid, 'Failed to execute')
          end

          it 'does not partially archive grants' do
            expect { worker.perform }.to raise_error(ActiveRecord::StatementInvalid)

            expect(OauthAccessGrant.count).to eq(5)
            expect(oauth_access_grant_archived_record_model.count).to eq(0)
          end
        end

        context 'when SQL operation is atomic' do
          it 'ensures DELETE and INSERT happen together' do
            # If INSERT fails, DELETE should be rolled back
            allow(ApplicationRecord.connection).to receive(:execute).and_wrap_original do |method, sql|
              raise ActiveRecord::StatementInvalid, 'Insert failed' if sql.include?('INSERT INTO')

              method.call(sql)
            end

            expect { worker.perform }.to raise_error(ActiveRecord::StatementInvalid)

            expect(OauthAccessGrant.find(old_revoked_grant.id)).to be_present
            expect(oauth_access_grant_archived_record_model.count).to eq(0)
          end
        end
      end

      context 'when there are no grants to archive' do
        before do
          OauthAccessGrant.update_all(revoked_at: 1.week.ago)
        end

        it 'does not archive any grants' do
          expect { worker.perform }.not_to change { oauth_access_grant_archived_record_model.count }
        end

        it 'does not enqueue another job' do
          expect(described_class).not_to receive(:perform_in)
          worker.perform
        end

        it 'logs zero archived count' do
          expect(worker).to receive(:log_extra_metadata_on_done).with(:result, hash_including(total_archived: 0))

          worker.perform
        end
      end

      context 'when all grants are active' do
        before do
          OauthAccessGrant.update_all(revoked_at: nil)
        end

        it 'does not process any grants' do
          expect { worker.perform }.not_to change { OauthAccessGrant.count }
          expect(oauth_access_grant_archived_record_model.count).to eq(0)
        end
      end
    end
  end
end
