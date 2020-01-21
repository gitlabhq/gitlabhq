# frozen_string_literal: true

RSpec.shared_examples 'misconfigured dashboard service response' do |status_code, message = nil|
  it 'returns an appropriate message and status code', :aggregate_failures do
    result = service_call

    expect(result.keys).to contain_exactly(:message, :http_status, :status)
    expect(result[:status]).to eq(:error)
    expect(result[:http_status]).to eq(status_code)
    expect(result[:message]).to eq(message) if message
  end
end

RSpec.shared_examples 'valid dashboard service response for schema' do
  it 'returns a json representation of the dashboard' do
    result = service_call

    expect(result.keys).to contain_exactly(:dashboard, :status)
    expect(result[:status]).to eq(:success)

    expect(JSON::Validator.fully_validate(dashboard_schema, result[:dashboard])).to be_empty
  end
end

RSpec.shared_examples 'valid dashboard service response' do
  let(:dashboard_schema) { JSON.parse(fixture_file('lib/gitlab/metrics/dashboard/schemas/dashboard.json')) }

  it_behaves_like 'valid dashboard service response for schema'
end

RSpec.shared_examples 'caches the unprocessed dashboard for subsequent calls' do
  it do
    expect(YAML).to receive(:safe_load).once.and_call_original

    described_class.new(*service_params).get_dashboard
    described_class.new(*service_params).get_dashboard
  end
end

RSpec.shared_examples 'valid embedded dashboard service response' do
  let(:dashboard_schema) { JSON.parse(fixture_file('lib/gitlab/metrics/dashboard/schemas/embedded_dashboard.json')) }

  it_behaves_like 'valid dashboard service response for schema'
end

RSpec.shared_examples 'raises error for users with insufficient permissions' do
  context 'when the user does not have sufficient access' do
    let(:user) { build(:user) }

    it_behaves_like 'misconfigured dashboard service response', :unauthorized
  end
end
