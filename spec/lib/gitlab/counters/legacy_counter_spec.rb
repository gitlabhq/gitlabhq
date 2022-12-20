# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Counters::LegacyCounter do
  subject(:counter) { described_class.new(counter_record, attribute) }

  let(:counter_record) { create(:project_statistics) }
  let(:attribute) { :snippets_size }
  let(:amount) { 123 }

  describe '#increment' do
    it 'increments the attribute in the counter record' do
      expect { counter.increment(amount) }.to change { counter_record.reload.method(attribute).call }.by(amount)
    end

    it 'returns the value after the increment' do
      counter.increment(100)

      expect(counter.increment(amount)).to eq(100 + amount)
    end

    it 'executes after counter_record after commit callback' do
      expect(counter_record).to receive(:execute_after_commit_callbacks).and_call_original

      counter.increment(amount)
    end
  end

  describe '#bulk_increment' do
    let(:increments) { [123, 456] }

    it 'increments the attribute in the counter record' do
      expect { counter.bulk_increment(increments) }
        .to change { counter_record.reload.method(attribute).call }.by(increments.sum)
    end

    it 'returns the value after the increment' do
      counter.increment(100)

      expect(counter.bulk_increment(increments)).to eq(100 + increments.sum)
    end

    it 'executes after counter_record after commit callback' do
      expect(counter_record).to receive(:execute_after_commit_callbacks).and_call_original

      counter.bulk_increment(increments)
    end
  end

  describe '#reset!' do
    before do
      allow(counter_record).to receive(:update!)
    end

    it 'resets the record to 0' do
      expect(counter_record).to receive(:update!).with(attribute => 0)

      counter.reset!
    end
  end
end
