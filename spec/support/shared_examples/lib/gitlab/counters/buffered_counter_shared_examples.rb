# frozen_string_literal: true

RSpec.shared_examples 'handling a buffered counter in redis' do
  it 'returns the value when there is an existing value stored in the counter' do
    Gitlab::Redis::SharedState.with do |redis|
      redis.set(counter.key, 456)
    end

    expect(counter.get).to eq(456)
  end

  it 'returns 0 when there is no existing value' do
    expect(counter.get).to eq(0)
  end
end

RSpec.shared_examples 'incrementing a buffered counter when not undergoing a refresh' do
  context 'when the counter is not undergoing refresh' do
    it 'sets a new key by the given value' do
      counter.increment(increment)

      expect(counter.get).to eq(increment.amount)
    end

    it 'increments an existing key by the given value' do
      counter.increment(other_increment)
      counter.increment(increment)

      expect(counter.get).to eq(other_increment.amount + increment.amount)
    end

    it 'returns the value of the key after the increment' do
      counter.increment(increment)
      result = counter.increment(other_increment)

      expect(result).to eq(increment.amount + other_increment.amount)
    end

    it 'schedules a worker to commit the counter key into database' do
      expect(FlushCounterIncrementsWorker).to receive(:perform_in)
        .with(described_class::WORKER_DELAY, counter_record.class.to_s, counter_record.id, attribute.to_s)

      counter.increment(increment)
    end
  end
end
