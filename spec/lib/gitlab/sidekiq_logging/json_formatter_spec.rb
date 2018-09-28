require 'spec_helper'

describe Gitlab::SidekiqLogging::JSONFormatter do
  let(:hash_input) { { foo: 1, bar: 'test' } }
  let(:message) { 'This is a test' }
  let(:timestamp) { Time.now }

  it 'wraps a Hash' do
    result = subject.call('INFO', timestamp, 'my program', hash_input)

    data = JSON.parse(result)
    expected_output = hash_input.stringify_keys
    expected_output['severity'] = 'INFO'
    expected_output['time'] = timestamp.utc.iso8601(3)

    expect(data).to eq(expected_output)
  end

  it 'wraps a String' do
    result = subject.call('DEBUG', timestamp, 'my string', message)

    data = JSON.parse(result)
    expected_output = {
      severity: 'DEBUG',
      time: timestamp.utc.iso8601(3),
      message: message
    }

    expect(data).to eq(expected_output.stringify_keys)
  end
end
