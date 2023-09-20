# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::DataBuilder::Deployment, feature_category: :continuous_delivery do
  describe '.build' do
    it 'returns the object kind for a deployment' do
      deployment = build(:deployment, deployable: nil, environment: create(:environment))

      data = described_class.build(deployment, 'success', Time.current)

      expect(data[:object_kind]).to eq('deployment')
    end

    it 'returns data for the given build', :aggregate_failures do
      environment = create(:environment, name: 'somewhere/1', external_url: 'https://test.com')
      project = create(:project, :repository, name: 'myproj')
      commit = project.commit('HEAD')
      deployment = create(:deployment, status: :failed, environment: environment, sha: commit.sha, project: project)
      deployable = deployment.deployable
      expected_deployable_url = Gitlab::Routing.url_helpers.project_job_url(deployable.project, deployable)
      expected_user_url = Gitlab::Routing.url_helpers.user_url(deployment.deployed_by)
      expected_commit_url = Gitlab::UrlBuilder.build(commit)
      status_changed_at = Time.current

      data = described_class.build(deployment, 'failed', status_changed_at)

      expect(data[:status]).to eq('failed')
      expect(data[:status_changed_at]).to eq(status_changed_at)
      expect(data[:deployment_id]).to eq(deployment.id)
      expect(data[:deployable_id]).to eq(deployable.id)
      expect(data[:deployable_url]).to eq(expected_deployable_url)
      expect(data[:environment]).to eq('somewhere/1')
      expect(data[:environment_slug]).to eq('somewhere-1-78avk6')
      expect(data[:environment_external_url]).to eq('https://test.com')
      expect(data[:project]).to eq(project.hook_attrs)
      expect(data[:short_sha]).to eq(deployment.short_sha)
      expect(data[:user]).to eq(deployment.deployed_by.hook_attrs)
      expect(data[:user_url]).to eq(expected_user_url)
      expect(data[:commit_url]).to eq(expected_commit_url)
      expect(data[:commit_title]).to eq(commit.title)
      expect(data[:ref]).to eq(deployment.ref)
      expect(data[:environment_tier]).to eq('other')
    end

    it 'does not include the deployable URL when there is no deployable' do
      deployment = create(:deployment, status: :failed, deployable: nil)
      data = described_class.build(deployment, 'failed', Time.current)

      expect(data[:deployable_url]).to be_nil
    end

    it 'does not include the deployable URL when deployable is bridge' do
      project = create(:project, :repository)
      bridge = create(:ci_bridge, project: project)
      deployment = create(:deployment, status: :failed, project: project, deployable: bridge)
      data = described_class.build(deployment, 'failed', Time.current)

      expect(data[:deployable_url]).to be_nil
    end

    context 'when commit does not exist in the repository' do
      let_it_be(:project) { create(:project, :repository) }
      let_it_be(:deployment) { create(:deployment, project: project) }

      subject(:data) { described_class.build(deployment, 'created', Time.current) }

      before_all do
        project.repository.remove
      end

      it 'returns nil for commit_url' do
        expect(data[:commit_url]).to be_nil
      end

      it 'returns nil for commit_title' do
        expect(data[:commit_title]).to be_nil
      end
    end

    context 'when deployed_by is nil' do
      let_it_be(:deployment) { create(:deployment, user: nil, deployable: nil) }

      subject(:data) { described_class.build(deployment, 'created', Time.current) }

      before_all do
        deployment.user = nil
      end

      it 'returns nil for user' do
        expect(data[:user]).to be_nil
      end

      it 'returns nil for user_url' do
        expect(data[:user_url]).to be_nil
      end
    end
  end
end
