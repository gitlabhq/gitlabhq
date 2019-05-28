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

  shared_examples_for 'misconfigured dashboard service response' do |status_code|
    it 'returns an appropriate message and status code' do
      result = service_call

      expect(result.keys).to contain_exactly(:message, :http_status, :status)
      expect(result[:status]).to eq(:error)
      expect(result[:http_status]).to eq(status_code)
    end
  end

  shared_examples_for 'valid dashboard service response' do
    let(:dashboard_schema) { JSON.parse(fixture_file('lib/gitlab/metrics/dashboard/schemas/dashboard.json')) }

    it 'returns a json representation of the dashboard' do
      result = service_call

      expect(result.keys).to contain_exactly(:dashboard, :status)
      expect(result[:status]).to eq(:success)

      expect(JSON::Validator.fully_validate(dashboard_schema, result[:dashboard])).to be_empty
    end
  end
end
