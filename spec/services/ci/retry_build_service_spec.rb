# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RetryBuildService do
  let_it_be(:reporter) { create(:user) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:pipeline) do
    create(:ci_pipeline, project: project,
           sha: 'b83d6e391c22777fca1ed3012fce84f633d7fed0')
  end

  let_it_be(:stage) do
    create(:ci_stage_entity, project: project,
                             pipeline: pipeline,
                             name: 'test')
  end

  let_it_be_with_refind(:build) { create(:ci_build, pipeline: pipeline, stage_id: stage.id) }

  let(:user) { developer }

  let(:service) do
    described_class.new(project, user)
  end

  before_all do
    project.add_developer(developer)
    project.add_reporter(reporter)
  end

  clone_accessors = described_class.clone_accessors.without(described_class.extra_accessors)

  reject_accessors =
    %i[id status user token token_encrypted coverage trace runner
       artifacts_expire_at
       created_at updated_at started_at finished_at queued_at erased_by
       erased_at auto_canceled_by job_artifacts job_artifacts_archive
       job_artifacts_metadata job_artifacts_trace job_artifacts_junit
       job_artifacts_sast job_artifacts_secret_detection job_artifacts_dependency_scanning
       job_artifacts_container_scanning job_artifacts_cluster_image_scanning job_artifacts_dast
       job_artifacts_license_scanning
       job_artifacts_performance job_artifacts_browser_performance job_artifacts_load_performance
       job_artifacts_lsif job_artifacts_terraform job_artifacts_cluster_applications
       job_artifacts_codequality job_artifacts_metrics scheduled_at
       job_variables waiting_for_resource_at job_artifacts_metrics_referee
       job_artifacts_network_referee job_artifacts_dotenv
       job_artifacts_cobertura needs job_artifacts_accessibility
       job_artifacts_requirements job_artifacts_coverage_fuzzing
       job_artifacts_api_fuzzing].freeze

  ignore_accessors =
    %i[type lock_version target_url base_tags trace_sections
       commit_id deployment erased_by_id project_id
       runner_id tag_taggings taggings tags trigger_request_id
       user_id auto_canceled_by_id retried failure_reason
       sourced_pipelines artifacts_file_store artifacts_metadata_store
       metadata runner_session trace_chunks upstream_pipeline_id
       artifacts_file artifacts_metadata artifacts_size commands
       resource resource_group_id processed security_scans author
       pipeline_id report_results pending_state pages_deployments
       queuing_entry runtime_metadata].freeze

  shared_examples 'build duplication' do
    let_it_be(:another_pipeline) { create(:ci_empty_pipeline, project: project) }

    let_it_be(:build) do
      create(:ci_build, :failed, :picked, :expired, :erased, :queued, :coverage, :tags,
             :allowed_to_fail, :on_tag, :triggered, :teardown_environment, :resource_group,
             description: 'my-job', stage: 'test', stage_id: stage.id,
             pipeline: pipeline, auto_canceled_by: another_pipeline,
             scheduled_at: 10.seconds.since)
    end

    before_all do
      # Make sure that build has both `stage_id` and `stage` because FactoryBot
      # can reset one of the fields when assigning another. We plan to deprecate
      # and remove legacy `stage` column in the future.
      build.update!(stage: 'test', stage_id: stage.id)

      # Make sure we have one instance for every possible job_artifact_X
      # associations to check they are correctly rejected on build duplication.
      Ci::JobArtifact::TYPE_AND_FORMAT_PAIRS.each do |file_type, file_format|
        create(:ci_job_artifact, file_format,
               file_type: file_type, job: build, expire_at: build.artifacts_expire_at)
      end

      create(:ci_job_variable, job: build)
      create(:ci_build_need, build: build)
    end

    describe 'clone accessors' do
      let(:forbidden_associations) do
        Ci::Build.reflect_on_all_associations.each_with_object(Set.new) do |assoc, memo|
          memo << assoc.name unless assoc.macro == :belongs_to
        end
      end

      clone_accessors.each do |attribute|
        it "clones #{attribute} build attribute", :aggregate_failures do
          expect(attribute).not_to be_in(forbidden_associations), "association #{attribute} must be `belongs_to`"
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

      it 'clones only the needs attributes' do
        expect(new_build.needs.exists?).to be_truthy
        expect(build.needs.exists?).to be_truthy

        expect(new_build.needs_attributes).to match(build.needs_attributes)
        expect(new_build.needs).not_to match(build.needs)
      end
    end

    describe 'reject accessors' do
      reject_accessors.each do |attribute|
        it "does not clone #{attribute} build attribute" do
          expect(new_build.send(attribute)).not_to eq build.send(attribute)
        end
      end
    end

    it 'has correct number of known attributes', :aggregate_failures do
      processed_accessors = clone_accessors + reject_accessors
      known_accessors = processed_accessors + ignore_accessors

      # :tag_list is a special case, this accessor does not exist
      # in reflected associations, comes from `act_as_taggable` and
      # we use it to copy tags, instead of reusing tags.
      #
      current_accessors =
        Ci::Build.attribute_names.map(&:to_sym) +
        Ci::Build.attribute_aliases.keys.map(&:to_sym) +
        Ci::Build.reflect_on_all_associations.map(&:name) +
        [:tag_list, :needs_attributes] -
        # ee-specific accessors should be tested in ee/spec/services/ci/retry_build_service_spec.rb instead
        described_class.extra_accessors -
        [:dast_site_profiles_build, :dast_scanner_profiles_build] # join tables

      current_accessors.uniq!

      expect(current_accessors).to include(*processed_accessors)
      expect(known_accessors).to include(*current_accessors)
    end
  end

  describe '#execute' do
    let(:new_build) do
      travel_to(1.second.from_now) do
        service.execute(build)
      end
    end

    context 'when user has ability to execute build' do
      before do
        stub_not_protect_default_branch
      end

      it_behaves_like 'build duplication'

      it 'creates a new build that represents the old one' do
        expect(new_build.name).to eq build.name
      end

      it 'enqueues the new build' do
        expect(new_build).to be_pending
      end

      it 'resolves todos for old build that failed' do
        expect(::MergeRequests::AddTodoWhenBuildFailsService)
          .to receive_message_chain(:new, :close)

        service.execute(build)
      end

      context 'when there are subsequent processables that are skipped' do
        let!(:subsequent_build) do
          create(:ci_build, :skipped, stage_idx: 2,
                                      pipeline: pipeline,
                                      stage: 'deploy')
        end

        let!(:subsequent_bridge) do
          create(:ci_bridge, :skipped, stage_idx: 2,
                                       pipeline: pipeline,
                                       stage: 'deploy')
        end

        it 'resumes pipeline processing in the subsequent stage' do
          service.execute(build)

          expect(subsequent_build.reload).to be_created
          expect(subsequent_bridge.reload).to be_created
        end

        it 'updates ownership for subsequent builds' do
          expect { service.execute(build) }.to change { subsequent_build.reload.user }.to(user)
        end

        it 'updates ownership for subsequent bridges' do
          expect { service.execute(build) }.to change { subsequent_bridge.reload.user }.to(user)
        end

        it 'does not cause n+1 when updaing build ownership' do
          control_count = ActiveRecord::QueryRecorder.new(skip_cached: false) { service.execute(build) }.count

          create_list(:ci_build, 2, :skipped, stage_idx: build.stage_idx + 1, pipeline: pipeline, stage: 'deploy')

          expect { service.execute(build) }.not_to exceed_all_query_limit(control_count)
        end
      end

      context 'when pipeline has other builds' do
        let!(:stage2) { create(:ci_stage_entity, project: project, pipeline: pipeline, name: 'deploy') }
        let!(:build2) { create(:ci_build, pipeline: pipeline, stage_id: stage.id ) }
        let!(:deploy) { create(:ci_build, pipeline: pipeline, stage_id: stage2.id) }
        let!(:deploy_needs_build2) { create(:ci_build_need, build: deploy, name: build2.name) }

        context 'when build has nil scheduling_type' do
          before do
            build.pipeline.processables.update_all(scheduling_type: nil)
            build.reload
          end

          it 'populates scheduling_type of processables' do
            expect(new_build.scheduling_type).to eq('stage')
            expect(build.reload.scheduling_type).to eq('stage')
            expect(build2.reload.scheduling_type).to eq('stage')
            expect(deploy.reload.scheduling_type).to eq('dag')
          end
        end

        context 'when build has scheduling_type' do
          it 'does not call populate_scheduling_type!' do
            expect_any_instance_of(Ci::Pipeline).not_to receive(:ensure_scheduling_type!)

            expect(new_build.scheduling_type).to eq('stage')
          end
        end
      end

      context 'when the pipeline is a child pipeline and the bridge is depended' do
        let!(:parent_pipeline) { create(:ci_pipeline, project: project) }
        let!(:bridge) { create(:ci_bridge, :strategy_depend, pipeline: parent_pipeline, status: 'success') }
        let!(:source_pipeline) { create(:ci_sources_pipeline, pipeline: pipeline, source_job: bridge) }

        it 'marks source bridge as pending' do
          service.execute(build)

          expect(bridge.reload).to be_pending
        end
      end
    end

    context 'when user does not have ability to execute build' do
      let(:user) { reporter }

      it 'raises an error' do
        expect { service.execute(build) }
          .to raise_error Gitlab::Access::AccessDeniedError
      end
    end
  end

  describe '#reprocess' do
    let(:new_build) do
      travel_to(1.second.from_now) do
        service.reprocess!(build)
      end
    end

    context 'when user has ability to execute build' do
      before do
        stub_not_protect_default_branch
      end

      it_behaves_like 'build duplication'

      it 'creates a new build that represents the old one' do
        expect(new_build.name).to eq build.name
      end

      it 'does not enqueue the new build' do
        expect(new_build).to be_created
        expect(new_build).not_to be_processed
      end

      it 'does mark old build as retried' do
        expect(new_build).to be_latest
        expect(build).to be_retried
        expect(build).to be_processed
      end

      context 'when build with deployment is retried' do
        let!(:build) do
          create(:ci_build, :with_deployment, :deploy_to_production,
                 pipeline: pipeline, stage_id: stage.id, project: project)
        end

        it 'creates a new deployment' do
          expect { new_build }.to change { Deployment.count }.by(1)
        end

        it 'persists expanded environment name' do
          expect(new_build.metadata.expanded_environment_name).to eq('production')
        end
      end

      context 'when build has needs' do
        before do
          create(:ci_build_need, build: build, name: 'build1')
          create(:ci_build_need, build: build, name: 'build2')
        end

        it 'bulk inserts all needs' do
          expect(Ci::BuildNeed).to receive(:bulk_insert!).and_call_original

          new_build
        end
      end
    end

    context 'when user does not have ability to execute build' do
      let(:user) { reporter }

      it 'raises an error' do
        expect { service.reprocess!(build) }
          .to raise_error Gitlab::Access::AccessDeniedError
      end
    end
  end
end
