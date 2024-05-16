# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Deployments::LinkMergeRequestsService, feature_category: :continuous_delivery do
  let(:project) { create(:project, :repository) }

  # *   ddd0f15 Merge branch 'po-fix-test-env-path' into 'master'
  # |\
  # | * 2d1db52 Correct test_env.rb path for adding branch
  # |/
  # *   1e292f8 Merge branch 'cherry-pick-ce369011' into 'master'
  # |\
  # | * c1c67ab Add file with a _flattable_ path
  # |/
  # *   7975be0 Merge branch 'rd-add-file-larger-than-1-mb' into 'master'
  let_it_be(:first_deployment_sha) { '7975be0116940bf2ad4321f79d02a55c5f7779aa' }
  let_it_be(:mr1_merge_commit_sha) { '1e292f8fedd741b75372e19097c76d327140c312' }
  let_it_be(:mr2_merge_commit_sha) { 'ddd0f15ae83993f5cb66a927a28673882e99100b' }

  describe '#execute' do
    context 'when the deployment is for a review environment' do
      it 'does nothing' do
        environment =
          create(:environment, environment_type: 'review', name: 'review/foo')

        deploy = create(:deployment, :success, environment: environment)

        expect(deploy).not_to receive(:link_merge_requests)

        described_class.new(deploy).execute
      end
    end

    context 'when the deployment is for one of the production environments' do
      it 'links merge requests' do
        environment =
          create(:environment, environment_type: 'production', name: 'production/gcp')

        deploy = create(:deployment, :success, environment: environment)

        expect(deploy).to receive(:link_merge_requests).once

        described_class.new(deploy).execute
      end
    end

    context 'when the deployment failed' do
      it 'does nothing' do
        environment = create(:environment, name: 'foo')
        deploy = create(:deployment, :failed, environment: environment)

        expect(deploy).not_to receive(:link_merge_requests)

        described_class.new(deploy).execute
      end
    end

    context 'when there is a previous deployment' do
      it 'links all merge requests merged since the previous deployment' do
        deploy1 = create(
          :deployment,
          :success,
          project: project,
          sha: first_deployment_sha
        )

        deploy2 = create(
          :deployment,
          :success,
          project: deploy1.project,
          environment: deploy1.environment,
          sha: mr2_merge_commit_sha
        )

        service = described_class.new(deploy2)

        expect(service)
          .to receive(:link_merge_requests_for_range)
          .with(first_deployment_sha, mr2_merge_commit_sha)

        service.execute
      end
    end

    context 'when there are no previous deployments' do
      it 'links all merged merge requests' do
        deploy = create(:deployment, :success, project: project)
        service = described_class.new(deploy)

        expect(service).to receive(:link_all_merged_merge_requests)

        service.execute
      end
    end
  end

  describe '#link_merge_requests_for_range' do
    it 'links merge requests' do
      environment = create(:environment, project: project)
      deploy =
        create(:deployment, :success, project: project, environment: environment)

      mr1 = create(
        :merge_request,
        :merged,
        merge_commit_sha: mr1_merge_commit_sha,
        source_project: project,
        target_project: project
      )

      mr2 = create(
        :merge_request,
        :merged,
        merge_commit_sha: mr2_merge_commit_sha,
        source_project: project,
        target_project: project
      )

      described_class.new(deploy).link_merge_requests_for_range(
        first_deployment_sha,
        mr2_merge_commit_sha
      )

      expect(deploy.merge_requests).to include(mr1, mr2)
    end

    it 'links picked merge requests' do
      environment = create(:environment, project: project)
      deploy =
        create(:deployment, :success, project: project, environment: environment)

      picked_mr = create(
        :merge_request,
        :merged,
        merge_commit_sha: '123abc',
        source_project: project,
        target_project: project
      )

      mr1 = create(
        :merge_request,
        :merged,
        merge_commit_sha: mr1_merge_commit_sha,
        source_project: project,
        target_project: project
      )

      # mr1 includes c1c67abba which is a cherry-pick of the fake picked_mr merge request
      create(:track_mr_picking_note, noteable: picked_mr, project: project, commit_id: 'c1c67abbaf91f624347bb3ae96eabe3a1b742478')

      described_class.new(deploy).link_merge_requests_for_range(
        first_deployment_sha,
        mr1_merge_commit_sha
      )

      expect(deploy.merge_requests).to include(mr1, picked_mr)
    end

    it "doesn't link the same merge_request twice" do
      create(:merge_request, :merged, merge_commit_sha: mr1_merge_commit_sha, source_project: project)

      picked_mr = create(:merge_request, :merged, merge_commit_sha: '123abc', source_project: project)

      # the first MR includes c1c67abba which is a cherry-pick of the fake picked_mr merge request
      create(:track_mr_picking_note, noteable: picked_mr, project: project, commit_id: 'c1c67abbaf91f624347bb3ae96eabe3a1b742478')

      environment = create(:environment, project: project)
      old_deploy =
        create(:deployment, :success, project: project, environment: environment)

      # manually linking all the MRs to the old_deploy
      old_deploy.link_merge_requests(project.merge_requests)

      deploy =
        create(:deployment, :success, project: project, environment: environment)

      described_class.new(deploy).link_merge_requests_for_range(
        first_deployment_sha,
        mr1_merge_commit_sha
      )

      expect(deploy.merge_requests).to be_empty
    end

    context 'when the deploy commits are the merge_commit_sha and head_commit_sha of one merge_request' do
      let(:mr_head_commit_sha) { mr1_merge_commit_sha }
      let(:mr_merge_commit_sha) { mr2_merge_commit_sha }

      let!(:merge_request) do
        create(
          :merge_request,
          :merged,
          source_project: project,
          target_project: project,
          merge_commit_sha: mr_merge_commit_sha
        ).tap do |merge_request|
          create(:merge_request_diff, merge_request: merge_request, head_commit_sha: mr_head_commit_sha)
        end
      end

      let!(:environment) { create(:environment, project: project) }
      let!(:deploy) { create(:deployment, :success, project: project, environment: environment) }

      it 'only links the merge request once' do
        described_class.new(deploy).link_merge_requests_for_range(
          first_deployment_sha,
          mr2_merge_commit_sha
        )

        expect(deploy.merge_requests).to eq([merge_request])
      end
    end

    context "when merge request is fast-forward merged and commits are not squashed" do
      def create_fast_forward_merge_request(reference_commit_sha)
        create(
          :merge_request,
          :merged,
          source_project: project,
          target_project: project,
          merge_commit_sha: nil
        ).tap do |merge_request|
          create(:merge_request_diff, merge_request: merge_request, head_commit_sha: reference_commit_sha)
        end
      end

      let!(:merge_request_1) { create_fast_forward_merge_request(mr1_merge_commit_sha) }
      let!(:merge_request_2) { create_fast_forward_merge_request(mr2_merge_commit_sha) }

      let!(:environment) { create(:environment, project: project) }
      let!(:deploy) { create(:deployment, :success, project: project, environment: environment) }

      subject(:link_merge_requests_for_range) do
        described_class.new(deploy).link_merge_requests_for_range(
          first_deployment_sha,
          mr2_merge_commit_sha
        )
      end

      it "links merge requests by the HEAD commit sha of the MR's diff" do
        link_merge_requests_for_range

        expect(deploy.merge_requests).to match_array([merge_request_1, merge_request_2])
      end
    end

    context "when merge request is fast-forward merged and commits are squashed" do
      def create_fast_forward_merge_request(reference_commit_sha)
        create(
          :merge_request,
          :merged,
          source_project: project,
          target_project: project,
          merge_commit_sha: nil,
          squash_commit_sha: reference_commit_sha
        )
      end

      let!(:merge_request_1) { create_fast_forward_merge_request(mr1_merge_commit_sha) }
      let!(:merge_request_2) { create_fast_forward_merge_request(mr2_merge_commit_sha) }

      let!(:environment) { create(:environment, project: project) }
      let!(:deploy) { create(:deployment, :success, project: project, environment: environment) }

      subject(:link_merge_requests_for_range) do
        described_class.new(deploy).link_merge_requests_for_range(
          first_deployment_sha,
          mr2_merge_commit_sha
        )
      end

      it "links merge requests by the squash commit of the MR" do
        link_merge_requests_for_range

        expect(deploy.merge_requests).to match_array([merge_request_1, merge_request_2])
      end
    end
  end

  describe '#link_all_merged_merge_requests' do
    it 'links all merged merge requests targeting the deployed branch' do
      environment = create(:environment, project: project)
      deploy =
        create(:deployment, :success, project: project, environment: environment)

      mr1 = create(
        :merge_request,
        :merged,
        source_project: project,
        target_project: project,
        source_branch: 'source1',
        target_branch: deploy.ref
      )

      mr2 = create(
        :merge_request,
        :merged,
        source_project: project,
        target_project: project,
        source_branch: 'source2',
        target_branch: deploy.ref
      )

      mr3 = create(
        :merge_request,
        :merged,
        source_project: project,
        target_project: project,
        target_branch: 'foo'
      )

      described_class.new(deploy).link_all_merged_merge_requests

      expect(deploy.merge_requests).to include(mr1, mr2)
      expect(deploy.merge_requests).not_to include(mr3)
    end
  end
end
