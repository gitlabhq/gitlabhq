# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::OauthAccessTokenCleanupWorker, feature_category: :system_access do
  describe '#perform' do
    subject(:worker) { described_class.new }

    let_it_be_with_reload(:token_1) { create(:oauth_access_token, created_at: 4.hours.ago) }
    let_it_be_with_reload(:token_2) { create(:oauth_access_token, created_at: 3.hours.ago) }
    let_it_be_with_reload(:token_3) { create(:oauth_access_token, created_at: 3.days.ago) }
    let_it_be_with_reload(:token_4) { create(:oauth_access_token, expires_in: 2.months, created_at: 3.months.ago) }
    let_it_be_with_reload(:live_token) { create(:oauth_access_token, expires_in: 2.months, created_at: 3.hours.ago) }

    it 'deletes expired tokens' do
      expect(OauthAccessToken.count).to eq(5)

      worker.perform

      expect(OauthAccessToken.ids).to contain_exactly(live_token.id)
    end

    it 'exposes traceability metrics' do
      expect(worker).to receive(:log_extra_metadata_on_done).with(:result, { over_time: false, deleted_count: 4 })

      worker.perform
    end

    context 'with FF disabled' do
      before do
        stub_feature_flags(cleanup_access_tokens: false)
      end

      it 'does not clean up tokens' do
        expect { worker.perform }.not_to change { OauthAccessToken.count }
      end
    end

    context 'with batches' do
      before do
        stub_const("#{described_class}::BATCH_SIZE", 5)
        stub_const("#{described_class}::SUB_BATCH_SIZE", 2)
      end

      it 'performs deletes in multiple batches' do
        sql_queries = ActiveRecord::QueryRecorder.new { worker.perform }.log

        delete_statement_count = sql_queries.count { |query| query.start_with?('DELETE FROM "oauth_access_tokens"') }

        expect(delete_statement_count).to eq(3)
        expect(OauthAccessToken.ids).to contain_exactly(live_token.id)
      end

      context 'when no expired records are found in the first sub batch' do
        before do
          [token_1, token_2, token_3].each { |token| token.update!(created_at: 4.minutes.ago) }
        end

        it 'processes subsequent sub batches' do
          worker.perform
          expect(OauthAccessToken.ids).not_to include(4)
        end
      end
    end

    context 'when runtime limit is reached' do
      before do
        stub_const("#{described_class}::BATCH_SIZE", 4)
        stub_const("#{described_class}::SUB_BATCH_SIZE", 2)

        allow_next_instance_of(Gitlab::Metrics::RuntimeLimiter) do |runtime_limiter|
          allow(runtime_limiter).to receive_messages(over_time?: true, was_over_time?: true)
        end

        create(:oauth_access_token, created_at: 3.hours.ago)
      end

      it 'reschedules the worker' do
        expect(described_class).to receive(:perform_in).with(3.minutes).twice
        worker.perform
      end

      it 'does not process any more records' do
        worker.perform
        expect(OauthAccessToken.count).to eq(2)
      end

      it 'exposes the correct traceability metrics' do
        expect(worker).to receive(:log_extra_metadata_on_done).with(:result, { over_time: true, deleted_count: 4 })

        worker.perform
      end
    end
  end
end
