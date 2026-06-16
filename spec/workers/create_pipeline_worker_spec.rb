# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CreatePipelineWorker, feature_category: :pipeline_composition do
  describe '.sidekiq_retries_exhausted' do
    let_it_be(:project) { create(:project) }
    let(:job) { { 'args' => [project.id, non_existing_record_id, 'main', :push, {}, {}] } }

    it 'calls perform_failure with extracted args and the exception' do
      exception = RuntimeError.new('something went wrong')

      expect_next_instance_of(described_class) do |worker|
        expect(worker).to receive(:perform_failure).with(project.id, 'main', exception, {})
      end

      described_class.sidekiq_retries_exhausted_block.call(job, exception)
    end
  end

  describe '#perform_failure' do
    let_it_be(:project) { create(:project) }

    it 'logs the exception message as the error' do
      exception = RuntimeError.new('something went wrong')

      expect(Sidekiq.logger).to receive(:warn).with(hash_including(
        class: 'CreatePipelineWorker',
        project_id: project.id,
        project_path: project.full_path,
        message: 'Error creating pipeline',
        errors: 'something went wrong'
      ))

      described_class.new.perform_failure(project.id, 'main', exception)
    end

    context 'when project is not found' do
      it 'does not log' do
        expect(Sidekiq.logger).not_to receive(:warn)

        described_class.new.perform_failure(non_existing_record_id, 'main', RuntimeError.new)
      end
    end
  end

  describe '#perform' do
    let(:worker) { described_class.new }
    let_it_be(:project) { create(:project) }
    let(:user) { create(:user) }
    let(:create_pipeline_service) { instance_double(Ci::CreatePipelineService) }
    let(:pipeline) { instance_double(Ci::Pipeline, persisted?: true) }
    let(:perform_args) do
      [
        project.id, user.id, project.default_branch, :web,
        { 'save_on_errors' => false }, { 'pipeline_creation_request' => { 'key' => 'test-key' } }
      ]
    end

    shared_examples 'does not call the Service' do
      specify do
        expect(Ci::CreatePipelineService).not_to receive(:new)
        expect { subject }.not_to raise_exception
      end
    end

    context 'when a project not found' do
      subject(:perform) { worker.perform(non_existing_record_id, create(:user).id, 'master', :web) }

      it_behaves_like 'does not call the Service'
    end

    context 'when a user not found' do
      subject(:perform) { worker.perform(project.id, non_existing_record_id, project.default_branch, :web) }

      it_behaves_like 'does not call the Service'
    end

    context 'when everything is ok' do
      let(:service_response) { instance_double(ServiceResponse, payload: pipeline, error?: false) }

      it 'calls the Service' do
        expect(Ci::CreatePipelineService).to receive(:new)
          .with(project, user, ref: project.default_branch, pipeline_creation_request: { 'key' => 'test-key' })
          .and_return(create_pipeline_service)
        expect(create_pipeline_service).to receive(:execute).with(:web, { save_on_errors: false })
                                                            .and_return(service_response)
        expect(worker).not_to receive(:log_pipeline_errors)

        worker.perform(*perform_args)
      end
    end

    context 'when CreatePipelineService responds with an error' do
      let(:service_response) do
        instance_double(ServiceResponse, payload: pipeline, error?: true, message: 'error message')
      end

      before do
        allow(Ci::CreatePipelineService).to receive(:new).and_return(create_pipeline_service)
        allow(create_pipeline_service).to receive(:execute).and_return(service_response)
      end

      it 'logs the error' do
        expect(Ci::CreatePipelineService).to receive(:new)
          .with(project, user, ref: project.default_branch, pipeline_creation_request: { 'key' => 'test-key' })
        expect(create_pipeline_service).to receive(:execute).with(:web, { save_on_errors: false })
        expect(Sidekiq.logger).to receive(:warn).with(hash_including(
          class: 'CreatePipelineWorker',
          project_id: project.id,
          project_path: project.full_path,
          message: 'Error creating pipeline',
          errors: 'error message'
        ))

        worker.perform(*perform_args)
      end
    end

    context 'when reference not found retry conditions are met' do
      let(:blank_sha) { Gitlab::Git::SHA1_BLANK_SHA }
      let(:ref_not_found_message) { Gitlab::Ci::Pipeline::Chain::Validate::Repository::REFERENCE_NOT_FOUND_MESSAGE }
      let(:service_response) { instance_double(ServiceResponse, error?: true, message: ref_not_found_message, payload: pipeline) }
      let(:push_args) { [project.id, user.id, project.default_branch, :push, {}, { 'before' => blank_sha }] }

      before do
        allow(Ci::CreatePipelineService).to receive(:new).and_return(create_pipeline_service)
        allow(create_pipeline_service).to receive(:execute).and_return(service_response)
      end

      context 'when ci_create_pipeline_worker_retry_on_reference_not_found feature flag is enabled' do
        before do
          stub_feature_flags(ci_create_pipeline_worker_retry_on_reference_not_found: project)
        end

        it 'raises ReferenceNotFoundError without logging' do
          expect(Sidekiq.logger).not_to receive(:warn)

          expect { worker.perform(*push_args) }
            .to raise_error(described_class::ReferenceNotFoundError)
        end

        context 'when before SHA is not blank' do
          let(:push_args) do
            [project.id, user.id, project.default_branch, :push, {}, { 'before' => 'abc123def456abc123def456abc123def456abc1' }]
          end

          it 'does not raise and logs the error instead' do
            expect(Sidekiq.logger).to receive(:warn)

            expect { worker.perform(*push_args) }.not_to raise_error
          end
        end

        context 'when error message is not "Reference not found"' do
          let(:service_response) { instance_double(ServiceResponse, error?: true, message: 'some other error', payload: pipeline) }

          it 'does not raise and logs the error instead' do
            expect(Sidekiq.logger).to receive(:warn)

            expect { worker.perform(*push_args) }.not_to raise_error
          end
        end
      end

      context 'when ci_create_pipeline_worker_retry_on_reference_not_found feature flag is disabled' do
        before do
          stub_feature_flags(ci_create_pipeline_worker_retry_on_reference_not_found: false)
        end

        it 'does not raise and logs the error instead' do
          expect(Sidekiq.logger).to receive(:warn)

          expect { worker.perform(*push_args) }.not_to raise_error
        end
      end
    end
  end
end
