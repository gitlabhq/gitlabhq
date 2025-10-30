# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Processable, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project) }
  let_it_be_with_refind(:pipeline) { create(:ci_pipeline, project: project) }

  describe 'associations' do
    it { is_expected.to have_one(:trigger).through(:pipeline) }
    it { is_expected.to have_one(:job_environment).class_name('Environments::Job').inverse_of(:job) }
    it { is_expected.to have_one(:job_definition_instance) }
    it { is_expected.to have_one(:job_definition).through(:job_definition_instance) }
    it { is_expected.to have_many(:job_messages).class_name('Ci::JobMessage').inverse_of(:job) }
    it { is_expected.to have_many(:error_job_messages).class_name('Ci::JobMessage').inverse_of(:job) }
  end

  describe 'delegations' do
    subject { described_class.new }

    it { is_expected.to delegate_method(:merge_request?).to(:pipeline) }
    it { is_expected.to delegate_method(:merge_request_ref?).to(:pipeline) }
    it { is_expected.to delegate_method(:legacy_detached_merge_request_pipeline?).to(:pipeline) }
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
          processable.reload
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

  describe '.fabricate' do
    let(:build_attributes) { { options: { script: ['echo'] }, project_id: 1, partition_id: 99 } }

    subject(:fabricate) { described_class.fabricate(build_attributes) }

    it 'initializes with temp_job_definition' do
      expect(fabricate.metadata&.config_options).to be_nil
      expect(fabricate).to have_attributes(
        temp_job_definition: instance_of(Ci::JobDefinition),
        job_definition: nil
      )
      expect(fabricate.temp_job_definition.config).to eq({ options: build_attributes[:options] })
      expect(fabricate.temp_job_definition.project_id).to eq(build_attributes[:project_id])
      expect(fabricate.temp_job_definition.partition_id).to eq(build_attributes[:partition_id])
    end
  end

  describe '#archived?' do
    shared_examples 'an archivable job' do
      it { is_expected.not_to be_archived }

      context 'when job is degenerated' do
        before do
          job.degenerate!
          job.reload
        end

        it { is_expected.to be_archived }
      end

      context 'when pipeline is archived' do
        before do
          pipeline.update!(created_at: 1.day.ago)
          stub_application_setting(archive_builds_in_seconds: 3600)
        end

        it { is_expected.to be_archived }
      end
    end

    context 'when job is a build' do
      subject(:job) { create(:ci_build, pipeline: pipeline) }

      it_behaves_like 'an archivable job'
    end

    context 'when job is a bridge' do
      subject(:job) { create(:ci_bridge, pipeline: pipeline) }

      it_behaves_like 'an archivable job'
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
      subject(:job) { build(:ci_build, :manual, :with_manual_confirmation) }

      it 'return manual_confirmation from option' do
        expect(job.manual_confirmation_message).to eq('Please confirm. Do you want to proceed?')
      end

      context "when job is not playable because it's archived" do
        before do
          allow(job).to receive(:archived?).and_return(true)
        end

        it { expect(job.manual_confirmation_message).to be_nil }
      end
    end

    context 'when job is not manual' do
      subject(:job) { build(:ci_build) }

      it { expect(job.manual_confirmation_message).to be_nil }
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

  describe '#trigger_short_token' do
    let_it_be(:pipeline) { create(:ci_pipeline, :triggered, project: project) }
    let_it_be(:stage) { create(:ci_stage, project: project, pipeline: pipeline, name: 'test') }
    let_it_be(:processable) { create(:ci_build, :triggered, stage_id: stage.id, pipeline: pipeline) }

    it 'delegates to trigger' do
      expect(processable.trigger).to receive(:short_token)
      processable.trigger_short_token
    end
  end

  describe '#redis_state' do
    let(:processable) { build_stubbed(:ci_processable, pipeline: pipeline) }

    it 'is a memoized Ci::JobRedisState record' do
      expect(processable.redis_state).to be_an_instance_of(Ci::JobRedisState)
      expect(processable.strong_memoized?(:redis_state)).to be(true)
    end
  end

  describe '#enqueue_immediately?', :clean_gitlab_redis_shared_state do
    let(:processable) { build_stubbed(:ci_processable, pipeline: pipeline) }

    [true, false].each do |value|
      context "when enqueue_immediately is set to #{value}" do
        before do
          processable.redis_state.enqueue_immediately = value
        end

        it { expect(processable.enqueue_immediately?).to be(value) }
      end
    end
  end

  describe '#set_enqueue_immediately!', :clean_gitlab_redis_shared_state do
    let(:processable) { build_stubbed(:ci_processable, pipeline: pipeline) }

    it 'changes enqueue_immediately to true' do
      expect { processable.set_enqueue_immediately! }
        .to change { processable.enqueue_immediately? }.to(true)
    end
  end
end
