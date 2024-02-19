# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::RebuildMaterializedViewCronWorker, :clean_gitlab_redis_shared_state, :freeze_time, feature_category: :database do
  def run_job
    described_class.new.perform
  end

  context 'when the previous run was just recently' do
    before do
      Gitlab::Redis::SharedState.with do |redis|
        state = { finished_at: 1.day.ago.to_json }
        redis.set(described_class.redis_key, Gitlab::Json.dump(state))
      end
    end

    it 'does not invoke the service' do
      expect(ClickHouse::RebuildMaterializedViewService).not_to receive(:new)

      run_job
    end
  end

  context 'when the rebuild_contributions_mv feature flag is disabled' do
    it 'does not invoke the service' do
      stub_feature_flags(rebuild_contributions_mv: false)

      expect(ClickHouse::RebuildMaterializedViewService).not_to receive(:new)

      run_job
    end
  end

  context 'when the service is finished', :click_house do
    it 'persists the finished_at timestamp' do
      run_job

      Gitlab::Redis::SharedState.with do |redis|
        data = Gitlab::Json.parse(redis.get(described_class.redis_key))
        expect(DateTime.parse(data['finished_at'])).to eq(Time.current)
      end
    end
  end

  context 'when the service is interrupted' do
    it 'persists the next value to continue the processing from' do
      allow_next_instance_of(ClickHouse::RebuildMaterializedViewService) do |instance|
        allow(instance).to receive(:execute).and_return(ServiceResponse.success(payload: { status: :over_time,
                                                                                           next_value: 100 }))
      end

      run_job

      Gitlab::Redis::SharedState.with do |redis|
        data = Gitlab::Json.parse(redis.get(described_class.redis_key))
        expect(data['finished_at']).to eq(nil)
        expect(data['next_value']).to eq(100)
      end
    end
  end

  context 'when the previous run was interrupted' do
    before do
      Gitlab::Redis::SharedState.with do |redis|
        state = { started_at: 1.day.ago.to_json, next_value: 200 }
        redis.set(described_class.redis_key, Gitlab::Json.dump(state))
      end
    end

    it 'continues from the the previously persisted next_value' do
      service = instance_double('ClickHouse::RebuildMaterializedViewService',
        execute: ServiceResponse.success(payload: { status: :finished }))

      expect(ClickHouse::RebuildMaterializedViewService).to receive(:new) do |args|
        expect(args[:state][:next_value]).to eq(200)
      end.and_return(service)

      run_job
    end
  end
end
