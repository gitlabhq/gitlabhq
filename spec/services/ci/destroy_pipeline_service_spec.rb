# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ci::DestroyPipelineService, :clean_gitlab_redis_rate_limiting,
  feature_category: :continuous_integration do
  let_it_be(:project) { create(:project, :small_repo) }
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
      expect { response }.not_to change { AuditEventReader.count }
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

    context 'when user is an instance administrator' do
      let(:user) { create(:admin) }

      context 'when admin mode is enabled', :enable_admin_mode do
        it_behaves_like 'pipeline destruction service'
      end

      context 'when admin mode is disabled' do
        it 'raises an exception' do
          expect { response }.to raise_error(Gitlab::Access::AccessDeniedError)
        end
      end
    end
  end

  describe 'rate limiting', :freeze_time do
    let_it_be(:user) { project.first_owner }

    let(:throttle_message) { ::Gitlab::ApplicationRateLimiter.throttled_error_message }

    def delete_pipeline(target = create(:ci_pipeline, project: project))
      described_class.new(project, user).execute(target)
    end

    it 'deletes while under both limits' do
      expect(delete_pipeline).to be_success
    end

    it 'throttles the sixth delete of the same pipeline in a minute', :aggregate_failures do
      target = create(:ci_pipeline, project: project)

      # Delete is idempotent, so repeats of one record are a bug rather than real work.
      5.times { described_class.new(project, user).execute(target) }

      response = described_class.new(project, user).execute(target)

      expect(response).to be_error
      expect(response.reason).to eq(:rate_limited)
      expect(response.message).to eq(throttle_message)
    end

    it 'logs the per-pipeline limit when it fires' do
      allow(Gitlab::AppJsonLogger).to receive(:info)
      target = create(:ci_pipeline, project: project)

      6.times { described_class.new(project, user).execute(target) }

      expect(Gitlab::AppJsonLogger).to have_received(:info).with(
        a_hash_including(message: 'Pipeline delete rate limit exceeded', rate_limit: 'pipeline_delete')
      ).once
    end

    context 'when the per-project limit is exceeded' do
      before do
        stub_application_setting(pipeline_delete_limit_per_user_project: 1)
      end

      it 'throttles a delete of a different pipeline in the same project', :aggregate_failures do
        expect(delete_pipeline).to be_success

        response = delete_pipeline

        expect(response).to be_error
        expect(response.reason).to eq(:rate_limited)
      end

      it 'logs the throttled call' do
        allow(Gitlab::AppJsonLogger).to receive(:info)
        target = create(:ci_pipeline, project: project)

        delete_pipeline
        delete_pipeline(target)

        expect(Gitlab::AppJsonLogger).to have_received(:info).with(
          a_hash_including(
            Labkit::Fields::CLASS_NAME => described_class.to_s,
            message: 'Pipeline delete rate limit exceeded',
            rate_limit: 'pipeline_delete_per_project',
            Labkit::Fields::GL_PROJECT_ID => project.id,
            Labkit::Fields::GL_PIPELINE_ID => target.id,
            Labkit::Fields::GL_USER_ID => user.id
          )
        ).once
      end
    end

    context 'when the per-project limit is disabled' do
      before do
        stub_application_setting(pipeline_delete_limit_per_user_project: 0)
      end

      it 'does not throttle on the per-project limit' do
        4.times { expect(delete_pipeline).to be_success }
      end

      it 'still applies the fixed per-pipeline limit', :aggregate_failures do
        target = create(:ci_pipeline, project: project)

        5.times { described_class.new(project, user).execute(target) }

        expect(described_class.new(project, user).execute(target).reason).to eq(:rate_limited)
      end
    end

    context 'when the per-pipeline limit is already exceeded' do
      let_it_be(:target) { create(:ci_pipeline, project: project) }

      before do
        stub_application_setting(pipeline_delete_limit_per_user_project: 8)
      end

      it 'does not spend the per-project budget on the blocked calls' do
        # 5 allowed, then 10 blocked per-pipeline. Were the blocked calls counted,
        # they would exhaust the per-project budget of 8 and block other pipelines.
        15.times { described_class.new(project, user).execute(target) }

        expect(delete_pipeline).to be_success
      end
    end

    context 'when the feature flag is disabled' do
      before do
        stub_feature_flags(rate_limit_pipeline_delete: false)
        stub_application_setting(pipeline_delete_limit_per_user_project: 1)
      end

      it 'does not throttle' do
        2.times { expect(delete_pipeline).to be_success }
      end
    end

    context 'when the user cannot delete the pipeline' do
      let_it_be(:user) { create(:user) }

      before do
        stub_application_setting(pipeline_delete_limit_per_user_project: 1)
      end

      it 'counts the rejected call against the bucket, and still raises', :aggregate_failures do
        2.times do
          expect { delete_pipeline }.to raise_error(Gitlab::Access::AccessDeniedError)
        end

        project.add_owner(user)

        expect(delete_pipeline.reason).to eq(:rate_limited)
      end
    end

    context 'when there is no current user' do
      it 'does not check the rate limit' do
        expect(::Gitlab::ApplicationRateLimiter).not_to receive(:throttled?)

        expect { described_class.new(project, nil).execute(create(:ci_pipeline, project: project)) }
          .to raise_error(Gitlab::Access::AccessDeniedError)
      end
    end

    describe '#unsafe_execute' do
      let_it_be(:target) { create(:ci_pipeline, project: project) }

      before do
        stub_application_setting(pipeline_delete_limit_per_user_project: 1)
      end

      # Housekeeping, project deletion and batch issuable deletion all reach the service
      # this way, and must never be throttled.
      it 'is never throttled', :aggregate_failures do
        expect(::Gitlab::ApplicationRateLimiter).not_to receive(:throttled?)

        10.times { expect(described_class.new(project, user).unsafe_execute([])).to be_success }

        expect(described_class.new(project, user).unsafe_execute([target])).to be_success
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
