# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CounterAttribute, :counter_attribute, :clean_gitlab_redis_shared_state do
  using RSpec::Parameterized::TableSyntax

  let(:project_statistics) { create(:project_statistics) }
  let(:model) { CounterAttributeModel.find(project_statistics.id) }

  it_behaves_like CounterAttribute, [:build_artifacts_size, :commit_count] do
    let(:model) { CounterAttributeModel.find(project_statistics.id) }
  end

  describe 'after_flush callbacks' do
    let(:attribute) { model.class.counter_attributes.first}

    subject { model.flush_increments_to_database!(attribute) }

    it 'has registered callbacks' do # defined in :counter_attribute RSpec tag
      expect(model.class.after_flush_callbacks.size).to eq(1)
    end

    context 'when there are increments to flush' do
      before do
        model.delayed_increment_counter(attribute, 10)
      end

      it 'executes the callbacks' do
        subject

        expect(model.flushed).to be_truthy
      end
    end

    context 'when there are no increments to flush' do
      it 'does not execute the callbacks' do
        subject

        expect(model.flushed).to be_nil
      end
    end
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
