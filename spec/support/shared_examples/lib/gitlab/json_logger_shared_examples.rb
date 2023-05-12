# frozen_string_literal: true

RSpec.shared_examples 'a json logger' do |extra_params|
  let(:now) { Time.now }
  let(:correlation_id) { Labkit::Correlation::CorrelationId.current_id }

  it 'formats strings' do
    output = subject.format_message('INFO', now, 'test', 'Hello world')
    data = Gitlab::Json.parse(output)

    expect(data['severity']).to eq('INFO')
    expect(data['time']).to eq(now.utc.iso8601(3))
    expect(data['message']).to eq('Hello world')
    expect(data['correlation_id']).to eq(correlation_id)
    expect(data).to include(extra_params)
  end

  it 'formats hashes' do
    output = subject.format_message('INFO', now, 'test', { hello: 1 })
    data = Gitlab::Json.parse(output)

    expect(data['severity']).to eq('INFO')
    expect(data['time']).to eq(now.utc.iso8601(3))
    expect(data['hello']).to eq(1)
    expect(data['message']).to be_nil
    expect(data['correlation_id']).to eq(correlation_id)
    expect(data).to include(extra_params)
  end
end
