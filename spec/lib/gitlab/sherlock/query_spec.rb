require 'spec_helper'

describe Gitlab::Sherlock::Query do
  let(:started_at)  { Time.utc(2015, 1, 1) }
  let(:finished_at) { started_at + 5 }

  let(:query) do
    described_class.new('SELECT COUNT(*) FROM users', started_at, finished_at)
  end

  describe 'new_with_bindings' do
    it 'returns a Query' do
      sql = 'SELECT COUNT(*) FROM users WHERE id = $1'
      bindings = [[double(:column), 10]]

      query = described_class
        .new_with_bindings(sql, bindings, started_at, finished_at)

      expect(query.query).to eq('SELECT COUNT(*) FROM users WHERE id = 10;')
    end
  end

  describe '#id' do
    it 'returns a String' do
      expect(query.id).to be_an_instance_of(String)
    end
  end

  describe '#query' do
    it 'returns the query with a trailing semi-colon' do
      expect(query.query).to eq('SELECT COUNT(*) FROM users;')
    end
  end

  describe '#started_at' do
    it 'returns the start time' do
      expect(query.started_at).to eq(started_at)
    end
  end

  describe '#finished_at' do
    it 'returns the completion time' do
      expect(query.finished_at).to eq(finished_at)
    end
  end

  describe '#backtrace' do
    it 'returns the backtrace' do
      expect(query.backtrace).to be_an_instance_of(Array)
    end
  end

  describe '#duration' do
    it 'returns the duration in milliseconds' do
      expect(query.duration).to be_within(0.1).of(5000.0)
    end
  end

  describe '#to_param' do
    it 'returns the query ID' do
      expect(query.to_param).to eq(query.id)
    end
  end

  describe '#formatted_query' do
    it 'returns a formatted version of the query' do
      expect(query.formatted_query).to eq(<<-EOF.strip)
SELECT COUNT(*)
FROM users;
      EOF
    end
  end

  describe '#last_application_frame' do
    it 'returns the last application frame' do
      frame = query.last_application_frame

      expect(frame).to be_an_instance_of(Gitlab::Sherlock::Location)
      expect(frame.path).to eq(__FILE__)
    end
  end

  describe '#application_backtrace' do
    it 'returns an Array of application frames' do
      frames = query.application_backtrace

      expect(frames).to be_an_instance_of(Array)
      expect(frames).not_to be_empty

      frames.each do |frame|
        expect(frame.path).to start_with(Rails.root.to_s)
      end
    end
  end

  describe '#explain' do
    it 'returns the query plan as a String' do
      lines = [
        ['Aggregate (cost=123 rows=1)'],
        ['  -> Index Only Scan using index_cats_are_amazing']
      ]

      result = double(:result, values: lines)

      allow(query).to receive(:raw_explain).and_return(result)

      expect(query.explain).to eq(<<-EOF.strip)
Aggregate (cost=123 rows=1)
  -> Index Only Scan using index_cats_are_amazing
      EOF
    end
  end
end
