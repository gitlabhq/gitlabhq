# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Deployments::UpdateEnvironmentWorker, feature_category: :continuous_delivery do
  subject(:worker) { described_class.new }

  context 'when successful deployment' do
    let(:deployment) { create(:deployment, :success) }

    it 'executes Deployments::UpdateEnvironmentService' do
      service = instance_double(Deployments::UpdateEnvironmentService)

      expect(Deployments::UpdateEnvironmentService)
          .to receive(:new)
                  .with(deployment)
                  .and_return(service)

      expect(service).to receive(:execute)

      worker.perform(deployment.id)
    end
  end

  context 'when canceled deployment' do
    let(:deployment) { create(:deployment, :canceled) }

    it 'does not execute Deployments::UpdateEnvironmentService' do
      expect(Deployments::UpdateEnvironmentService).not_to receive(:new)

      worker.perform(deployment.id)
    end
  end

  context 'when deploy record does not exist' do
    it 'does not execute Deployments::UpdateEnvironmentService' do
      expect(Deployments::UpdateEnvironmentService).not_to receive(:new)

      worker.perform(non_existing_record_id)
    end
  end

  context 'idempotent' do
    include_examples 'an idempotent worker' do
      let(:project) { create(:project, :repository) }
      let(:environment) { create(:environment, name: 'production') }
      let(:deployment) { create(:deployment, :success, project: project, environment: environment) }
      let(:merge_request) { create(:merge_request, target_branch: 'master', source_branch: 'feature', source_project: project) }
      let(:job_args) { deployment.id }

      before do
        merge_request.metrics.update!(merged_at: 1.hour.ago)
      end

      it 'updates merge requests metrics' do
        subject

        expect(merge_request.reload.metrics.first_deployed_to_production_at)
            .to be_like_time(deployment.finished_at)
      end
    end
  end
end
