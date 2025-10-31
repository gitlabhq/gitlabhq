# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CloneJobService, feature_category: :continuous_integration do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }

  let_it_be(:pipeline) do
    create(:ci_pipeline, project: project)
  end

  let_it_be(:stage) do
    create(:ci_stage, project: project, pipeline: pipeline, name: 'test')
  end

  let(:new_job_variables) { [] }

  shared_context 'when job is a bridge' do
    let_it_be(:downstream_project) { create(:project, :repository) }

    let_it_be_with_refind(:job) do
      create(:ci_bridge, :success, :resource_group,
        pipeline: pipeline, downstream: downstream_project,
        description: 'a trigger job', stage_id: stage.id,
        environment: 'production')
    end

    let(:clone_accessors) { ::Ci::Bridge.clone_accessors }
    let(:reject_accessors) { [] }
    let(:ignore_accessors) { [] }
  end

  shared_context 'when job is a build' do
    let_it_be(:another_pipeline) { create(:ci_empty_pipeline, project: project) }

    let_it_be_with_refind(:job) do
      create(
        :ci_build, :failed, :picked, :expired, :erased, :queued, :coverage, :tags,
        :allowed_to_fail, :on_tag, :triggered, :teardown_environment, :resource_group,
        description: 'my-job', stage_id: stage.id,
        pipeline: pipeline, auto_canceled_by: another_pipeline,
        scheduled_at: 10.seconds.since,
        scoped_user_id: 1,
        timeout: 3600,
        timeout_source: 2,
        exit_code: 127, # command not found
        debug_trace_enabled: false
      )
    end

    let_it_be(:internal_job_variable) { create(:ci_job_variable, job: job) }

    let(:clone_accessors) do
      %i[pipeline project ref tag options name allow_failure stage_idx yaml_variables
        when environment coverage_regex description tag_list protected needs_attributes job_variables_attributes
        timeout timeout_source debug_trace_enabled
        resource_group scheduling_type ci_stage partition_id id_tokens]
    end

    let(:reject_accessors) do
      %i[id status user token_encrypted coverage runner artifacts_expire_at
        created_at updated_at started_at finished_at queued_at erased_by
        erased_at auto_canceled_by job_artifacts job_artifacts_archive
        job_artifacts_metadata job_artifacts_trace job_artifacts_junit
        job_artifacts_sast job_artifacts_secret_detection job_artifacts_dependency_scanning
        job_artifacts_container_scanning job_artifacts_cluster_image_scanning job_artifacts_dast
        job_artifacts_license_scanning
        job_artifacts_performance job_artifacts_browser_performance job_artifacts_load_performance
        job_artifacts_lsif job_artifacts_scip job_artifacts_terraform job_artifacts_cluster_applications
        job_artifacts_codequality job_artifacts_metrics scheduled_at
        job_variables waiting_for_resource_at job_artifacts_metrics_referee
        job_artifacts_network_referee job_artifacts_dotenv
        job_artifacts_cobertura needs job_artifacts_accessibility
        job_artifacts_requirements job_artifacts_coverage_fuzzing
        job_artifacts_requirements_v2 job_artifacts_repository_xray
        job_artifacts_api_fuzzing terraform_state_versions job_artifacts_cyclonedx
        scoped_user_id exit_code job_annotations job_artifacts_annotations
        job_artifacts_jacoco].freeze
    end

    let(:ignore_accessors) do
      %i[type namespace lock_version target_url base_tags trace_sections
        commit_id deployment job_environment erased_by_id project_id project_mirror
        runner_id taggings tags trigger trigger_id
        user_id auto_canceled_by_id retried failure_reason
        sourced_pipelines sourced_pipeline artifacts_file_store artifacts_metadata_store
        metadata runner_manager_build runner_manager runner_session trace_chunks
        upstream_pipeline_id upstream_pipeline_partition_id
        artifacts_file artifacts_metadata artifacts_size commands
        resource resource_group_id processed security_scans security_report_artifacts author
        pipeline_id report_results pending_state pages_deployments
        queuing_entry runtime_metadata trace_metadata
        dast_site_profile dast_scanner_profile stage_id dast_site_profiles_build
        dast_scanner_profiles_build auto_canceled_by_partition_id execution_config_id execution_config
        build_source id_value inputs error_job_messages
        job_definition job_definition_instance job_messages temp_job_definition interruptible].freeze
    end

    before_all do
      # Create artifacts to check that the associations are rejected when cloning
      Enums::Ci::JobArtifact.type_and_format_pairs.each do |file_type, file_format|
        create(:ci_job_artifact, file_format, file_type: file_type, job: job,
          expire_at: job.artifacts_expire_at)
      end

      create(:ci_job_variable, :dotenv_source, job: job)
      create(:terraform_state_version, build: job)
      create(:ci_job_annotation, :external_link, job: job)
    end

    before do
      job.update!(retried: false, status: :success)
    end
  end

  shared_examples_for 'clones the job' do
    before do
      create(:ci_build_need, build: job)
    end

    describe 'clone accessors' do
      let(:forbidden_associations) do
        Ci::Build.reflect_on_all_associations.each_with_object(Set.new) do |assoc, memo|
          memo << assoc.name unless assoc.macro == :belongs_to
        end
      end

      it 'clones the job attributes', :aggregate_failures do
        clone_accessors.each do |attribute|
          expect(attribute).not_to be_in(forbidden_associations), "association #{attribute} must be `belongs_to`"
          expect(job.send(attribute)).not_to be_nil,
            "old job attribute #{attribute} should not be nil"
          expect(new_job.send(attribute)).not_to be_nil,
            "new job attribute #{attribute} should not be nil"
          expect(new_job.send(attribute)).to eq(job.send(attribute)),
            "new job attribute #{attribute} should match old job"
        end
      end

      it 'clones only the needs attributes' do
        expect(new_job.needs.size).to be(1)
        expect(job.needs.exists?).to be_truthy

        expect(new_job.needs_attributes).to match(job.needs_attributes)
        expect(new_job.needs).not_to match(job.needs)
      end

      it 'creates a new job definition instance for the new job' do
        expect(new_job.job_definition)
          .to be_present
          .and eq(job.job_definition)

        expect(new_job.job_definition_instance).to be_present
        expect(new_job.job_definition_instance)
          .not_to eq(job.job_definition_instance)
      end

      context 'when the job has protected: nil' do
        before do
          job.update_attribute(:protected, nil)
        end

        it 'clones the protected job attribute' do
          expect(new_job.protected).to be_nil
          expect(new_job.protected).to eq job.protected
        end
      end

      context 'when the job definitions do not exit' do
        before do
          create(:ci_build_metadata, build: job)
          Ci::JobDefinitionInstance.delete_all
          Ci::JobDefinition.delete_all
        end

        it 'creates a new job definition from metadata' do
          expect(job.job_definition).not_to be_present
          expect(new_job.job_definition).to be_present
        end
      end

      context 'when a job definition for the metadata attributes already exits' do
        let(:metadata) do
          create(:ci_build_metadata, build: job,
            config_options: job.options,
            config_variables: job.yaml_variables,
            id_tokens: job.id_tokens,
            interruptible: job.interruptible
          )
        end

        let(:config) do
          {
            options: metadata.config_options,
            yaml_variables: metadata.config_variables,
            id_tokens: metadata.id_tokens,
            secrets: metadata.secrets,
            tag_list: job.tag_list.to_a,
            run_steps: job.try(:execution_config)&.run_steps || [],
            interruptible: metadata.interruptible
          }
        end

        let(:attributes) do
          {
            config: config.compact,
            project_id: project.id,
            partition_id: pipeline.partition_id
          }
        end

        before do
          Ci::JobDefinitionInstance.delete_all
          Ci::JobDefinition.fabricate(**attributes).save!
          job.reload # clear the associated records
        end

        it 'attaches an existing job definition' do
          expect(job.job_definition).not_to be_present
          expect { new_job }.not_to change { Ci::JobDefinition.count }
          expect(new_job.job_definition).to be_present
        end
      end
    end

    describe 'reject accessors' do
      it 'does not clone rejected attributes' do
        reject_accessors.each do |attribute|
          expect(new_job.send(attribute)).not_to eq(job.send(attribute)),
            "job attribute #{attribute} should not have been cloned"
        end
      end
    end

    it 'creates a new job that represents the old job' do
      expect(new_job.name).to eq job.name
    end
  end

  describe '#execute' do
    let(:new_job) do
      described_class
        .new(job, current_user: user)
        .execute(new_job_variables: new_job_variables)
        .tap(&:save!)
    end

    context 'when the job to be cloned is a bridge' do
      include_context 'when job is a bridge'

      it_behaves_like 'clones the job'
    end

    context 'when the job to be cloned is a build' do
      include_context 'when job is a build'

      it_behaves_like 'clones the job'

      it 'has the correct number of known attributes', :aggregate_failures do
        processed_accessors = clone_accessors + reject_accessors
        known_accessors = processed_accessors + ignore_accessors

        current_accessors =
          Ci::Build.attribute_names.map(&:to_sym) +
          Ci::Build.attribute_aliases.keys.map(&:to_sym) +
          Ci::Build.reflect_on_all_associations.map(&:name) +
          [:tag_list, :needs_attributes, :job_variables_attributes, :id_tokens, :interruptible, :trigger]

        current_accessors.uniq!

        expect(current_accessors).to include(*processed_accessors)
        expect(known_accessors).to include(*current_accessors)
      end

      context 'when it has a deployment' do
        let!(:job) do
          create(:ci_build, :with_deployment, :deploy_to_production, pipeline: pipeline, stage_id: stage.id,
            project: project)
        end

        it 'persists the expanded environment name' do
          expect(new_job.expanded_environment_name).to eq('production')
        end

        it 'does not write to ci_builds_metadata' do
          expect { new_job }.to not_change { Ci::BuildMetadata.count }
        end
      end

      context 'when the job has job variables' do
        it 'only clones the internal job variables' do
          expect(new_job.job_variables.size).to eq(1)
          expect(new_job.job_variables.first.key).to eq(internal_job_variable.key)
          expect(new_job.job_variables.first.value).to eq(internal_job_variable.value)
        end
      end

      context 'when build execution config is given' do
        let(:build_execution_config) { create(:ci_builds_execution_configs, pipeline: pipeline) }

        before do
          job.update!(execution_config: build_execution_config)
        end

        it 'clones the config id' do
          expect(new_job.execution_config_id).to eq(build_execution_config.id)
        end
      end

      context 'when the job has inputs' do
        before do
          create(:ci_job_input, job: job, name: 'test_input', value: { 'key' => 'value' }, project: project)
        end

        it 'clones job inputs' do
          expect(new_job.inputs.count).to eq(job.inputs.count)
          expect(new_job.inputs.first.name).to eq('test_input')
          expect(new_job.inputs.first.value).to eq({ 'key' => 'value' })
        end
      end

      context 'when given new job variables' do
        context 'when the cloned job has an action' do
          before do
            job.update!(when: :manual)

            create(:ci_job_variable, job: job, key: 'TEST_KEY', value: 'old value')
            create(:ci_job_variable, job: job, key: 'OLD_KEY', value: 'i will not live for long')
          end

          let(:new_job_variables) do
            [
              { key: 'TEST_KEY', value: 'new value' },
              { key: 'NEW_KEY', value: 'exciting new value' }
            ]
          end

          it 'applies the new job variables' do
            expect(new_job.job_variables.count).to be(2)
            expect(new_job.job_variables.pluck(:key))
              .to contain_exactly('TEST_KEY', 'NEW_KEY')

            expect(new_job.job_variables.map(&:value))
              .to contain_exactly('new value', 'exciting new value')
          end
        end

        context 'when the cloned job does not have an action' do
          let(:new_job_variables) do
            [{ key: 'TEST_KEY', value: 'new value' }]
          end

          it 'applies the old job variables' do
            expect(new_job.job_variables.count).to be(1)
            expect(new_job.job_variables.pluck(:key)).to contain_exactly(internal_job_variable.key)
            expect(new_job.job_variables.map(&:value)).to contain_exactly(internal_job_variable.value)
          end
        end
      end

      context 'when not given new job variables' do
        before do
          job.update!(when: :manual)
        end

        it 'applies the old job variables' do
          expect(new_job.job_variables.count).to be(1)
          expect(new_job.job_variables.pluck(:key)).to contain_exactly(internal_job_variable.key)
          expect(new_job.job_variables.map(&:value)).to contain_exactly(internal_job_variable.value)
        end
      end
    end
  end
end
