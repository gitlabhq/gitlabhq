# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::IamReplication::DrainWorker, feature_category: :system_access do
  let_it_be(:application) { create(:oauth_application) }

  let(:entity_type) { 'oauth_application' }

  let(:replicator) do
    instance_double(Authn::IamReplication::OauthApplicationReplicator, deliver: :delivered)
  end

  subject(:worker) { described_class.new }

  # The feature flag is enabled by default in tests, so delete all the outbox row produced by the
  # initial `application` creation
  before do
    Authn::IamOutbox.delete_all
    allow(::Authn::IamAuthService).to receive(:enabled?).and_return(true)
    allow(Authn::IamReplication::OauthApplicationReplicator).to receive(:new).and_return(replicator)
  end

  def upsert_row(entity_id: application.id)
    create(:iam_outbox, entity_type: entity_type, entity_id: entity_id, event_type: :upsert)
  end

  def delete_row(entity_id: application.id, uid: 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6')
    create(:iam_outbox,
      entity_type: entity_type, entity_id: entity_id, event_type: :delete, payload: { 'uid' => uid })
  end

  it_behaves_like 'worker with data consistency', described_class, data_consistency: :sticky

  it_behaves_like 'an idempotent worker' do
    let(:job_args) { [entity_type, application.id, 'upsert'] }

    before do
      upsert_row
    end

    it 'delivers once across repeated runs and marks the row delivered' do
      perform_idempotent_work

      expect(replicator).to have_received(:deliver).once
      expect(Authn::IamOutbox.sole.l0_delivered_at).to be_present
    end
  end

  describe '#perform' do
    context 'with an upsert event' do
      it 'delegates the row to the replicator and marks the L0 target delivered' do
        row = upsert_row

        worker.perform(entity_type, application.id, 'upsert')

        expect(replicator).to have_received(:deliver).with(row)
        expect(row.reload.l0_delivered_at).to be_present
      end

      it 'logs the delivery' do
        upsert_row

        expect(::Gitlab::AuthLogger).to receive(:info).with(
          hash_including(
            'message' => 'IAM outbox row delivery',
            'layer' => 3,
            'entity_type' => entity_type,
            'entity_id' => application.id,
            'event_type' => 'upsert',
            'target' => described_class::TARGET,
            'attempts' => 0,
            'result' => :delivered
          )
        )

        worker.perform(entity_type, application.id, 'upsert')
      end

      context 'when the replicator reports the record as skipped' do
        before do
          allow(replicator).to receive(:deliver).and_return(:skipped)
        end

        it 'logs the skipped delivery' do
          upsert_row

          expect(::Gitlab::AuthLogger).to receive(:info).with(hash_including('result' => :skipped))

          worker.perform(entity_type, application.id, 'upsert')
        end
      end
    end

    context 'with a delete event' do
      it 'delegates the row to the replicator and marks L0 delivered' do
        row = delete_row

        worker.perform(entity_type, application.id, 'delete')

        expect(replicator).to have_received(:deliver).with(row)
        expect(row.reload.l0_delivered_at).to be_present
      end
    end

    context 'when the replicator raises a RequestError' do
      before do
        allow(replicator).to receive(:deliver)
          .and_raise(Authn::IamService::GrpcClient::RequestError.new(
            'IAM auth service is not configured', reason: :unavailable))
      end

      it 'records the gRPC reason, leaves the target undelivered, and re-raises for retry',
        :aggregate_failures do
        row = upsert_row

        expect { worker.perform(entity_type, application.id, 'upsert') }
          .to raise_error(Authn::IamService::GrpcClient::RequestError, 'IAM auth service is not configured')

        row.reload
        expect(row.l0_attempts).to eq(1)
        expect(row.l0_last_error).to eq('unavailable')
        expect(row.l0_delivered_at).to be_nil
      end

      it 'logs the failure with the incremented attempt count' do
        upsert_row

        expect(::Gitlab::AuthLogger).to receive(:info)
          .with(hash_including('result' => :error, 'attempts' => 1))

        expect { worker.perform(entity_type, application.id, 'upsert') }
          .to raise_error(Authn::IamService::GrpcClient::RequestError)
      end
    end

    context 'when the replicator raises something other than a RequestError' do
      before do
        allow(replicator).to receive(:deliver).and_raise(ArgumentError)
      end

      it 'falls back to the class name, since only a RequestError carries a reason', :aggregate_failures do
        row = upsert_row

        expect { worker.perform(entity_type, application.id, 'upsert') }.to raise_error(ArgumentError)

        row.reload
        expect(row.l0_attempts).to eq(1)
        expect(row.l0_last_error).to eq('ArgumentError')
        expect(row.l0_delivered_at).to be_nil
      end
    end

    context 'with an unknown event_type' do
      it 'raises and leaves the row undelivered' do
        row = upsert_row

        expect { worker.perform(entity_type, application.id, 'unknown') }
          .to raise_error(ArgumentError, /unknown event_type/)

        expect(row.reload.l0_delivered_at).to be_nil
      end
    end

    context 'with several undelivered rows for the same entity' do
      before do
        3.times { upsert_row }
      end

      it 'collapses them into a single delivery and marks them all delivered', :aggregate_failures do
        worker.perform(entity_type, application.id, 'upsert')

        expect(replicator).to have_received(:deliver).once
        expect(Authn::IamOutbox.l0_undelivered).to be_empty
      end

      it 'leaves every row undelivered for retry when delivery fails', :aggregate_failures do
        allow(replicator).to receive(:deliver)
          .and_raise(Authn::IamService::GrpcClient::RequestError.new(
            'IAM auth service is not configured', reason: :unavailable))

        expect { worker.perform(entity_type, application.id, 'upsert') }
          .to raise_error(Authn::IamService::GrpcClient::RequestError)

        expect(Authn::IamOutbox.l0_undelivered.count).to eq(3)
        expect(Authn::IamOutbox.pluck(:l0_attempts)).to all(eq(1))
      end

      # The id set is pinned before delivery, so a row written mid-delivery isn't in it.
      it 'leaves a row written after the delivery read pending for its own drain' do
        allow(replicator).to receive(:deliver) do |_row|
          upsert_row
          :delivered
        end

        worker.perform(entity_type, application.id, 'upsert')

        expect(Authn::IamOutbox.l0_undelivered.count).to eq(1)
      end
    end

    context 'when the feature flag is disabled' do
      before do
        stub_feature_flags(iam_data_replication: false)
      end

      it 'is a no-op and never builds a replicator' do
        row = upsert_row
        expect(Authn::IamReplication::OauthApplicationReplicator).not_to receive(:new)

        expect { worker.perform(entity_type, application.id, 'upsert') }
          .not_to change { row.reload.l0_delivered_at }
      end
    end

    context 'when the IAM auth service is disabled' do
      before do
        allow(::Authn::IamAuthService).to receive(:enabled?).and_return(false)
      end

      it 'is a no-op and never builds a replicator' do
        row = upsert_row
        expect(Authn::IamReplication::OauthApplicationReplicator).not_to receive(:new)

        expect { worker.perform(entity_type, application.id, 'upsert') }
          .not_to change { row.reload.l0_delivered_at }
      end
    end

    context 'with the real replicator' do
      let(:client) do
        instance_double(Authn::IamService::GrpcClient, create_oauth_application: nil, delete_oauth_application: nil)
      end

      before do
        allow(Authn::IamReplication::OauthApplicationReplicator).to receive(:new).and_call_original
        allow(Authn::IamService::GrpcClient).to receive(:new).and_return(client)
      end

      it 'reaches IAM through the replicator' do
        upsert_row

        worker.perform(entity_type, application.id, 'upsert')

        expect(client).to have_received(:create_oauth_application).with(hash_including(client_id: application.uid))
      end
    end
  end
end
