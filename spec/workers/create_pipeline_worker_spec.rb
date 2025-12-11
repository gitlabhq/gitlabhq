# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CreatePipelineWorker, feature_category: :pipeline_composition do
  describe '#perform' do
    let(:worker) { described_class.new }

    context 'when a project not found' do
      it 'does not call the Service' do
        expect(Ci::CreatePipelineService).not_to receive(:new)
        expect { worker.perform(non_existing_record_id, create(:user).id, 'master', :web) }.not_to raise_exception
      end
    end

    context 'when a user not found' do
      let_it_be(:project) { create(:project) }

      it 'does not call the Service' do
        expect(Ci::CreatePipelineService).not_to receive(:new)
        expect { worker.perform(project.id, non_existing_record_id, project.default_branch, :web) }.not_to raise_exception
      end
    end

    context 'when everything is ok' do
      let_it_be(:project) { create(:project) }
      let(:user) { create(:user) }
      let(:create_pipeline_service) { instance_double(Ci::CreatePipelineService) }
      let(:service_response) { instance_double(ServiceResponse, payload: pipeline, error?: false) }
      let(:pipeline) { instance_double(Ci::Pipeline, persisted?: true) }

      it 'calls the Service' do
        expect(Ci::CreatePipelineService).to receive(:new)
          .with(project, user, ref: project.default_branch, pipeline_creation_request: { 'key' => 'test-key' })
          .and_return(create_pipeline_service)
        expect(create_pipeline_service).to receive(:execute).with(:web, { save_on_errors: false })
                                                            .and_return(service_response)
        expect(worker).not_to receive(:log_pipeline_errors)

        worker.perform(
          project.id, user.id, project.default_branch, :web,
          { 'save_on_errors' => false }, { 'pipeline_creation_request' => { 'key' => 'test-key' } }
        )
      end
    end

    context 'when CreatePipelineService responds with an error' do
      let_it_be(:project) { create(:project) }
      let(:user) { create(:user) }
      let(:create_pipeline_service) { instance_double(Ci::CreatePipelineService) }
      let(:service_response) { instance_double(ServiceResponse, payload: pipeline, error?: true, message: 'error message') }
      let(:pipeline) { instance_double(Ci::Pipeline, persisted?: true) }

      it 'logs the error' do
        expect(Ci::CreatePipelineService).to receive(:new)
                                               .with(project, user, ref: project.default_branch, pipeline_creation_request: { 'key' => 'test-key' })
                                               .and_return(create_pipeline_service)
        expect(create_pipeline_service).to receive(:execute).with(:web, { save_on_errors: false })
                                                            .and_return(service_response)

        expect(Sidekiq.logger).to receive(:warn).with(hash_including(
          class: 'CreatePipelineWorker',
          project_id: project.id,
          project_path: project.full_path,
          message: 'Error creating pipeline',
          errors: 'error message'
        ))

        worker.perform(
          project.id, user.id, project.default_branch, :web,
          { 'save_on_errors' => false }, { 'pipeline_creation_request' => { 'key' => 'test-key' } }
        )
      end
    end
  end
end
