require 'spec_helper'

describe EnvironmentStatusEntity do
  let(:user)    { create(:user) }
  let(:request) { double('request') }

  let(:deployment)    { create(:deployment, :succeed, :review_app) }
  let(:environment)   { deployment.environment }
  let(:project)       { deployment.project }
  let(:merge_request) { create(:merge_request, :deployed_review_app, deployment: deployment) }

  let(:environment_status) { EnvironmentStatus.new(environment, merge_request, merge_request.diff_head_sha) }
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
  it { is_expected.to include(:changes) }
  it { is_expected.to include(:status) }

  it { is_expected.not_to include(:stop_url) }
  it { is_expected.not_to include(:metrics_url) }
  it { is_expected.not_to include(:metrics_monitoring_url) }

  context 'when :ci_environments_status_changes feature flag is disabled' do
    before do
      stub_feature_flags(ci_environments_status_changes: false)
    end

    it { is_expected.not_to include(:changes) }
  end

  context 'when the user is project maintainer' do
    before do
      project.add_maintainer(user)
    end

    it { is_expected.to include(:stop_url) }
  end
end
