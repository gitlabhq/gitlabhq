# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CounterAttribute, :counter_attribute, :clean_gitlab_redis_shared_state do
  using RSpec::Parameterized::TableSyntax

  let(:project_statistics) { create(:project_statistics) }
  let(:model) { CounterAttributeModel.find(project_statistics.id) }

  it_behaves_like CounterAttribute, [:build_artifacts_size, :commit_count] do
    let(:model) { CounterAttributeModel.find(project_statistics.id) }
  end

  describe '.steal_increments' do
    let(:increment_key) { 'counters:Model:123:attribute' }
    let(:flushed_key) { 'counter:Model:123:attribute:flushed' }

    subject { model.send(:steal_increments, increment_key, flushed_key) }

    where(:increment, :flushed, :result, :flushed_key_present) do
      nil | nil | 0  | false
      nil | 0   | 0  | false
      0   | 0   | 0  | false
      1   | 0   | 1  | true
      1   | nil | 1  | true
      1   | 1   | 2  | true
      1   | -2  | -1 | true
      -1  | 1   | 0  | false
    end

    with_them do
      before do
        Gitlab::Redis::SharedState.with do |redis|
          redis.set(increment_key, increment) if increment
          redis.set(flushed_key, flushed) if flushed
        end
      end

      it { is_expected.to eq(result) }

      it 'drops the increment key and creates the flushed key if it does not exist' do
        subject

        Gitlab::Redis::SharedState.with do |redis|
          expect(redis.exists(increment_key)).to be_falsey
          expect(redis.exists(flushed_key)).to eq(flushed_key_present)
        end
      end
    end
  end
end
