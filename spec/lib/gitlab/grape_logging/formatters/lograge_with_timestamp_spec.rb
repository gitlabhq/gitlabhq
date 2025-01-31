# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GrapeLogging::Formatters::LogrageWithTimestamp do
  let(:log_entry) do
    {
      status: 200,
      time: {
        total: 758.58,
        db: 77.06,
        view: 681.52
      },
      method: 'PUT',
      path: '/api/v4/projects/1',
      params: {
        description: '[FILTERED]',
        name: 'gitlab test',
        int: 42,
        float: 42.123,
        true_value: true,
        false_value: false,
        null_value: nil
      },
      host: 'localhost',
      remote_ip: '127.0.0.1',
      ua: 'curl/7.66.0',
      route: '/api/:version/projects/:id',
      user_id: 1,
      username: 'root',
      queue_duration: 1764.06,
      gitaly_calls: 6,
      gitaly_duration: 20.0,
      correlation_id: 'WMefXn60429'
    }
  end

  let(:time) { Time.now }
  let(:result) { Gitlab::Json.parse(subject) }

  subject { described_class.new.call(:info, time, nil, log_entry) }

  it 'turns the log entry to valid JSON' do
    expect(result['status']).to eq(200)
  end

  it 're-formats the params hash' do
    params = result['params']

    expect(params).to eq(
      [
        { 'key' => 'description', 'value' => '[FILTERED]' },
        { 'key' => 'name', 'value' => 'gitlab test' },
        { 'key' => 'int', 'value' => 42 },
        { 'key' => 'float', 'value' => 42.123 },
        { 'key' => 'true_value', 'value' => true },
        { 'key' => 'false_value', 'value' => false },
        { 'key' => 'null_value', 'value' => nil }
      ])
  end
end
