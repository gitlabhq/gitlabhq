# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Cells::ClaimsVerificationWorker, :clean_gitlab_redis_shared_state, feature_category: :cell do
  let(:worker) { described_class.new }
  let(:mock_service) { instance_double(Cells::Claims::VerificationService) }
  let(:redis_key) { "cells:claims:verification_service:last_processed_id:User" }

  before do
    stub_config_cell(enabled: true)
  end

  it_behaves_like 'an idempotent worker' do
    let(:job_args) { ["User"] }
  end

  describe '#lease_key' do
    it 'includes the model name for per-model locking' do
      worker.perform("User") # sets @model_name
      expect(worker.send(:lease_key)).to eq("cells/claims_verification_worker:User")
    end
  end

  describe '#perform' do
    let(:model_name) { 'User' }

    context 'when cell is not enabled' do
      before do
        stub_config_cell(enabled: false)
      end

      it 'does not execute the verification service' do
        expect(Cells::Claims::VerificationService).not_to receive(:new)

        worker.perform(model_name)
      end

      it 'is not enabled' do
        expect(worker.send(:enabled?, User)).to be(false)
      end
    end

    context 'when feature flag is disabled for the model' do
      before do
        stub_feature_flags(cells_claims_verification_worker_user: false)
      end

      it 'does not execute the verification service' do
        expect(Cells::Claims::VerificationService).not_to receive(:new)

        worker.perform(model_name)
      end
    end

    context 'when model_name is namespaced' do
      let(:model_name) { 'Foo::Bar' }
      let(:model) do
        Class.new(ApplicationRecord) do
          self.table_name = 'foobar'
          def self.name = 'Foo::Bar'
        end
      end

      before do
        stub_feature_flag_definition("cells_claims_verification_worker_foo_bar")
        stub_const('Foo::Bar', model)
      end

      it 'uses underscored and de-namespaced flag name' do
        expect(Feature).to receive(:enabled?)
          .with("cells_claims_verification_worker_foo_bar", :instance)
          .and_return(false)

        worker.perform(model_name)
      end
    end

    context 'when model_name cannot be constantized' do
      let(:model_name) { 'NonExistentModel' }

      before do
        stub_feature_flag_definition("cells_claims_verification_worker_non_existent_model")
      end

      it 'does not execute the verification service' do
        expect(Cells::Claims::VerificationService).not_to receive(:new)

        worker.perform(model_name)
      end
    end

    context 'when model_name constantizes to a non-ActiveRecord class' do
      let(:model_name) { 'String' }

      before do
        stub_feature_flag_definition("cells_claims_verification_worker_string")
      end

      it 'does not execute the verification service' do
        expect(Cells::Claims::VerificationService).not_to receive(:new)

        worker.perform(model_name)
      end
    end

    context 'when model is valid' do
      before do
        allow(Cells::Claims::VerificationService).to receive(:new)
          .with(User, timeout: described_class::MAX_RUNTIME, start_id: 0).and_return(mock_service)
        allow(mock_service).to receive(:execute).and_return({
          created: 3,
          destroyed: 1,
          over_time: false,
          last_id: 100
        })
      end

      it 'executes the verification service' do
        expect(mock_service).to receive(:execute)

        worker.perform(model_name)
      end

      it 'does not re-enqueue itself' do
        expect(described_class).not_to receive(:perform_async)

        worker.perform(model_name)
      end

      it 'resets last_processed_id to 0' do
        worker.perform(model_name)

        Gitlab::Redis::SharedState.with do |redis|
          expect(redis.get(redis_key)).to eq('0')
        end
      end

      it 'logs the verification result' do
        expect(worker).to receive(:log_hash_metadata_on_done).with(
          message: 'Records verification completed',
          feature_category: :cell,
          model: "User",
          created: 3,
          destroyed: 1,
          over_time: false,
          start_id: 0,
          last_id: 100
        )

        worker.perform(model_name)
      end
    end

    context 'when the service exceeds the runtime limit' do
      before do
        allow(Cells::Claims::VerificationService).to receive(:new) do |_model, **_kwargs, &block|
          block.call(5000)
          mock_service
        end
        allow(mock_service).to receive(:execute).and_return({
          created: 5,
          destroyed: 0,
          over_time: true,
          last_id: 5000
        })
      end

      it 're-enqueues itself' do
        expect(described_class).to receive(:perform_async).with(model_name)

        worker.perform(model_name)
      end

      it 'saves last_processed_id for the next run' do
        allow(described_class).to receive(:perform_async)

        worker.perform(model_name)

        Gitlab::Redis::SharedState.with do |redis|
          expect(redis.get(redis_key).to_i).to eq(5000)
        end
      end

      it 'logs over_time in metadata' do
        allow(described_class).to receive(:perform_async)

        expect(worker).to receive(:log_hash_metadata_on_done).with(
          hash_including(over_time: true, start_id: 0, last_id: 5000)
        )

        worker.perform(model_name)
      end
    end

    context 'when last_processed_id is already set in Redis' do
      before do
        Gitlab::Redis::SharedState.with { |r| r.set(redis_key, 3000) }
        allow(Cells::Claims::VerificationService).to receive(:new)
          .with(User, timeout: described_class::MAX_RUNTIME, start_id: 3000).and_return(mock_service)
        allow(mock_service).to receive(:execute).and_return({
          created: 2,
          destroyed: 0,
          over_time: false,
          last_id: 5000
        })
      end

      it 'passes the last_processed_id as start_id to the service' do
        expect(Cells::Claims::VerificationService).to receive(:new)
          .with(User, timeout: described_class::MAX_RUNTIME, start_id: 3000)
          .and_return(mock_service)

        worker.perform(model_name)
      end
    end

    context 'when the exclusive lease is already held' do
      include ExclusiveLeaseHelpers

      before do
        stub_exclusive_lease_taken("cells/claims_verification_worker:User")
      end

      it 'does not execute the verification service' do
        expect(Cells::Claims::VerificationService).not_to receive(:new)

        expect { worker.perform(model_name) }.to raise_error(
          Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError
        )
      end

      it 'does not track the exception' do
        expect(Gitlab::ErrorTracking).not_to receive(:track_exception)

        expect { worker.perform(model_name) }.to raise_error(
          Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError
        )
      end

      it 'logs the lock failure' do
        expect(Sidekiq.logger).to receive(:warn).with(
          hash_including(message: a_string_including('exclusive lease'))
        )

        expect { worker.perform(model_name) }.to raise_error(
          Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError
        )
      end
    end

    context 'when the service raises a StandardError' do
      let(:error) { StandardError.new('something went wrong') }

      before do
        allow(Cells::Claims::VerificationService).to receive(:new)
          .with(User, timeout: described_class::MAX_RUNTIME, start_id: 0).and_return(mock_service)
        allow(mock_service).to receive(:execute).and_raise(error)
      end

      it 'tracks the exception' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception)
          .with(error, feature_category: :cell)

        expect { worker.perform(model_name) }.to raise_error(StandardError)
      end

      it 're-raises the error for Sidekiq retry' do
        allow(Gitlab::ErrorTracking).to receive(:track_exception)

        expect { worker.perform(model_name) }.to raise_error(StandardError, 'something went wrong')
      end
    end

    context 'when per-batch progress callback is invoked' do
      it 'saves progress to Redis after each batch via the callback' do
        allow(Cells::Claims::VerificationService).to receive(:new) do |_model, **_kwargs, &block|
          block.call(2000)
          block.call(4000)
          mock_service
        end

        allow(mock_service).to receive(:execute).and_return({
          created: 0,
          destroyed: 0,
          over_time: false,
          last_id: 4000
        })

        expect(worker).to receive(:save_last_processed_id).with(2000).ordered
        expect(worker).to receive(:save_last_processed_id).with(4000).ordered
        expect(worker).to receive(:save_last_processed_id).with(0).ordered

        worker.perform(model_name)
      end

      it 'preserves batch progress in Redis when service raises after some batches' do
        allow(Cells::Claims::VerificationService).to receive(:new) do |_model, **_kwargs, &block|
          block.call(2000)
          block.call(4000)
          mock_service
        end

        allow(mock_service).to receive(:execute).and_raise(StandardError.new('gRPC timeout'))
        allow(Gitlab::ErrorTracking).to receive(:track_exception)

        expect { worker.perform(model_name) }.to raise_error(StandardError)

        Gitlab::Redis::SharedState.with do |redis|
          expect(redis.get(redis_key).to_i).to eq(4000)
        end
      end
    end
  end
end
