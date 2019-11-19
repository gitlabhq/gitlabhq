# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::DataBuilder::Deployment do
  describe '.build' do
    it 'returns the object kind for a deployment' do
      deployment = build(:deployment)

      data = described_class.build(deployment)

      expect(data[:object_kind]).to eq('deployment')
    end

    it 'returns data for the given build' do
      environment = create(:environment, name: "somewhere")
      project = create(:project, :repository, name: 'myproj')
      commit = project.commit('HEAD')
      deployment = create(:deployment, status: :failed, environment: environment, sha: commit.sha, project: project)
      deployable = deployment.deployable
      expected_deployable_url = Gitlab::Routing.url_helpers.project_job_url(deployable.project, deployable)
      expected_user_url = Gitlab::Routing.url_helpers.user_url(deployment.user)
      expected_commit_url = Gitlab::UrlBuilder.build(commit)

      data = described_class.build(deployment)

      expect(data[:status]).to eq('failed')
      expect(data[:deployable_id]).to eq(deployable.id)
      expect(data[:deployable_url]).to eq(expected_deployable_url)
      expect(data[:environment]).to eq("somewhere")
      expect(data[:project]).to eq(project.hook_attrs)
      expect(data[:short_sha]).to eq(deployment.short_sha)
      expect(data[:user]).to eq(deployment.user.hook_attrs)
      expect(data[:user_url]).to eq(expected_user_url)
      expect(data[:commit_url]).to eq(expected_commit_url)
      expect(data[:commit_title]).to eq(commit.title)
    end

    it 'does not include the deployable URL when there is no deployable' do
      deployment = create(:deployment, status: :failed, deployable: nil)
      data = described_class.build(deployment)

      expect(data[:deployable_url]).to be_nil
    end
  end
end
