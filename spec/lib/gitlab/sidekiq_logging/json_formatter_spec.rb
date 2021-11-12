# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqLogging::JSONFormatter do
  let(:message) { 'This is a test' }
  let(:now) { Time.now }
  let(:timestamp) { now.utc.to_f }
  let(:timestamp_iso8601) { now.iso8601(3) }

  describe 'with a Hash' do
    subject { Gitlab::Json.parse(described_class.new.call('INFO', now, 'my program', hash_input)) }

    let(:hash_input) do
      {
        foo: 1,
        'class' => 'PostReceive',
        'bar' => 'test',
        'created_at' => timestamp,
        'scheduled_at' => timestamp,
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
          'scheduled_at' => timestamp_iso8601,
          'enqueued_at' => timestamp_iso8601,
          'started_at' => timestamp_iso8601,
          'retried_at' => timestamp_iso8601,
          'failed_at' => timestamp_iso8601,
          'completed_at' => timestamp_iso8601,
          'retry' => 0
        }
      )

      expect(subject).to eq(expected_output)
    end

    it 'removes jobstr from the hash' do
      hash_input[:jobstr] = 'job string'

      expect(subject).not_to include('jobstr')
    end

    it 'does not modify the input hash' do
      input = { 'args' => [1, 'string'] }

      output = Gitlab::Json.parse(described_class.new.call('INFO', now, 'my program', input))

      expect(input['args']).to eq([1, 'string'])
      expect(output['args']).to eq(['1', '[FILTERED]'])
    end

    context 'job arguments' do
      context 'when the arguments are bigger than the maximum allowed' do
        it 'keeps args from the front until they exceed the limit' do
          half_limit = Gitlab::Utils::LogLimitedArray::MAXIMUM_ARRAY_LENGTH / 2
          hash_input['args'] = [1, 2, 'a' * half_limit, 'b' * half_limit, 3]

          expected_args = hash_input['args'].take(3).map(&:to_s) + ['...']

          expect(subject['args']).to eq(expected_args)
        end
      end

      context 'when the job has non-integer arguments' do
        it 'only allows permitted non-integer arguments through' do
          hash_input['args'] = [1, 'foo', 'bar']
          hash_input['class'] = 'WebHookWorker'

          expect(subject['args']).to eq(['1', '[FILTERED]', 'bar'])
        end
      end

      it 'properly flattens arguments to a String' do
        hash_input['args'] = [1, "test", 2, { 'test' => 1 }]

        expect(subject['args']).to eq(["1", "test", "2", %({"test"=>1})])
      end
    end

    context 'when the job has a non-integer value for retry' do
      using RSpec::Parameterized::TableSyntax

      where(:retry_in_job, :retry_in_logs) do
        3        | 3
        true     | 25
        false    | 0
        nil      | 0
        'string' | -1
      end

      with_them do
        it 'logs as the correct integer' do
          hash_input['retry'] = retry_in_job

          expect(subject['retry']).to eq(retry_in_logs)
        end
      end
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
