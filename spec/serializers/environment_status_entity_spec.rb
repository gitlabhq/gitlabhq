# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EnvironmentStatusEntity do
  let_it_be(:non_member) { create(:user) }
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:deployment) { create(:deployment, :succeed, :review_app) }
  let_it_be(:merge_request) { create(:merge_request, :deployed_review_app, deployment: deployment) }
  let_it_be(:environment) { deployment.environment }
  let_it_be(:project) { deployment.project }

  let(:user) { non_member }
  let(:request) { double('request', project: project) }
  let(:environment_status) { EnvironmentStatus.new(project, environment, merge_request, merge_request.diff_head_sha) }
  let(:entity) { described_class.new(environment_status, request: request) }

  subject { entity.as_json }

  before_all do
    project.add_maintainer(maintainer)
    deployment.update!(sha: merge_request.diff_head_sha)
  end

  before do
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
  it { is_expected.to include(:environment_available) }

  it { is_expected.not_to include(:retry_url) }
  it { is_expected.not_to include(:stop_url) }

  context 'when the user is project maintainer' do
    let(:user) { maintainer }

    it { is_expected.to include(:stop_url) }
    it { is_expected.to include(:retry_url) }
  end
end
