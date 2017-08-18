require 'spec_helper'

describe Gitlab::Sherlock::Transaction do
  let(:transaction) { described_class.new('POST', '/cat_pictures') }

  describe '#id' do
    it 'returns the transaction ID' do
      expect(transaction.id).to be_an_instance_of(String)
    end
  end

  describe '#type' do
    it 'returns the type' do
      expect(transaction.type).to eq('POST')
    end
  end

  describe '#path' do
    it 'returns the path' do
      expect(transaction.path).to eq('/cat_pictures')
    end
  end

  describe '#queries' do
    it 'returns an Array of queries' do
      expect(transaction.queries).to be_an_instance_of(Array)
    end
  end

  describe '#file_samples' do
    it 'returns an Array of file samples' do
      expect(transaction.file_samples).to be_an_instance_of(Array)
    end
  end

  describe '#started_at' do
    it 'returns the start time' do
      allow(transaction).to receive(:profile_lines).and_yield

      transaction.run { 'cats are amazing' }

      expect(transaction.started_at).to be_an_instance_of(Time)
    end
  end

  describe '#finished_at' do
    it 'returns the completion time' do
      allow(transaction).to receive(:profile_lines).and_yield

      transaction.run { 'cats are amazing' }

      expect(transaction.finished_at).to be_an_instance_of(Time)
    end
  end

  describe '#view_counts' do
    it 'returns a Hash' do
      expect(transaction.view_counts).to be_an_instance_of(Hash)
    end

    it 'sets the default value of a key to 0' do
      expect(transaction.view_counts['cats.rb']).to be_zero
    end
  end

  describe '#run' do
    it 'runs the transaction' do
      allow(transaction).to receive(:profile_lines).and_yield

      retval = transaction.run { 'cats are amazing' }

      expect(retval).to eq('cats are amazing')
    end
  end

  describe '#duration' do
    it 'returns the duration in seconds' do
      start_time = Time.now

      allow(transaction).to receive(:started_at).and_return(start_time)
      allow(transaction).to receive(:finished_at).and_return(start_time + 5)

      expect(transaction.duration).to be_within(0.1).of(5.0)
    end
  end

  describe '#query_duration' do
    it 'returns the total query duration in seconds' do
      time   = Time.now
      query1 = Gitlab::Sherlock::Query.new('SELECT 1', time, time + 5)
      query2 = Gitlab::Sherlock::Query.new('SELECT 2', time, time + 2)

      transaction.queries << query1
      transaction.queries << query2

      expect(transaction.query_duration).to be_within(0.1).of(7.0)
    end
  end

  describe '#to_param' do
    it 'returns the transaction ID' do
      expect(transaction.to_param).to eq(transaction.id)
    end
  end

  describe '#sorted_queries' do
    it 'returns the queries in descending order' do
      start_time = Time.now

      query1 = Gitlab::Sherlock::Query.new('SELECT 1', start_time, start_time)

      query2 = Gitlab::Sherlock::Query
        .new('SELECT 2', start_time, start_time + 5)

      transaction.queries << query1
      transaction.queries << query2

      expect(transaction.sorted_queries).to eq([query2, query1])
    end
  end

  describe '#sorted_file_samples' do
    it 'returns the file samples in descending order' do
      sample1 = Gitlab::Sherlock::FileSample.new(__FILE__, [], 10.0, 1)
      sample2 = Gitlab::Sherlock::FileSample.new(__FILE__, [], 15.0, 1)

      transaction.file_samples << sample1
      transaction.file_samples << sample2

      expect(transaction.sorted_file_samples).to eq([sample2, sample1])
    end
  end

  describe '#find_query' do
    it 'returns a Query when found' do
      query = Gitlab::Sherlock::Query.new('SELECT 1', Time.now, Time.now)

      transaction.queries << query

      expect(transaction.find_query(query.id)).to eq(query)
    end

    it 'returns nil when no query could be found' do
      expect(transaction.find_query('cats')).to be_nil
    end
  end

  describe '#find_file_sample' do
    it 'returns a FileSample when found' do
      sample = Gitlab::Sherlock::FileSample.new(__FILE__, [], 10.0, 1)

      transaction.file_samples << sample

      expect(transaction.find_file_sample(sample.id)).to eq(sample)
    end

    it 'returns nil when no file sample could be found' do
      expect(transaction.find_file_sample('cats')).to be_nil
    end
  end

  describe '#profile_lines' do
    describe 'when line profiling is enabled' do
      it 'yields the block using the line profiler' do
        allow(Gitlab::Sherlock).to receive(:enable_line_profiler?)
          .and_return(true)

        allow_any_instance_of(Gitlab::Sherlock::LineProfiler)
          .to receive(:profile).and_return('cats are amazing', [])

        retval = transaction.profile_lines { 'cats are amazing' }

        expect(retval).to eq('cats are amazing')
      end
    end

    describe 'when line profiling is disabled' do
      it 'yields the block' do
        allow(Gitlab::Sherlock).to receive(:enable_line_profiler?)
          .and_return(false)

        retval = transaction.profile_lines { 'cats are amazing' }

        expect(retval).to eq('cats are amazing')
      end
    end
  end

  describe '#subscribe_to_active_record' do
    let(:subscription) { transaction.subscribe_to_active_record }
    let(:time) { Time.now }
    let(:query_data) { { sql: 'SELECT 1', binds: [] } }

    after do
      ActiveSupport::Notifications.unsubscribe(subscription)
    end

    it 'tracks executed queries' do
      expect(transaction).to receive(:track_query)
        .with('SELECT 1', [], time, time)

      subscription.publish('test', time, time, nil, query_data)
    end

    it 'only tracks queries triggered from the transaction thread' do
      expect(transaction).not_to receive(:track_query)

      Thread.new { subscription.publish('test', time, time, nil, query_data) }
        .join
    end
  end

  describe '#subscribe_to_action_view' do
    let(:subscription) { transaction.subscribe_to_action_view }
    let(:time) { Time.now }
    let(:view_data) { { identifier: 'foo.rb' } }

    after do
      ActiveSupport::Notifications.unsubscribe(subscription)
    end

    it 'tracks rendered views' do
      expect(transaction).to receive(:track_view).with('foo.rb')

      subscription.publish('test', time, time, nil, view_data)
    end

    it 'only tracks views rendered from the transaction thread' do
      expect(transaction).not_to receive(:track_view)

      Thread.new { subscription.publish('test', time, time, nil, view_data) }
        .join
    end
  end
end
