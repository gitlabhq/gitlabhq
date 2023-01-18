# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Counters::LegacyCounter do
  subject(:counter) { described_class.new(counter_record, attribute) }

  let_it_be(:counter_record, reload: true) { create(:project_statistics) }

  let(:attribute) { :snippets_size }

  let(:increment) { Gitlab::Counters::Increment.new(amount: 123) }
  let(:other_increment) { Gitlab::Counters::Increment.new(amount: 100) }

  describe '#increment' do
    it 'increments the attribute in the counter record' do
      expect { counter.increment(increment) }
        .to change { counter_record.reload.method(attribute).call }.by(increment.amount)
    end

    it 'returns the value after the increment' do
      counter.increment(other_increment)

      expect(counter.increment(increment)).to eq(other_increment.amount + increment.amount)
    end

    it 'executes after counter_record after commit callback' do
      expect(counter_record).to receive(:execute_after_commit_callbacks).and_call_original

      counter.increment(increment)
    end
  end

  describe '#bulk_increment' do
    let(:increments) { [Gitlab::Counters::Increment.new(amount: 123), Gitlab::Counters::Increment.new(amount: 456)] }

    it 'increments the attribute in the counter record' do
      expect { counter.bulk_increment(increments) }
        .to change { counter_record.reload.method(attribute).call }.by(increments.sum(&:amount))
    end

    it 'returns the value after the increment' do
      counter.increment(other_increment)

      expect(counter.bulk_increment(increments)).to eq(other_increment.amount + increments.sum(&:amount))
    end

    it 'executes after counter_record after commit callback' do
      expect(counter_record).to receive(:execute_after_commit_callbacks).and_call_original

      counter.bulk_increment(increments)
    end
  end
end
