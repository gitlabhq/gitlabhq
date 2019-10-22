# frozen_string_literal: true

require 'spec_helper'

describe Ci::RetryBuildService do
  set(:user) { create(:user) }
  set(:project) { create(:project) }
  set(:pipeline) { create(:ci_pipeline, project: project) }

  let(:stage) do
    create(:ci_stage_entity, project: project,
                             pipeline: pipeline,
                             name: 'test')
  end

  let(:build) { create(:ci_build, pipeline: pipeline, stage_id: stage.id) }

  let(:service) do
    described_class.new(project, user)
  end

  CLONE_ACCESSORS = described_class::CLONE_ACCESSORS

  REJECT_ACCESSORS =
    %i[id status user token token_encrypted coverage trace runner
       artifacts_expire_at
       created_at updated_at started_at finished_at queued_at erased_by
       erased_at auto_canceled_by job_artifacts job_artifacts_archive
       job_artifacts_metadata job_artifacts_trace job_artifacts_junit
       job_artifacts_sast job_artifacts_dependency_scanning
       job_artifacts_container_scanning job_artifacts_dast
       job_artifacts_license_management job_artifacts_performance
       job_artifacts_codequality job_artifacts_metrics scheduled_at
       job_variables].freeze

  IGNORE_ACCESSORS =
    %i[type lock_version target_url base_tags trace_sections
       commit_id deployment erased_by_id project_id
       runner_id tag_taggings taggings tags trigger_request_id
       user_id auto_canceled_by_id retried failure_reason
       sourced_pipelines artifacts_file_store artifacts_metadata_store
       metadata runner_session trace_chunks upstream_pipeline_id
       artifacts_file artifacts_metadata artifacts_size commands].freeze

  shared_examples 'build duplication' do
    let(:another_pipeline) { create(:ci_empty_pipeline, project: project) }

    let(:build) do
      create(:ci_build, :failed, :expired, :erased, :queued, :coverage, :tags,
             :allowed_to_fail, :on_tag, :triggered, :teardown_environment,
             description: 'my-job', stage: 'test', stage_id: stage.id,
             pipeline: pipeline, auto_canceled_by: another_pipeline,
             scheduled_at: 10.seconds.since)
    end

    before do
      # Make sure that build has both `stage_id` and `stage` because FactoryBot
      # can reset one of the fields when assigning another. We plan to deprecate
      # and remove legacy `stage` column in the future.
      build.update(stage: 'test', stage_id: stage.id)

      # Make sure we have one instance for every possible job_artifact_X
      # associations to check they are correctly rejected on build duplication.
      Ci::JobArtifact::TYPE_AND_FORMAT_PAIRS.each do |file_type, file_format|
        create(:ci_job_artifact, file_format,
               file_type: file_type, job: build, expire_at: build.artifacts_expire_at)
      end

      create(:ci_job_variable, job: build)
      create(:ci_build_need, build: build)

      build.reload
    end

    describe 'clone accessors' do
      CLONE_ACCESSORS.each do |attribute|
        it "clones #{attribute} build attribute" do
          expect(build.send(attribute)).not_to be_nil
          expect(new_build.send(attribute)).not_to be_nil
          expect(new_build.send(attribute)).to eq build.send(attribute)
        end
      end

      context 'when job has nullified protected' do
        before do
          build.update_attribute(:protected, nil)
        end

        it "clones protected build attribute" do
          expect(new_build.protected).to be_nil
          expect(new_build.protected).to eq build.protected
        end
      end
    end

    describe 'reject acessors' do
      REJECT_ACCESSORS.each do |attribute|
        it "does not clone #{attribute} build attribute" do
          expect(new_build.send(attribute)).not_to eq build.send(attribute)
        end
      end
    end

    it 'has correct number of known attributes' do
      processed_accessors = CLONE_ACCESSORS + REJECT_ACCESSORS
      known_accessors = processed_accessors + IGNORE_ACCESSORS

      # :tag_list is a special case, this accessor does not exist
      # in reflected associations, comes from `act_as_taggable` and
      # we use it to copy tags, instead of reusing tags.
      #
      current_accessors =
        Ci::Build.attribute_names.map(&:to_sym) +
        Ci::Build.reflect_on_all_associations.map(&:name) +
        [:tag_list]

      current_accessors.uniq!

      expect(current_accessors).to include(*processed_accessors)
      expect(known_accessors).to include(*current_accessors)
    end
  end

  describe '#execute' do
    let(:new_build) do
      Timecop.freeze(1.second.from_now) do
        service.execute(build)
      end
    end

    context 'when user has ability to execute build' do
      before do
        stub_not_protect_default_branch

        project.add_developer(user)
      end

      it_behaves_like 'build duplication'

      it 'creates a new build that represents the old one' do
        expect(new_build.name).to eq build.name
      end

      it 'enqueues the new build' do
        expect(new_build).to be_pending
      end

      it 'resolves todos for old build that failed' do
        expect(MergeRequests::AddTodoWhenBuildFailsService)
          .to receive_message_chain(:new, :close)

        service.execute(build)
      end

      context 'when there are subsequent builds that are skipped' do
        let!(:subsequent_build) do
          create(:ci_build, :skipped, stage_idx: 2,
                                      pipeline: pipeline,
                                      stage: 'deploy')
        end

        it 'resumes pipeline processing in a subsequent stage' do
          service.execute(build)

          expect(subsequent_build.reload).to be_created
        end
      end
    end

    context 'when user does not have ability to execute build' do
      it 'raises an error' do
        expect { service.execute(build) }
          .to raise_error Gitlab::Access::AccessDeniedError
      end
    end
  end

  describe '#reprocess' do
    let(:new_build) do
      Timecop.freeze(1.second.from_now) do
        service.reprocess!(build)
      end
    end

    context 'when user has ability to execute build' do
      before do
        stub_not_protect_default_branch

        project.add_developer(user)
      end

      it_behaves_like 'build duplication'

      it 'creates a new build that represents the old one' do
        expect(new_build.name).to eq build.name
      end

      it 'does not enqueue the new build' do
        expect(new_build).to be_created
      end

      it 'does mark old build as retried in the database and on the instance' do
        expect(new_build).to be_latest
        expect(build).to be_retried
        expect(build.reload).to be_retried
      end

      context 'when build with deployment is retried' do
        let!(:build) do
          create(:ci_build, :with_deployment, :deploy_to_production, pipeline: pipeline, stage_id: stage.id)
        end

        it 'creates a new deployment' do
          expect { new_build }.to change { Deployment.count }.by(1)
        end
      end
    end

    context 'when user does not have ability to execute build' do
      it 'raises an error' do
        expect { service.reprocess!(build) }
          .to raise_error Gitlab::Access::AccessDeniedError
      end
    end
  end
end
