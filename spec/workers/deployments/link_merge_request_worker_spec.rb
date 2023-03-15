# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Deployments::LinkMergeRequestWorker, feature_category: :continuous_delivery do
  subject(:worker) { described_class.new }

  describe '#perform' do
    it 'links merge requests to the deployment' do
      deployment = create(:deployment)
      service = instance_double(Deployments::LinkMergeRequestsService)

      expect(Deployments::LinkMergeRequestsService)
          .to receive(:new)
                  .with(deployment)
                  .and_return(service)

      expect(service).to receive(:execute)

      worker.perform(deployment.id)
    end

    it 'does not link merge requests when the deployment is not found' do
      expect(Deployments::LinkMergeRequestsService).not_to receive(:new)

      worker.perform(non_existing_record_id)
    end
  end

  context 'idempotent' do
    include_examples 'an idempotent worker' do
      let(:project) { create(:project, :repository) }
      let(:environment) { create(:environment, project: project) }
      let(:deployment) { create(:deployment, :success, project: project, environment: environment) }
      let(:job_args) { deployment.id }

      it 'links merge requests to deployment' do
        mr1 = create(
          :merge_request,
          :merged,
          source_project: project,
          target_project: project,
          source_branch: 'source1',
          target_branch: deployment.ref
        )

        mr2 = create(
          :merge_request,
          :merged,
          source_project: project,
          target_project: project,
          source_branch: 'source2',
          target_branch: deployment.ref
        )

        mr3 = create(
          :merge_request,
          :merged,
          source_project: project,
          target_project: project,
          target_branch: 'foo'
        )

        subject

        expect(deployment.merge_requests).to include(mr1, mr2)
        expect(deployment.merge_requests).not_to include(mr3)
      end
    end
  end
end
