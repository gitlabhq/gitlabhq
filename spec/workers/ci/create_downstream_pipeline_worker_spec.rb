# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CreateDownstreamPipelineWorker, feature_category: :continuous_integration do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

  let(:bridge) { create(:ci_bridge, user: user, pipeline: pipeline) }

  describe '#perform' do
    context 'when bridge exists' do
      let(:service) { double('pipeline creation service') }

      let(:service_result) { ServiceResponse.success(payload: instance_double(Ci::Pipeline, id: 100)) }

      it 'calls cross project pipeline creation service and logs the new pipeline id' do
        expect(Ci::CreateDownstreamPipelineService)
          .to receive(:new)
          .with(project, user)
          .and_return(service)

        expect(service)
          .to receive(:execute)
          .with(bridge)
          .and_return(service_result)

        worker = described_class.new
        worker.perform(bridge.id)

        expect(worker.logging_extras).to eq({ "extra.ci_create_downstream_pipeline_worker.new_pipeline_id" => 100 })
      end

      context 'when downstream pipeline creation errors' do
        let(:service_result) { ServiceResponse.error(message: 'Already has a downstream pipeline') }

        it 'calls cross project pipeline creation service and logs the error' do
          expect(Ci::CreateDownstreamPipelineService)
            .to receive(:new)
            .with(project, user)
            .and_return(service)

          expect(service)
            .to receive(:execute)
            .with(bridge)
            .and_return(service_result)

          worker = described_class.new
          worker.perform(bridge.id)

          expect(worker.logging_extras).to eq(
            {
              "extra.ci_create_downstream_pipeline_worker.create_error_message" => "Already has a downstream pipeline"
            }
          )
        end
      end
    end

    context 'when bridge does not exist' do
      it 'does nothing' do
        expect(Ci::CreateDownstreamPipelineService)
          .not_to receive(:new)

        described_class.new.perform(non_existing_record_id)
      end
    end
  end
end
