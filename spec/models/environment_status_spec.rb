# frozen_string_literal: true

require 'spec_helper'

describe EnvironmentStatus do
  include ProjectForksHelper

  let(:deployment)    { create(:deployment, :succeed, :review_app) }
  let(:environment)   { deployment.environment }
  let(:project)       { deployment.project }
  let(:merge_request) { create(:merge_request, :deployed_review_app, deployment: deployment) }
  let(:sha)           { deployment.sha }

  subject(:environment_status) { described_class.new(project, environment, merge_request, sha) }

  it { is_expected.to delegate_method(:id).to(:environment) }
  it { is_expected.to delegate_method(:name).to(:environment) }
  it { is_expected.to delegate_method(:deployed_at).to(:deployment) }
  it { is_expected.to delegate_method(:status).to(:deployment) }

  describe '#project' do
    subject { environment_status.project }

    it { is_expected.to eq(project) }
  end

  describe '#merge_request' do
    subject { environment_status.merge_request }

    it { is_expected.to eq(merge_request) }
  end

  describe '#deployment' do
    subject { environment_status.deployment }

    it { is_expected.to eq(deployment) }
  end

  # $ git diff --stat pages-deploy-target...pages-deploy
  # .gitlab/route-map.yml              |  5 +++++
  # files/html/500.html                | 13 -------------
  # files/html/page.html               |  3 +++
  # files/js/application.js            |  3 +++
  # files/markdown/ruby-style-guide.md |  4 ++++
  # pages-deploy.txt                   |  1 +
  #
  # $ cat .gitlab/route-map.yml
  # - source: /files\/markdown\/(.+)\.md$/
  #   public: '\1.html'
  #
  # - source: /files\/(.+)/
  #   public: '\1'
  describe '#changes' do
    it 'contains only added and modified public pages' do
      expect(environment_status.changes).to contain_exactly(
        {
          path: 'ruby-style-guide.html',
          external_url: "#{environment.external_url}/ruby-style-guide.html"
        }, {
          path: 'html/page.html',
          external_url: "#{environment.external_url}/html/page.html"
        }
      )
    end
  end

  describe '.for_merge_request' do
    let(:admin) { create(:admin) }
    let!(:pipeline) { create(:ci_pipeline, sha: sha, merge_requests_as_head_pipeline: [merge_request]) }

    it 'is based on merge_request.diff_head_sha' do
      expect(merge_request).to receive(:diff_head_sha)
      expect(merge_request).not_to receive(:merge_commit_sha)

      described_class.for_merge_request(merge_request, admin)
    end
  end

  describe '.after_merge_request' do
    let(:admin)    { create(:admin) }
    let(:pipeline) { create(:ci_pipeline, sha: sha) }

    before do
      merge_request.mark_as_merged!
    end

    it 'is based on merge_request.merge_commit_sha' do
      expect(merge_request).to receive(:merge_commit_sha)
      expect(merge_request).not_to receive(:diff_head_sha)

      described_class.after_merge_request(merge_request, admin)
    end
  end

  describe '.for_deployed_merge_request' do
    context 'when a merge request has no explicitly linked deployments' do
      it 'returns the statuses based on the CI pipelines' do
        mr = create(:merge_request, :merged)

        expect(described_class)
          .to receive(:after_merge_request)
          .with(mr, mr.author)
          .and_return([])

        statuses = described_class.for_deployed_merge_request(mr, mr.author)

        expect(statuses).to eq([])
      end
    end

    context 'when a merge request has explicitly linked deployments' do
      let(:merge_request) { create(:merge_request, :merged) }

      let(:environment) do
        create(:environment, project: merge_request.target_project)
      end

      it 'returns the statuses based on the linked deployments' do
        deploy = create(
          :deployment,
          :success,
          project: merge_request.target_project,
          environment: environment,
          deployable: nil
        )

        deploy.link_merge_requests(merge_request.target_project.merge_requests)

        statuses = described_class
          .for_deployed_merge_request(merge_request, merge_request.author)

        expect(statuses.length).to eq(1)
        expect(statuses[0].environment).to eq(environment)
        expect(statuses[0].merge_request).to eq(merge_request)
      end

      it 'excludes environments the user can not see' do
        deploy = create(
          :deployment,
          :success,
          project: merge_request.target_project,
          environment: environment,
          deployable: nil
        )

        deploy.link_merge_requests(merge_request.target_project.merge_requests)

        statuses = described_class
          .for_deployed_merge_request(merge_request, create(:user))

        expect(statuses).to be_empty
      end

      it 'excludes deployments that have the status "created"' do
        deploy = create(
          :deployment,
          :created,
          project: merge_request.target_project,
          environment: environment,
          deployable: nil
        )

        deploy.link_merge_requests(merge_request.target_project.merge_requests)

        statuses = described_class
          .for_deployed_merge_request(merge_request, merge_request.author)

        expect(statuses).to be_empty
      end
    end
  end

  describe '.build_environments_status' do
    subject { described_class.send(:build_environments_status, merge_request, user, pipeline) }

    let!(:build) { create(:ci_build, :with_deployment, :deploy_to_production, pipeline: pipeline) }
    let(:environment) { build.deployment.environment }
    let(:user) { project.owner }

    context 'when environment is created on a forked project' do
      let(:project) { create(:project, :repository) }
      let(:forked) { fork_project(project, user, repository: true) }
      let(:sha) { forked.commit.sha }
      let(:pipeline) { create(:ci_pipeline, sha: sha, project: forked) }

      let(:merge_request) do
        create(:merge_request,
               source_project: forked,
               target_project: project,
               target_branch: 'master',
               head_pipeline: pipeline)
      end

      it 'returns environment status', :sidekiq_might_not_need_inline do
        expect(subject.count).to eq(1)
        expect(subject[0].environment).to eq(environment)
        expect(subject[0].merge_request).to eq(merge_request)
        expect(subject[0].sha).to eq(sha)
      end
    end

    context 'when environment is created on a target project' do
      let(:project) { create(:project, :repository) }
      let(:sha) { project.commit.sha }
      let(:pipeline) { create(:ci_pipeline, sha: sha, project: project) }

      let(:merge_request) do
        create(:merge_request,
               source_project: project,
               source_branch: 'feature',
               target_project: project,
               target_branch: 'master',
               head_pipeline: pipeline)
      end

      it 'returns environment status' do
        expect(subject.count).to eq(1)
        expect(subject[0].environment).to eq(environment)
        expect(subject[0].merge_request).to eq(merge_request)
        expect(subject[0].sha).to eq(sha)
      end

      context 'when the build stops an environment' do
        let!(:build) { create(:ci_build, :stop_review_app, pipeline: pipeline) }

        it 'does not return environment status' do
          expect(subject.count).to eq(0)
        end
      end

      context 'when user does not have a permission to see the environment' do
        let(:user) { create(:user) }

        it 'does not return environment status' do
          expect(subject.count).to eq(0)
        end
      end

      context 'when multiple deployments with the same SHA in different environments' do
        let(:pipeline2) { create(:ci_pipeline, sha: sha, project: project) }
        let!(:build2) { create(:ci_build, :start_review_app, pipeline: pipeline2) }

        it 'returns deployments related to the head pipeline' do
          expect(subject.count).to eq(1)
          expect(subject[0].environment).to eq(environment)
          expect(subject[0].merge_request).to eq(merge_request)
          expect(subject[0].sha).to eq(sha)
        end
      end

      context 'when multiple deployments in the same pipeline for the same environments' do
        let!(:build2) { create(:ci_build, :deploy_to_production, pipeline: pipeline) }

        it 'returns unique entries' do
          expect(subject.count).to eq(1)
          expect(subject[0].environment).to eq(environment)
          expect(subject[0].merge_request).to eq(merge_request)
          expect(subject[0].sha).to eq(sha)
        end
      end

      context 'when environment is stopped' do
        before do
          environment.stop!
        end

        it 'does not return environment status' do
          expect(subject.count).to eq(0)
        end
      end
    end
  end
end
