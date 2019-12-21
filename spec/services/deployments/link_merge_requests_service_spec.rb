# frozen_string_literal: true

require 'spec_helper'

describe Deployments::LinkMergeRequestsService do
  let(:project) { create(:project, :repository) }

  describe '#execute' do
    context 'when the deployment did not succeed' do
      it 'does nothing' do
        deploy = create(:deployment, :failed)

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
          sha: '7975be0116940bf2ad4321f79d02a55c5f7779aa'
        )

        deploy2 = create(
          :deployment,
          :success,
          project: deploy1.project,
          environment: deploy1.environment,
          sha: 'ddd0f15ae83993f5cb66a927a28673882e99100b'
        )

        service = described_class.new(deploy2)

        expect(service)
          .to receive(:link_merge_requests_for_range)
          .with(
            '7975be0116940bf2ad4321f79d02a55c5f7779aa',
            'ddd0f15ae83993f5cb66a927a28673882e99100b'
          )

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
        merge_commit_sha: '1e292f8fedd741b75372e19097c76d327140c312',
        source_project: project,
        target_project: project
      )

      mr2 = create(
        :merge_request,
        :merged,
        merge_commit_sha: '2d1db523e11e777e49377cfb22d368deec3f0793',
        source_project: project,
        target_project: project
      )

      described_class.new(deploy).link_merge_requests_for_range(
        '7975be0116940bf2ad4321f79d02a55c5f7779aa',
        'ddd0f15ae83993f5cb66a927a28673882e99100b'
      )

      expect(deploy.merge_requests).to include(mr1, mr2)
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
