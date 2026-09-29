# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EnvironmentStatusEntity, feature_category: :continuous_delivery do
  let_it_be(:maintainer) { create(:user) }
  let_it_be_with_reload(:deployment) { create(:deployment, :succeed, :review_app) }
  let_it_be(:environment) { deployment.environment }
  let_it_be(:project) { deployment.project }
  let_it_be(:merge_request) do
    create(:merge_request, :deployed_review_app, deployment: deployment, source_project: project)
  end

  let(:non_member) { build_stubbed(:user) }
  let(:user) { non_member }
  let(:request) { double('request', project: project) }
  let(:environment_status) { EnvironmentStatus.new(project, environment, merge_request, merge_request.diff_head_sha) }
  let(:entity) { described_class.new(environment_status, request: request) }

  subject(:serialized_entity) { entity.as_json }

  before_all do
    project.add_maintainer(maintainer)
    deployment.update!(sha: merge_request.diff_head_sha)
  end

  before do
    allow(request).to receive(:current_user).and_return(user)
  end

  it 'exposes the environment status attributes' do
    is_expected.to include(
      :id, :name, :url, :external_url, :external_url_formatted, :deployed_at, :deployed_at_formatted,
      :details, :changes, :status, :environment_available, :deployment_approved
    ).and exclude(:retry_url, :stop_url)
  end

  context 'when the user is project maintainer' do
    let(:user) { maintainer }

    it { is_expected.to include(:stop_url, :retry_url) }
  end

  describe '#details' do
    it 'passes playable_build and playable_job options to DeploymentEntity' do
      expect(DeploymentEntity).to receive(:represent).with(
        deployment,
        hash_including(only: [:playable_build, :playable_job])
      ).and_call_original

      serialized_entity
    end
  end
end
