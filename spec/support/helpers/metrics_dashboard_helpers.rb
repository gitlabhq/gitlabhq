# frozen_string_literal: true

module MetricsDashboardHelpers
  def project_with_dashboard(dashboard_path, dashboard_yml = nil)
    dashboard_yml ||= fixture_file('lib/gitlab/metrics/dashboard/sample_dashboard.yml')

    create(:project, :custom_repo, files: { dashboard_path => dashboard_yml })
  end

  def delete_project_dashboard(project, user, dashboard_path)
    project.repository.delete_file(
      user,
      dashboard_path,
      branch_name: 'master',
      message: 'Delete dashboard'
    )

    project.repository.refresh_method_caches([:metrics_dashboard])
  end

  def system_dashboard_path
    Metrics::Dashboard::SystemDashboardService::DASHBOARD_PATH
  end

  def business_metric_title
    PrometheusMetricEnums.group_details[:business][:group_title]
  end

  shared_examples_for 'misconfigured dashboard service response' do |status_code|
    it 'returns an appropriate message and status code' do
      result = service_call

      expect(result.keys).to contain_exactly(:message, :http_status, :status)
      expect(result[:status]).to eq(:error)
      expect(result[:http_status]).to eq(status_code)
    end
  end

  shared_examples_for 'valid dashboard service response for schema' do
    it 'returns a json representation of the dashboard' do
      result = service_call

      expect(result.keys).to contain_exactly(:dashboard, :status)
      expect(result[:status]).to eq(:success)

      expect(JSON::Validator.fully_validate(dashboard_schema, result[:dashboard])).to be_empty
    end
  end

  shared_examples_for 'valid dashboard service response' do
    let(:dashboard_schema) { JSON.parse(fixture_file('lib/gitlab/metrics/dashboard/schemas/dashboard.json')) }

    it_behaves_like 'valid dashboard service response for schema'
  end

  shared_examples_for 'caches the unprocessed dashboard for subsequent calls' do
    it do
      expect(YAML).to receive(:safe_load).once.and_call_original

      described_class.new(*service_params).get_dashboard
      described_class.new(*service_params).get_dashboard
    end
  end

  shared_examples_for 'valid embedded dashboard service response' do
    let(:dashboard_schema) { JSON.parse(fixture_file('lib/gitlab/metrics/dashboard/schemas/embedded_dashboard.json')) }

    it_behaves_like 'valid dashboard service response for schema'
  end

  shared_examples_for 'raises error for users with insufficient permissions' do
    context 'when the user does not have sufficient access' do
      let(:user) { build(:user) }

      it_behaves_like 'misconfigured dashboard service response', :unauthorized
    end
  end
end
