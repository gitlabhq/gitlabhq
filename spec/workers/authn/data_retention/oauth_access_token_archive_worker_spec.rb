# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::DataRetention::OauthAccessTokenArchiveWorker, feature_category: :system_access do
  describe '#perform' do
    subject(:worker) { described_class.new }

    let(:cutoff_date) { OauthAccessToken::RETENTION_PERIOD.ago.beginning_of_day }

    let_it_be_with_reload(:very_old_revoked_token) do
      create(:oauth_access_token, created_at: 3.years.ago, revoked_at: 2.years.ago)
    end

    let_it_be_with_reload(:old_revoked_token) do
      create(:oauth_access_token, created_at: 3.months.ago, revoked_at: 2.months.ago)
    end

    let_it_be_with_reload(:old_revoked_token_after_cutoff) do
      create(:oauth_access_token,
        created_at: 1.month.ago.beginning_of_day + 1.hour, revoked_at: 1.week.ago)
    end

    let_it_be_with_reload(:recent_revoked_token) do
      create(:oauth_access_token, created_at: 2.weeks.ago, revoked_at: 1.week.ago)
    end

    let_it_be_with_reload(:active_token) do
      create(:oauth_access_token, revoked_at: nil)
    end

    before do
      stub_application_setting(authn_data_retention_cleanup_enabled: true)
    end

    it_behaves_like 'an idempotent worker'

    context 'when application setting is disabled' do
      before do
        stub_application_setting(authn_data_retention_cleanup_enabled: false)
      end

      it 'does not delete any tokens' do
        expect { worker.perform }.not_to change { OauthAccessToken.count }
        expect(OauthAccessToken.count).to eq(5)
      end

      it 'does not enqueue another job' do
        expect(described_class).not_to receive(:perform_in)
        worker.perform
      end
    end

    context 'when the feature flag :archive_revoked_access_tokens is disabled' do
      before do
        stub_feature_flags(archive_revoked_access_tokens: false)
      end

      it 'does not delete any tokens' do
        expect { worker.perform }.not_to change { OauthAccessToken.count }
        expect(OauthAccessToken.count).to eq(5)
      end

      it 'does not enqueue another job' do
        expect(described_class).not_to receive(:perform_in)
        worker.perform
      end
    end

    context 'when the feature flag :archive_revoked_access_tokens is enabled', :freeze_time do
      context 'when there are revoked tokens to delete' do
        it 'deletes only revoked tokens created before cutoff date' do
          expect { worker.perform }.to change { OauthAccessToken.count }.by(-2)

          expect(OauthAccessToken.pluck(:id))
            .to contain_exactly(old_revoked_token_after_cutoff.id, recent_revoked_token.id, active_token.id)
        end

        it 'deletes tokens exactly at cutoff boundary' do
          token_at_boundary = create(:oauth_access_token, revoked_at: cutoff_date, created_at: cutoff_date - 1.month)

          expect { worker.perform }.to change { OauthAccessToken.exists?(token_at_boundary.id) }.from(true).to(false)
        end

        it 'logs the sub batch deletion count' do
          expect(Gitlab::AppLogger).to receive(:info).with(
            class: described_class.name,
            message: "Deleted OAuth tokens sub-batch",
            sub_batch_deleted: 2,
            cutoff_date: cutoff_date
          )

          worker.perform
        end

        it 'logs the total deleted count' do
          expect(worker)
            .to receive(:log_extra_metadata_on_done)
                  .with(:result, hash_including(
                    over_time: false,
                    total_deleted: 2,
                    cutoff_date: cutoff_date
                  ))

          worker.perform
        end

        context 'with large batch processing' do
          before do
            stub_const("#{described_class}::BATCH_SIZE", 10)
            stub_const("#{described_class}::SUB_BATCH_SIZE", 5)

            create_list(:oauth_access_token, 10,
              revoked_at: 2.months.ago,
              created_at: 3.months.ago)
          end

          it 'processes tokens in batches' do
            expect(worker).to receive(:log_sub_batch_deleted)
                                .at_least(3).times
                                .and_call_original

            worker.perform

            expect(OauthAccessToken.where(created_at: ..cutoff_date).count).to eq(0)
          end
        end

        context 'when the runtime limit is reached' do
          before do
            stub_const("#{described_class}::BATCH_SIZE", 4)
            stub_const("#{described_class}::SUB_BATCH_SIZE", 2)

            allow_next_instance_of(Gitlab::Metrics::RuntimeLimiter) do |runtime_limiter|
              allow(runtime_limiter).to receive_messages(over_time?: true, was_over_time?: true)
            end

            create(:oauth_access_token, created_at: 1.year.ago, revoked_at: 10.months.ago)
          end

          it 'reschedules the worker' do
            expect(described_class).to receive(:perform_in).with(3.minutes, an_instance_of(Integer))
            worker.perform
          end

          it 'stops processing when limit reached' do
            worker.perform

            remaining = OauthAccessToken.where(revoked_at: ..cutoff_date).count
            expect(remaining).to be 1
          end

          it 'exposes the correct traceability metrics' do
            expect(worker)
              .to receive(:log_extra_metadata_on_done)
                    .with(:result, hash_including(
                      over_time: true,
                      total_deleted: 2
                    ))

            worker.perform
          end
        end

        context 'when there is a database error' do
          before do
            # rubocop:disable RSpec/AnyInstanceOf -- each_batch creates multiple Relation instances that need stubbing
            allow_any_instance_of(ActiveRecord::Relation)
              .to receive(:delete_all)
                    .and_raise(ActiveRecord::StatementInvalid.new('Failed to execute'))
            # rubocop:enable RSpec/AnyInstanceOf
          end

          it 'skip logs and raises the error' do
            expect(Gitlab::AppLogger).not_to receive(:info)

            expect { worker.perform }.to raise_error(ActiveRecord::StatementInvalid, 'Failed to execute')
          end

          it 'does not partially delete tokens' do
            expect { worker.perform }.to raise_error(ActiveRecord::StatementInvalid)

            expect(OauthAccessToken.count).to eq(5)
          end
        end
      end

      context 'when there are no tokens to delete' do
        before do
          OauthAccessToken.update_all(revoked_at: 1.week.ago)
        end

        it 'does not delete any tokens' do
          expect { worker.perform }.not_to change { OauthAccessToken.count }
        end

        it 'does not enqueue another job' do
          expect(described_class).not_to receive(:perform_in)
          worker.perform
        end

        it 'logs zero deleted count' do
          expect(worker).to receive(:log_extra_metadata_on_done).with(:result, hash_including(total_deleted: 0))

          worker.perform
        end
      end

      context 'when all tokens are active' do
        before do
          OauthAccessToken.update_all(revoked_at: nil)
        end

        it 'does not process any tokens' do
          expect { worker.perform }.not_to change { OauthAccessToken.count }
        end
      end
    end
  end
end
