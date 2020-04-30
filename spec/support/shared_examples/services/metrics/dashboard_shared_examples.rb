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
  let(:dashboard_schema) { Gitlab::Json.parse(fixture_file('lib/gitlab/metrics/dashboard/schemas/dashboard.json')) }

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
  let(:dashboard_schema) { Gitlab::Json.parse(fixture_file('lib/gitlab/metrics/dashboard/schemas/embedded_dashboard.json')) }

  it_behaves_like 'valid dashboard service response for schema'
end

RSpec.shared_examples 'raises error for users with insufficient permissions' do
  context 'when the user does not have sufficient access' do
    let(:user) { build(:user) }

    it_behaves_like 'misconfigured dashboard service response', :unauthorized
  end
end

RSpec.shared_examples 'valid dashboard cloning process' do |dashboard_template, sequence|
  context "dashboard template: #{dashboard_template}" do
    let(:dashboard) { dashboard_template }
    let(:dashboard_attrs) do
      {
        commit_message: commit_message,
        branch_name: branch,
        start_branch: project.default_branch,
        encoding: 'text',
        file_path: ".gitlab/dashboards/#{file_name}",
        file_content: file_content_hash.to_yaml
      }
    end

    it 'delegates commit creation to Files::CreateService', :aggregate_failures do
      service_instance = instance_double(::Files::CreateService)
      allow(::Gitlab::Metrics::Dashboard::Processor).to receive(:new).and_return(double(process: file_content_hash))
      expect(::Files::CreateService).to receive(:new).with(project, user, dashboard_attrs).and_return(service_instance)
      expect(service_instance).to receive(:execute).and_return(status: :success)

      service_call
    end

    context 'user has defined custom metrics' do
      it 'uses external service to includes them into new file content', :aggregate_failures do
        service_instance = double(::Gitlab::Metrics::Dashboard::Processor)
        expect(::Gitlab::Metrics::Dashboard::Processor).to receive(:new).with(project, file_content_hash, sequence, {}).and_return(service_instance)
        expect(service_instance).to receive(:process).and_return(file_content_hash)
        expect(::Files::CreateService).to receive(:new).with(project, user, dashboard_attrs).and_return(double(execute: { status: :success }))

        service_call
      end
    end
  end
end

RSpec.shared_examples 'valid dashboard update process' do
  let(:dashboard_attrs) do
    {
      commit_message: commit_message,
      branch_name: branch,
      start_branch: project.default_branch,
      encoding: 'text',
      file_path: ".gitlab/dashboards/#{file_name}",
      file_content: ::PerformanceMonitoring::PrometheusDashboard.from_json(file_content_hash).to_yaml
    }
  end

  it 'delegates commit creation to Files::UpdateService', :aggregate_failures do
    service_instance = instance_double(::Files::UpdateService)
    expect(::Files::UpdateService).to receive(:new).with(project, user, dashboard_attrs).and_return(service_instance)
    expect(service_instance).to receive(:execute).and_return(status: :success)

    service_call
  end
end

RSpec.shared_examples 'misconfigured dashboard service response with stepable' do |status_code, message = nil|
  it 'returns an appropriate message and status code', :aggregate_failures do
    result = service_call

    expect(result.keys).to contain_exactly(:message, :http_status, :status, :last_step)
    expect(result[:status]).to eq(:error)
    expect(result[:http_status]).to eq(status_code)
    expect(result[:message]).to eq(message) if message
  end
end

RSpec.shared_examples 'updates gitlab_metrics_dashboard_processing_time_ms metric' do
  specify :prometheus do
    service_call
    metric = subject.send(:processing_time_metric)
    labels = subject.send(:processing_time_metric_labels)

    expect(metric.get(labels)).to be > 0
  end
end
