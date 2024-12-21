# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ci::DestroyPipelineService, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be_with_refind(:pipeline) { create(:ci_pipeline, :success, project: project, sha: project.commit.id) }

  let(:service) { described_class.new(project, user) }

  shared_examples 'pipeline destruction service' do
    it 'destroys the pipeline' do
      response

      expect { pipeline.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'clears the cache', :use_clean_rails_redis_caching do
      create(:commit_status, :success, pipeline: pipeline, ref: pipeline.ref)

      expect(project.pipeline_status.has_status?).to be_truthy

      response

      # We need to reset lazy_latest_pipeline cache to simulate a new request
      BatchLoader::Executor.clear_current

      # Need to use find to avoid memoization
      expect(Project.find(project.id).pipeline_status.has_status?).to be_falsey
    end

    it 'does not log an audit event' do
      expect { response }.not_to change { AuditEvent.count }
    end

    context 'when the pipeline has jobs' do
      let!(:build) { create(:ci_build, project: project, pipeline: pipeline) }

      it 'destroys associated jobs' do
        response

        expect { build.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'destroys associated stages' do
        stages = pipeline.stages

        response

        expect(stages).to all(raise_error(ActiveRecord::RecordNotFound))
      end

      context 'when job has artifacts' do
        let!(:artifact) { create(:ci_job_artifact, :archive, job: build) }

        it 'destroys associated artifacts' do
          response

          expect { artifact.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end

        it 'inserts deleted objects for object storage files' do
          expect { response }.to change { Ci::DeletedObject.count }
        end
      end

      context 'when job has trace chunks' do
        before do
          stub_object_storage(connection_params: connection_params, remote_directory: 'artifacts')
          stub_artifacts_object_storage
        end

        let(:connection_params) { Gitlab.config.artifacts.object_store.connection.symbolize_keys }
        let(:connection) { ::Fog::Storage.new(connection_params) }
        let!(:trace_chunk) { create(:ci_build_trace_chunk, :fog_with_data, build: build) }

        it 'destroys associated trace chunks' do
          response

          expect { trace_chunk.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end

        it 'removes data from object store' do
          expect { response }.to change { Ci::BuildTraceChunks::Fog.new.data(trace_chunk) }
        end
      end
    end

    context 'when pipeline is in cancelable state', :sidekiq_inline do
      let!(:build) { create(:ci_build, :running, pipeline: pipeline) }
      let!(:child_pipeline) { create(:ci_pipeline, :running, child_of: pipeline) }
      let!(:child_build) { create(:ci_build, :running, pipeline: child_pipeline) }

      it 'cancels the pipelines sync' do
        cancel_pipeline_service = instance_double(::Ci::CancelPipelineService)
        expect(::Ci::CancelPipelineService)
          .to receive(:new)
          .with(pipeline: pipeline, current_user: user, cascade_to_children: true, execute_async: false)
          .and_return(cancel_pipeline_service)

        expect(cancel_pipeline_service).to receive(:force_execute)

        response
      end
    end

    context 'with concurrent updates' do
      it 'destroys the pipeline' do
        expect(service).to receive(:destroy_all_records).and_wrap_original do |original_method, *args, &block|
          ::Ci::Pipeline.id_in(pipeline).update_all('lock_version = lock_version + 1')

          original_method.call(*args, &block)
        end

        expect(response).to be_success

        expect { pipeline.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'with concurrent destroy actions' do
      it 'destroys the pipeline' do
        expect(service).to receive(:destroy_all_records).and_wrap_original do |original_method, *args, &block|
          ::Ci::Pipeline.id_in(pipeline).each(&:destroy!)

          original_method.call(*args, &block)
        end

        expect(response).to be_success

        expect { pipeline.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe '#execute' do
    subject(:response) { service.execute(pipeline) }

    context 'when user is owner' do
      let(:user) { project.first_owner }

      it_behaves_like 'pipeline destruction service'
    end

    context 'when user is not owner' do
      let(:user) { create(:user) }

      it 'raises an exception' do
        expect { response }.to raise_error(Gitlab::Access::AccessDeniedError)
      end
    end
  end

  describe '#unsafe_execute' do
    let(:user) { nil }

    context 'with a pipeline array as input' do
      subject(:response) { service.unsafe_execute([pipeline]) }

      it_behaves_like 'pipeline destruction service'
    end

    context 'with a pipeline object as input' do
      subject(:response) { service.unsafe_execute(pipeline) }

      it_behaves_like 'pipeline destruction service'
    end

    context 'with an empty array' do
      subject(:response) { service.unsafe_execute([]) }

      it { is_expected.to be_success }
    end
  end
end
