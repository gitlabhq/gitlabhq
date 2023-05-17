# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ci::Deployments::DestroyService, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project, :repository) }

  let(:environment) { create(:environment, project: project) }
  let(:commits) { project.repository.commits(nil, { limit: 3 }) }
  let!(:deploy) do
    create(
      :deployment,
      :success,
      project: project,
      environment: environment,
      deployable: nil,
      sha: commits[2].sha
    )
  end

  let!(:running_deploy) do
    create(
      :deployment,
      :running,
      project: project,
      environment: environment,
      deployable: nil,
      sha: commits[1].sha
    )
  end

  let!(:old_deploy) do
    create(
      :deployment,
      :success,
      project: project,
      environment: environment,
      deployable: nil,
      sha: commits[0].sha,
      finished_at: 1.year.ago
    )
  end

  let(:user) { project.first_owner }

  subject { described_class.new(project, user) }

  context 'when deleting a deployment' do
    it 'delete is accepted for old deployment' do
      expect(subject.execute(old_deploy)).to be_success
    end

    it 'does not delete a running deployment' do
      response = subject.execute(running_deploy)
      expect(response).to be_an_error
      expect(response.message).to eq("Cannot destroy running deployment")
    end

    it 'does not delete the last deployment' do
      response = subject.execute(deploy)
      expect(response).to be_an_error
      expect(response.message).to eq("Deployment currently deployed to environment")
    end
  end
end
