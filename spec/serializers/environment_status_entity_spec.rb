# frozen_string_literal: true

require 'spec_helper'

describe EnvironmentStatusEntity do
  let(:user)    { create(:user) }
  let(:request) { double('request', project: project) }

  let(:deployment)    { create(:deployment, :succeed, :review_app) }
  let(:environment)   { deployment.environment }
  let(:project)       { deployment.project }
  let(:merge_request) { create(:merge_request, :deployed_review_app, deployment: deployment) }

  let(:environment_status) { EnvironmentStatus.new(project, environment, merge_request, merge_request.diff_head_sha) }
  let(:entity)             { described_class.new(environment_status, request: request) }

  subject { entity.as_json }

  before do
    deployment.update(sha: merge_request.diff_head_sha)
    allow(request).to receive(:current_user).and_return(user)
  end

  it { is_expected.to include(:id) }
  it { is_expected.to include(:name) }
  it { is_expected.to include(:url) }
  it { is_expected.to include(:external_url) }
  it { is_expected.to include(:external_url_formatted) }
  it { is_expected.to include(:deployed_at) }
  it { is_expected.to include(:deployed_at_formatted) }
  it { is_expected.to include(:details) }
  it { is_expected.to include(:changes) }
  it { is_expected.to include(:status) }

  it { is_expected.not_to include(:stop_url) }
  it { is_expected.not_to include(:metrics_url) }
  it { is_expected.not_to include(:metrics_monitoring_url) }

  context 'when the user is project maintainer' do
    before do
      project.add_maintainer(user)
    end

    it { is_expected.to include(:stop_url) }
  end

  context 'when deployment has metrics' do
    let(:prometheus_adapter) { double('prometheus_adapter', can_query?: true) }

    let(:simple_metrics) do
      {
        success: true,
        metrics: {},
        last_update: 42
      }
    end

    before do
      project.add_maintainer(user)
      allow(deployment).to receive(:prometheus_adapter).and_return(prometheus_adapter)
      allow(entity).to receive(:deployment).and_return(deployment)

      expect_next_instance_of(DeploymentMetrics) do |deployment_metrics|
        allow(deployment_metrics).to receive(:prometheus_adapter).and_return(prometheus_adapter)

        allow(prometheus_adapter).to receive(:query)
          .with(:deployment, deployment).and_return(simple_metrics)
      end
    end

    context 'when deployment succeeded' do
      let(:deployment)    { create(:deployment, :succeed, :review_app) }

      it 'returns metrics url' do
        expect(subject[:metrics_url])
          .to eq("/#{project.full_path}/environments/#{environment.id}/deployments/#{deployment.iid}/metrics")
      end
    end

    context 'when deployment is running' do
      let(:deployment)    { create(:deployment, :running, :review_app) }

      it 'does not return metrics url' do
        expect(subject[:metrics_url]).to be_nil
      end
    end
  end
end
