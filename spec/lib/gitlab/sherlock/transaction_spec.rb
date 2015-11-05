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

  describe '#to_param' do
    it 'returns the transaction ID' do
      expect(transaction.to_param).to eq(transaction.id)
    end
  end

  describe '#sorted_queries' do
    it 'returns the queries in descending order' do
      start_time = Time.now

      query1 = Gitlab::Sherlock::Query.new('SELECT 1', start_time, start_time)

      query2 = Gitlab::Sherlock::Query.
        new('SELECT 2', start_time, start_time + 5)

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
        allow(Gitlab::Sherlock).to receive(:enable_line_profiler?).
          and_return(true)

        allow_any_instance_of(Gitlab::Sherlock::LineProfiler).
          to receive(:profile).and_return('cats are amazing', [])

        retval = transaction.profile_lines { 'cats are amazing' }

        expect(retval).to eq('cats are amazing')
      end
    end

    describe 'when line profiling is disabled' do
      it 'yields the block' do
        allow(Gitlab::Sherlock).to receive(:enable_line_profiler?).
          and_return(false)

        retval = transaction.profile_lines { 'cats are amazing' }

        expect(retval).to eq('cats are amazing')
      end
    end
  end
end
