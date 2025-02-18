# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Processable, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project) }
  let_it_be_with_refind(:pipeline) { create(:ci_pipeline, project: project) }

  describe 'associations' do
    it { is_expected.to belong_to(:trigger_request) }
  end

  describe 'delegations' do
    subject { described_class.new }

    it { is_expected.to delegate_method(:merge_request?).to(:pipeline) }
    it { is_expected.to delegate_method(:merge_request_ref?).to(:pipeline) }
    it { is_expected.to delegate_method(:legacy_detached_merge_request_pipeline?).to(:pipeline) }
    it { is_expected.to delegate_method(:trigger_short_token).to(:trigger_request) }
  end

  describe '#clone' do
    let(:user) { create(:user) }

    let(:new_processable) do
      new_proc = processable.clone(current_user: user)
      new_proc.save!

      new_proc
    end

    let_it_be(:stage) { create(:ci_stage, project: project, pipeline: pipeline, name: 'test') }

    shared_context 'processable bridge' do
      let_it_be(:downstream_project) { create(:project, :repository) }

      let_it_be_with_refind(:processable) do
        create(:ci_bridge, :success,
          pipeline: pipeline, downstream: downstream_project, description: 'a trigger job', stage_id: stage.id,
          environment: 'production')
      end

      let(:clone_accessors) { ::Ci::Bridge.clone_accessors }
      let(:reject_accessors) { [] }
      let(:ignore_accessors) { [] }
    end

    shared_context 'processable build' do
      let_it_be(:another_pipeline) { create(:ci_empty_pipeline, project: project) }

      let_it_be_with_refind(:processable) do
        create(
          :ci_build, :failed, :picked, :expired, :erased, :queued, :coverage, :tags,
          :allowed_to_fail, :on_tag, :triggered, :teardown_environment, :resource_group,
          description: 'my-job', stage_id: stage.id,
          pipeline: pipeline, auto_canceled_by: another_pipeline,
          scheduled_at: 10.seconds.since
        )
      end

      let_it_be(:internal_job_variable) { create(:ci_job_variable, job: processable) }

      let(:clone_accessors) do
        %i[pipeline project ref tag options name allow_failure stage_idx trigger_request yaml_variables
           when environment coverage_regex description tag_list protected needs_attributes job_variables_attributes
           resource_group scheduling_type ci_stage partition_id id_tokens interruptible]
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
           job_artifacts_lsif job_artifacts_terraform job_artifacts_cluster_applications
           job_artifacts_codequality job_artifacts_metrics scheduled_at
           job_variables waiting_for_resource_at job_artifacts_metrics_referee
           job_artifacts_network_referee job_artifacts_dotenv
           job_artifacts_cobertura needs job_artifacts_accessibility
           job_artifacts_requirements job_artifacts_coverage_fuzzing
           job_artifacts_requirements_v2 job_artifacts_repository_xray
           job_artifacts_api_fuzzing terraform_state_versions job_artifacts_cyclonedx
           job_annotations job_artifacts_annotations job_artifacts_jacoco].freeze
      end

      let(:ignore_accessors) do
        %i[type namespace lock_version target_url base_tags trace_sections
           commit_id deployment erased_by_id project_id project_mirror
           runner_id taggings tags trigger_request_id
           user_id auto_canceled_by_id retried failure_reason
           sourced_pipelines sourced_pipeline artifacts_file_store artifacts_metadata_store
           metadata runner_manager_build runner_manager runner_session trace_chunks
           upstream_pipeline_id upstream_pipeline_partition_id
           artifacts_file artifacts_metadata artifacts_size commands
           resource resource_group_id processed security_scans author
           pipeline_id report_results pending_state pages_deployments
           queuing_entry runtime_metadata trace_metadata
           dast_site_profile dast_scanner_profile stage_id dast_site_profiles_build
           dast_scanner_profiles_build auto_canceled_by_partition_id execution_config_id execution_config
           build_source id_value].freeze
      end

      before_all do
        # Create artifacts to check that the associations are rejected when cloning
        Enums::Ci::JobArtifact.type_and_format_pairs.each do |file_type, file_format|
          create(:ci_job_artifact, file_format, file_type: file_type, job: processable, expire_at: processable.artifacts_expire_at)
        end

        create(:ci_job_variable, :dotenv_source, job: processable)
        create(:terraform_state_version, build: processable)
        create(:ci_job_annotation, :external_link, job: processable)
      end

      before do
        processable.update!(retried: false, status: :success)
      end
    end

    shared_examples_for 'clones the processable' do
      before_all do
        processable.assign_attributes(stage_id: stage.id, interruptible: true)
        processable.save!

        create(:ci_build_need, build: processable)
      end

      describe 'clone accessors' do
        let(:forbidden_associations) do
          Ci::Build.reflect_on_all_associations.each_with_object(Set.new) do |assoc, memo|
            memo << assoc.name unless assoc.macro == :belongs_to
          end
        end

        it 'clones the processable attributes', :aggregate_failures do
          clone_accessors.each do |attribute|
            expect(attribute).not_to be_in(forbidden_associations), "association #{attribute} must be `belongs_to`"
            expect(processable.send(attribute)).not_to be_nil, "old processable attribute #{attribute} should not be nil"
            expect(new_processable.send(attribute)).not_to be_nil, "new processable attribute #{attribute} should not be nil"
            expect(new_processable.send(attribute)).to eq(processable.send(attribute)), "new processable attribute #{attribute} should match old processable"
          end
        end

        it 'clones only the needs attributes' do
          expect(new_processable.needs.size).to be(1)
          expect(processable.needs.exists?).to be_truthy

          expect(new_processable.needs_attributes).to match(processable.needs_attributes)
          expect(new_processable.needs).not_to match(processable.needs)
        end

        context 'when the processable has protected: nil' do
          before do
            processable.update_attribute(:protected, nil)
          end

          it 'clones the protected job attribute' do
            expect(new_processable.protected).to be_nil
            expect(new_processable.protected).to eq processable.protected
          end
        end
      end

      describe 'reject accessors' do
        it 'does not clone rejected attributes' do
          reject_accessors.each do |attribute|
            expect(new_processable.send(attribute)).not_to eq(processable.send(attribute)), "processable attribute #{attribute} should not have been cloned"
          end
        end
      end

      it 'creates a new processable that represents the old processable' do
        expect(new_processable.name).to eq processable.name
      end
    end

    context 'when the processable to be cloned is a bridge' do
      include_context 'processable bridge'

      it_behaves_like 'clones the processable'
    end

    context 'when the processable to be cloned is a build' do
      include_context 'processable build'

      it_behaves_like 'clones the processable'

      it 'has the correct number of known attributes', :aggregate_failures do
        processed_accessors = clone_accessors + reject_accessors
        known_accessors = processed_accessors + ignore_accessors

        current_accessors =
          Ci::Build.attribute_names.map(&:to_sym) +
          Ci::Build.attribute_aliases.keys.map(&:to_sym) +
          Ci::Build.reflect_on_all_associations.map(&:name) +
          [:tag_list, :needs_attributes, :job_variables_attributes, :id_tokens, :interruptible]

        current_accessors.uniq!

        expect(current_accessors).to include(*processed_accessors)
        expect(known_accessors).to include(*current_accessors)
      end

      context 'when it has a deployment' do
        let!(:processable) do
          create(:ci_build, :with_deployment, :deploy_to_production, pipeline: pipeline, stage_id: stage.id, project: project)
        end

        it 'persists the expanded environment name' do
          expect(new_processable.metadata.expanded_environment_name).to eq('production')
        end
      end

      context 'when it has a dynamic environment' do
        let_it_be(:other_developer) { create(:user, developer_of: project) }

        let(:environment_name) { 'review/$CI_COMMIT_REF_SLUG-$GITLAB_USER_ID' }

        let!(:processable) do
          create(:ci_build, :with_deployment,
            environment: environment_name,
            options: { environment: { name: environment_name } },
            pipeline: pipeline, stage_id: stage.id, project: project,
            user: other_developer)
        end

        it 're-uses the previous persisted environment' do
          expect(processable.persisted_environment.name).to eq("review/#{processable.ref}-#{other_developer.id}")

          expect(new_processable.persisted_environment.name).to eq("review/#{processable.ref}-#{other_developer.id}")
        end
      end

      context 'when the processable has job variables' do
        it 'only clones the internal job variables' do
          expect(new_processable.job_variables.size).to eq(1)
          expect(new_processable.job_variables.first.key).to eq(internal_job_variable.key)
          expect(new_processable.job_variables.first.value).to eq(internal_job_variable.value)
        end
      end
    end
  end

  describe '#retryable' do
    shared_examples_for 'retryable processable' do
      context 'when processable is successful' do
        before do
          processable.success!
        end

        it { is_expected.to be_retryable }
      end

      context 'when processable is failed' do
        before do
          processable.drop!
        end

        it { is_expected.to be_retryable }
      end

      context 'when processable is canceled' do
        before do
          processable.cancel!
        end

        it { is_expected.to be_retryable }
      end
    end

    shared_examples_for 'non-retryable processable' do
      context 'when processable is skipped' do
        before do
          processable.skip!
        end

        it { is_expected.not_to be_retryable }
      end

      context 'when processable is degenerated' do
        before do
          processable.degenerate!
        end

        it { is_expected.not_to be_retryable }
      end

      context 'when a canceled processable has been retried already' do
        before do
          project.add_developer(create(:user))
          processable.cancel!
          processable.update!(retried: true)
        end

        it { is_expected.not_to be_retryable }
      end
    end

    context 'when the processable is a bridge' do
      subject(:processable) { create(:ci_bridge, pipeline: pipeline) }

      it_behaves_like 'retryable processable'
    end

    context 'when the processable is a build' do
      subject(:processable) { create(:ci_build, pipeline: pipeline) }

      context 'when the processable is retryable' do
        it_behaves_like 'retryable processable'

        context 'when deployment is rejected' do
          before do
            processable.drop!(:deployment_rejected)
          end

          it { is_expected.not_to be_retryable }
        end

        context 'when build is waiting for deployment approval' do
          subject { build_stubbed(:ci_build, :manual, environment: 'production') }

          before do
            create(:deployment, :blocked, deployable: subject)
          end

          it { is_expected.not_to be_retryable }
        end
      end

      context 'when the processable is non-retryable' do
        it_behaves_like 'non-retryable processable'

        context 'when processable is running' do
          before do
            processable.run!
          end

          it { is_expected.not_to be_retryable }
        end
      end
    end
  end

  describe '#aggregated_needs_names' do
    let(:with_aggregated_needs) { pipeline.processables.select_with_aggregated_needs(project) }

    context 'with created status' do
      let!(:processable) { create(:ci_build, :created, project: project, pipeline: pipeline) }

      context 'with needs' do
        before do
          create(:ci_build_need, build: processable, name: 'test1')
          create(:ci_build_need, build: processable, name: 'test2')
        end

        it 'returns all processables' do
          expect(with_aggregated_needs).to contain_exactly(processable)
        end

        it 'returns all needs' do
          expect(with_aggregated_needs.first.aggregated_needs_names).to contain_exactly('test1', 'test2')
        end
      end

      context 'without needs' do
        it 'returns all processables' do
          expect(with_aggregated_needs).to contain_exactly(processable)
        end

        it 'returns empty needs' do
          expect(with_aggregated_needs.first.aggregated_needs_names).to be_nil
        end
      end
    end
  end

  describe 'validate presence of scheduling_type' do
    using RSpec::Parameterized::TableSyntax

    subject { build(:ci_build, project: project, pipeline: pipeline, importing: importing) }

    where(:importing, :should_validate) do
      false | true
      true  | false
    end

    with_them do
      context 'on create' do
        it 'validates presence' do
          if should_validate
            is_expected.to validate_presence_of(:scheduling_type).on(:create)
          else
            is_expected.not_to validate_presence_of(:scheduling_type).on(:create)
          end
        end
      end

      context 'on update' do
        it { is_expected.not_to validate_presence_of(:scheduling_type).on(:update) }
      end
    end
  end

  describe '.populate_scheduling_type!' do
    let!(:build_without_needs) { create(:ci_build, project: project, pipeline: pipeline) }
    let!(:build_with_needs) { create(:ci_build, project: project, pipeline: pipeline) }
    let!(:needs_relation) { create(:ci_build_need, build: build_with_needs) }
    let!(:another_build) { create(:ci_build, project: project) }

    before do
      described_class.update_all(scheduling_type: nil)
    end

    it 'populates scheduling_type of processables' do
      expect do
        pipeline.processables.populate_scheduling_type!
      end.to change(pipeline.processables.where(scheduling_type: nil), :count).from(2).to(0)

      expect(build_without_needs.reload.scheduling_type).to eq('stage')
      expect(build_with_needs.reload.scheduling_type).to eq('dag')
    end

    it 'does not affect processables from other pipelines' do
      pipeline.processables.populate_scheduling_type!
      expect(another_build.reload.scheduling_type).to be_nil
    end
  end

  describe '#needs_attributes' do
    let(:build) { create(:ci_build, :created, project: project, pipeline: pipeline) }

    subject { build.needs_attributes }

    context 'with needs' do
      before do
        create(:ci_build_need, build: build, name: 'test1')
        create(:ci_build_need, build: build, name: 'test2')
      end

      it 'returns all needs attributes' do
        is_expected.to contain_exactly(
          { 'artifacts' => true, 'name' => 'test1', 'optional' => false, 'partition_id' => build.partition_id, 'project_id' => build.project_id },
          { 'artifacts' => true, 'name' => 'test2', 'optional' => false, 'partition_id' => build.partition_id, 'project_id' => build.project_id }
        )
      end
    end

    context 'without needs' do
      it { is_expected.to be_empty }
    end
  end

  describe 'state transition with resource group' do
    let(:resource_group) { create(:ci_resource_group, project: project) }

    context 'when build status is created' do
      let(:build) { create(:ci_build, :created, project: project, resource_group: resource_group) }

      it 'is waiting for resource when build is enqueued' do
        expect(Ci::ResourceGroups::AssignResourceFromResourceGroupWorker).to receive(:perform_async).with(resource_group.id)

        expect { build.enqueue! }.to change { build.status }.from('created').to('waiting_for_resource')

        expect(build.waiting_for_resource_at).not_to be_nil
      end

      context 'when build is waiting for resource' do
        before do
          build.update_column(:status, 'waiting_for_resource')
        end

        it 'is enqueued when build requests resource' do
          expect { build.enqueue_waiting_for_resource! }.to change { build.status }.from('waiting_for_resource').to('pending')
        end

        it 'releases a resource when build finished' do
          expect(build.resource_group).to receive(:release_resource_from).with(build).and_return(true).and_call_original
          expect(Ci::ResourceGroups::AssignResourceFromResourceGroupWorker).to receive(:perform_async).with(build.resource_group_id)

          build.enqueue_waiting_for_resource!
          build.success!
        end

        it 're-checks the resource group even if the processable does not retain a resource' do
          expect(build.resource_group).to receive(:release_resource_from).with(build).and_return(false).and_call_original
          expect(Ci::ResourceGroups::AssignResourceFromResourceGroupWorker).to receive(:perform_async).with(build.resource_group_id)

          build.success!
        end

        context 'when build has prerequisites' do
          before do
            allow(build).to receive(:any_unmet_prerequisites?) { true }
          end

          it 'is preparing when build is enqueued' do
            expect { build.enqueue_waiting_for_resource! }.to change { build.status }.from('waiting_for_resource').to('preparing')
          end
        end

        context 'when there are no available resources' do
          before do
            resource_group.assign_resource_to(create(:ci_build))
          end

          it 'stays as waiting for resource when build requests resource' do
            expect { build.enqueue_waiting_for_resource }.not_to change { build.status }
          end
        end
      end
    end
  end

  describe '.manual_actions' do
    shared_examples_for 'manual actions for a job' do
      let!(:manual_but_created) { create(factory_type, :manual, status: :created, pipeline: pipeline) }
      let!(:manual_but_succeeded) { create(factory_type, :manual, status: :success, pipeline: pipeline) }
      let!(:manual_action) { create(factory_type, :manual, pipeline: pipeline) }

      subject { described_class.manual_actions }

      it { is_expected.to include(manual_action) }
      it { is_expected.to include(manual_but_succeeded) }
      it { is_expected.not_to include(manual_but_created) }
    end

    it_behaves_like 'manual actions for a job' do
      let(:factory_type) { :ci_build }
    end

    it_behaves_like 'manual actions for a job' do
      let(:factory_type) { :ci_bridge }
    end
  end

  describe '#other_manual_actions' do
    let_it_be(:user) { create(:user) }

    before_all do
      project.add_developer(user)
    end

    shared_examples_for 'other manual actions for a job' do
      let(:job) { create(factory_type, :manual, pipeline: pipeline, project: project) }
      let!(:other_job) { create(factory_type, :manual, pipeline: pipeline, project: project, name: 'other action') }

      subject { job.other_manual_actions }

      it 'returns other actions' do
        is_expected.to contain_exactly(other_job)
      end

      context 'when job is retried' do
        let!(:new_job) { Ci::RetryJobService.new(project, user).execute(job)[:job] }

        it 'does not return any of them' do
          is_expected.not_to include(job, new_job)
        end
      end
    end

    it_behaves_like 'other manual actions for a job' do
      let(:factory_type) { :ci_build }
    end

    it_behaves_like 'other manual actions for a job' do
      let(:factory_type) { :ci_bridge }
    end
  end

  describe 'manual_job?' do
    context 'when job is manual' do
      subject { build(:ci_build, :manual) }

      it { expect(subject.manual_job?).to be_truthy }
    end

    context 'when job is not manual' do
      subject { build(:ci_build) }

      it { expect(subject.manual_job?).to be_falsey }
    end
  end

  describe 'manual_confirmation_message' do
    context 'when job is manual' do
      subject { build(:ci_build, :manual, :with_manual_confirmation) }

      it 'return manual_confirmation from option' do
        expect(subject.manual_confirmation_message).to eq('Please confirm. Do you want to proceed?')
      end
    end

    context 'when job is not manual' do
      subject { build(:ci_build) }

      it { expect(subject.manual_confirmation_message).to be_nil }
    end
  end

  describe 'state transition: any => [:failed]' do
    using RSpec::Parameterized::TableSyntax

    let!(:processable) { create(:ci_build, :running, pipeline: pipeline, user: create(:user)) }

    before do
      allow(processable).to receive(:can_auto_cancel_pipeline_on_job_failure?).and_return(can_auto_cancel_pipeline_on_job_failure)
      allow(processable).to receive(:allow_failure?).and_return(allow_failure)
    end

    where(:can_auto_cancel_pipeline_on_job_failure, :allow_failure, :result) do
      true  | true  | false
      true  | false | true
      false | true  | false
      false | false | false
    end

    with_them do
      it 'behaves as expected' do
        if result
          expect(processable.pipeline).to receive(:cancel_async_on_job_failure)
        else
          expect(processable.pipeline).not_to receive(:cancel_async_on_job_failure)
        end

        processable.drop!
      end
    end
  end

  describe 'job_dependencies_with_accessible_artifacts' do
    context 'in the same project' do
      let(:build) { create(:ci_build, :created, project: project, pipeline: pipeline) }
      let(:build2) { create(:ci_build, :created, project: project, pipeline: pipeline) }
      let!(:job_artifact) { create(:ci_job_artifact, :dotenv, job: build2, accessibility: accessibility) }

      let!(:job_variable_1) { create(:ci_job_variable, :dotenv_source, job: build2) }
      let!(:job_variable_2) { create(:ci_job_variable, job: build2) }

      subject { build.job_dependencies_with_accessible_artifacts([build2]) }

      context 'inherits only jobs whose artifacts are public' do
        let(:accessibility) { 'public' }

        it { expect(subject).to eq([build2]) }
      end

      context 'inherits jobs whose artifacts are private' do
        let(:accessibility) { 'private' }

        it { expect(subject).to eq([build2]) }
      end
    end

    context 'in a different project' do
      let_it_be(:public_project) { create(:project, :public) }
      let(:build) { create(:ci_build, :created, project: project, pipeline: pipeline) }
      let(:build2) { create(:ci_build, :created, project: public_project) }
      let!(:job_artifact) { create(:ci_job_artifact, :dotenv, job: build2, accessibility: accessibility) }

      let!(:job_variable_1) { create(:ci_job_variable, :dotenv_source, job: build2) }
      let!(:job_variable_2) { create(:ci_job_variable, job: build2) }

      subject { build.job_dependencies_with_accessible_artifacts([build2]) }

      context 'inherits only jobs whose artifacts are public' do
        let(:accessibility) { 'public' }

        it { expect(subject).to eq([build2]) }
      end

      context 'does not inherit jobs whose artifacts are private' do
        let(:accessibility) { 'private' }

        it { expect(subject).to eq([]) }
      end
    end
  end
end
