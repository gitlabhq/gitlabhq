# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::SidekiqLogging::JSONFormatter do
  let(:message) { 'This is a test' }
  let(:now) { Time.now }
  let(:timestamp) { now.utc.to_f }
  let(:timestamp_iso8601) { now.iso8601(3) }

  describe 'with a Hash' do
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
      result = subject.call('INFO', now, 'my program', hash_input)

      data = JSON.parse(result)
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

      expect(data).to eq(expected_output)
    end
  end

  it 'wraps a String' do
    result = subject.call('DEBUG', now, 'my string', message)

    data = JSON.parse(result)
    expected_output = {
      severity: 'DEBUG',
      time: timestamp_iso8601,
      message: message
    }

    expect(data).to eq(expected_output.stringify_keys)
  end
end
