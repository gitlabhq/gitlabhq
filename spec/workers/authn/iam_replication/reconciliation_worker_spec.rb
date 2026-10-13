# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::IamReplication::ReconciliationWorker, :clean_gitlab_redis_shared_state,
  feature_category: :system_access do
  let_it_be(:applications) do
    create_list(:oauth_application, 2) + [create(:oauth_application, dynamic: true)]
  end

  let(:entity_type) { 'oauth_application' }
  let(:redis_key) { 'authn:iam_replication:reconciliation:last_processed_id:oauth_application' }
  let(:client) { instance_double(Authn::IamService::GrpcClient) }
  let(:upserted_client_ids) { [] }

  subject(:worker) { described_class.new }

  before do
    allow(Authn::IamAuthService).to receive(:enabled?).and_return(true)
    allow(Authn::IamService::GrpcClient).to receive(:new).and_return(client)
    allow(client).to receive(:upsert_oauth_application) { |**attributes| upserted_client_ids << attributes[:client_id] }
  end

  it { is_expected.to be_a(CronjobQueue) }

  it_behaves_like 'worker with data consistency', described_class, data_consistency: :always

  it_behaves_like 'an idempotent worker' do
    let(:job_args) { [entity_type] }
  end

  describe '#perform' do
    it 'upserts every application' do
      worker.perform(entity_type)

      expect(upserted_client_ids).to match_array(applications.map(&:uid))
    end

    it 'does not run a query per application', :use_sql_query_cache do
      control = ActiveRecord::QueryRecorder.new(skip_cached: false) { worker.perform(entity_type) }

      create_list(:oauth_application, 2)

      expect { worker.perform(entity_type) }.not_to exceed_all_query_limit(control)
    end

    it 'resets the last processed id after a complete pass' do
      worker.perform(entity_type)

      expect(Gitlab::Redis::SharedState.with { |redis| redis.get(redis_key) }).to eq('0')
    end

    it 'logs the result' do
      stub_config_cell(id: 1)

      expect(worker).to receive(:log_extra_metadata_on_done)
        .with(:result, hash_including(delivered: 3, entity_type: entity_type, layer: 4, cell_id: 1, over_time: false))

      worker.perform(entity_type)
    end

    context 'when a last processed id is stored' do
      it 'resumes after it' do
        Gitlab::Redis::SharedState.with { |redis| redis.set(redis_key, applications.first.id) }

        worker.perform(entity_type)

        expect(upserted_client_ids).to match_array(applications.drop(1).map(&:uid))
      end

      context 'when it is past the last row' do
        it 'upserts nothing and resets it', :aggregate_failures do
          Gitlab::Redis::SharedState.with { |redis| redis.set(redis_key, applications.last.id) }

          worker.perform(entity_type)

          expect(upserted_client_ids).to be_empty
          expect(Gitlab::Redis::SharedState.with { |redis| redis.get(redis_key) }).to eq('0')
        end
      end
    end

    context 'when the rows of a batch are deleted during the pass' do
      before do
        stub_const("#{described_class}::BATCH_SIZE", 1)

        allow(client).to receive(:upsert_oauth_application) do |**attributes|
          upserted_client_ids << attributes[:client_id]
          Authn::OauthApplication.where(id: applications.drop(1).map(&:id)).delete_all
        end
      end

      it 'skips the empty batch' do
        worker.perform(entity_type)

        expect(upserted_client_ids).to eq([applications.first.uid])
      end
    end

    context 'when the runtime limit is reached' do
      before do
        stub_const("#{described_class}::BATCH_SIZE", 1)

        allow_next_instance_of(Gitlab::Metrics::RuntimeLimiter) do |limiter|
          allow(limiter).to receive_messages(over_time?: true, was_over_time?: true)
        end
      end

      it 'keeps the last processed id and logs over_time', :aggregate_failures do
        expect(worker).to receive(:log_extra_metadata_on_done)
          .with(:result, hash_including(delivered: 1, over_time: true))

        worker.perform(entity_type)

        expect(Gitlab::Redis::SharedState.with { |redis| redis.get(redis_key) }).to eq(applications.first.id.to_s)
      end
    end

    context 'when IAM rejects a row as invalid' do
      let(:error) { Authn::IamService::GrpcClient::RequestError.new('invalid', reason: :invalid_request) }

      before do
        allow(client).to receive(:upsert_oauth_application)
          .with(hash_including(client_id: applications.first.uid)).and_raise(error)
        allow(Gitlab::AuthLogger).to receive(:warn)
      end

      it 'logs the skipped row and upserts the other rows', :aggregate_failures do
        worker.perform(entity_type)

        expect(Gitlab::AuthLogger).to have_received(:warn)
          .with(hash_including('entity_id' => applications.first.id, 'skip_reason' => :invalid_request))
        expect(upserted_client_ids).to match_array(applications.drop(1).map(&:uid))
      end
    end

    context 'when a row has a secret IAM does not accept' do
      before do
        Authn::OauthApplication.where(id: applications.first.id).update_all(secret: '$pbkdf2-sha512$20000$$legacy')
      end

      it 'counts the skipped row and upserts the other rows', :aggregate_failures do
        expect(worker).to receive(:log_extra_metadata_on_done)
          .with(:result, hash_including(delivered: 2, unsupported_secret_digest: 1))

        worker.perform(entity_type)

        expect(upserted_client_ids).to match_array(applications.drop(1).map(&:uid))
      end
    end

    context 'when a row raises an unexpected error' do
      before do
        allow(client).to receive(:upsert_oauth_application)
          .with(hash_including(client_id: applications.first.uid)).and_raise(StandardError)
      end

      it 'tracks the error and upserts the other rows', :aggregate_failures do
        expect(Gitlab::ErrorTracking).to receive(:track_exception)
          .with(an_instance_of(StandardError), entity_type: entity_type, entity_id: applications.first.id)

        worker.perform(entity_type)

        expect(upserted_client_ids).to match_array(applications.drop(1).map(&:uid))
      end
    end

    context 'when IAM is unhealthy' do
      where(:reason) { %i[unavailable unknown] }

      with_them do
        let(:error) { Authn::IamService::GrpcClient::RequestError.new('unhealthy', reason: reason) }

        before do
          stub_const("#{described_class}::BATCH_SIZE", 1)

          allow(client).to receive(:upsert_oauth_application)
            .with(hash_including(client_id: applications.second.uid)).and_raise(error)
        end

        it 'raises and keeps the last processed id at the last complete batch', :aggregate_failures do
          expect { worker.perform(entity_type) }.to raise_error(error)

          expect(Gitlab::Redis::SharedState.with { |redis| redis.get(redis_key) }).to eq(applications.first.id.to_s)
        end

        it 'logs the result of the rows before the error' do
          expect(worker).to receive(:log_extra_metadata_on_done)
            .with(:result, hash_including(delivered: 1, over_time: false))

          expect { worker.perform(entity_type) }.to raise_error(error)
        end
      end
    end

    context 'when iam_data_replication is disabled' do
      before do
        stub_feature_flags(iam_data_replication: false)
      end

      it 'does not upsert' do
        worker.perform(entity_type)

        expect(client).not_to have_received(:upsert_oauth_application)
      end
    end

    context 'when the IAM auth service is disabled' do
      before do
        allow(Authn::IamAuthService).to receive(:enabled?).and_return(false)
      end

      it 'does not upsert' do
        worker.perform(entity_type)

        expect(client).not_to have_received(:upsert_oauth_application)
      end
    end
  end
end
