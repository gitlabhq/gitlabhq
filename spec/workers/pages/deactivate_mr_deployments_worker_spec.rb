# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pages::DeactivateMrDeploymentsWorker, feature_category: :pages do
  subject(:worker) { described_class.new }

  describe '#perform' do
    let(:merge_request) { create(:merge_request) }
    let(:pipeline_1) { create(:ci_pipeline, merge_request: merge_request) }
    let(:pipeline_2) { create(:ci_pipeline, merge_request: merge_request) }

    context 'when MR does not have a Pages Build' do
      it 'does not raise an error' do
        expect { worker.perform(merge_request) }.not_to raise_error
      end
    end

    context 'when MR does have a Pages Build' do
      let(:build_1) { create(:ci_build, pipeline: pipeline_1) }
      let(:build_2) { create(:ci_build, pipeline: pipeline_2) }

      context 'with a path_prefix' do
        it 'deactivates the deployment', :freeze_time do
          pages_deployment_1 = create(:pages_deployment, path_prefix: '/foo', ci_build: build_1)
          pages_deployment_2 = create(:pages_deployment, path_prefix: '/bar', ci_build: build_1)

          expect { worker.perform(merge_request.id) }
            .to change { pages_deployment_1.reload.deleted_at }.from(nil).to(Time.now.utc)
            .and change { pages_deployment_2.reload.deleted_at }.from(nil).to(Time.now.utc)
        end
      end

      context 'without a path_prefix' do
        it 'does not deactivate the deployment' do
          pages_deployment_1 = create(:pages_deployment, path_prefix: '', ci_build: build_1)

          expect { worker.perform(merge_request) }
            .to not_change { pages_deployment_1.reload.deleted_at }
        end
      end
    end
  end
end
