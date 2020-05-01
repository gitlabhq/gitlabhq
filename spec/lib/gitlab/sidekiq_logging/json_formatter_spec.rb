# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::SidekiqLogging::JSONFormatter do
  let(:message) { 'This is a test' }
  let(:now) { Time.now }
  let(:timestamp) { now.utc.to_f }
  let(:timestamp_iso8601) { now.iso8601(3) }

  describe 'with a Hash' do
    subject { Gitlab::Json.parse(described_class.new.call('INFO', now, 'my program', hash_input)) }

    let(:hash_input) do
      {
        foo: 1,
        'bar' => 'test',
        'created_at' => timestamp,
        'enqueued_at' => timestamp,
        'started_at' => timestamp,
        'retried_at' => timestamp,
        'failed_at' => timestamp,
        'completed_at' => timestamp_iso8601
      }
    end

    it 'properly formats timestamps into ISO 8601 form' do
      expected_output = hash_input.stringify_keys.merge!(
        {
          'severity' => 'INFO',
          'time' => timestamp_iso8601,
          'created_at' => timestamp_iso8601,
          'enqueued_at' => timestamp_iso8601,
          'started_at' => timestamp_iso8601,
          'retried_at' => timestamp_iso8601,
          'failed_at' => timestamp_iso8601,
          'completed_at' => timestamp_iso8601
        }
      )

      expect(subject).to eq(expected_output)
    end

    context 'when the job args are bigger than the maximum allowed' do
      it 'keeps args from the front until they exceed the limit' do
        half_limit = Gitlab::Utils::LogLimitedArray::MAXIMUM_ARRAY_LENGTH / 2
        hash_input['args'] = [1, 2, 'a' * half_limit, 'b' * half_limit, 3]

        expected_args = hash_input['args'].take(3).map(&:to_s) + ['...']

        expect(subject['args']).to eq(expected_args)
      end
    end

    it 'properly flattens arguments to a String' do
      hash_input['args'] = [1, "test", 2, { 'test' => 1 }]

      expect(subject['args']).to eq(["1", "test", "2", %({"test"=>1})])
    end
  end

  describe 'with a String' do
    it 'accepts strings with no changes' do
      result = subject.call('DEBUG', now, 'my string', message)

      data = Gitlab::Json.parse(result)
      expected_output = {
        severity: 'DEBUG',
        time: timestamp_iso8601,
        message: message
      }

      expect(data).to eq(expected_output.stringify_keys)
    end
  end
end
