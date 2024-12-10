# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Bridge, feature_category: :continuous_integration do
  let_it_be(:project, refind: true) { create(:project, :repository, :in_group) }
  let_it_be(:target_project) { create(:project, name: 'project', namespace: create(:namespace, name: 'my')) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

  let_it_be(:public_project) { create(:project, :public) }

  before_all do
    create(:ci_pipeline_variable, pipeline: pipeline, key: 'PVAR1', value: 'PVAL1')
  end

  let(:bridge) do
    create(:ci_bridge, :variables, status: :created, options: options, pipeline: pipeline)
  end

  let(:options) do
    { trigger: { project: 'my/project', branch: 'master' } }
  end

  it 'has one sourced pipeline' do
    expect(bridge).to have_one(:sourced_pipeline)
  end

  it_behaves_like 'has ID tokens', :ci_bridge

  it_behaves_like 'a retryable job'

  it_behaves_like 'a deployable job' do
    let(:job) { bridge }
  end

  it 'has one downstream pipeline' do
    expect(bridge).to have_one(:sourced_pipeline)
    expect(bridge).to have_one(:downstream_pipeline)
  end

  describe 'no-op methods for compatibility with Ci::Build' do
    it 'returns an empty array job_artifacts' do
      expect(bridge.job_artifacts).to eq(Ci::JobArtifact.none)
    end

    it 'return nil for artifacts_expire_at' do
      expect(bridge.artifacts_expire_at).to be_nil
    end

    it 'return nil for runner' do
      expect(bridge.runner).to be_nil
    end

    it 'returns an empty TagList for tag_list' do
      expect(bridge.tag_list).to be_a(Gitlab::Ci::Tags::TagList)
    end
  end

  describe '#retryable?' do
    let(:bridge) { create(:ci_bridge, :success) }

    it 'returns true' do
      expect(bridge.retryable?).to eq(true)
    end
  end

  context 'when there is a pipeline loop detected' do
    let(:bridge) { create(:ci_bridge, :failed, failure_reason: :pipeline_loop_detected) }

    it 'returns false' do
      expect(bridge.failure_reason).to eq('pipeline_loop_detected')
      expect(bridge.retryable?).to eq(false)
    end
  end

  context 'when the pipeline depth has reached the max descendents' do
    let(:bridge) { create(:ci_bridge, :failed, failure_reason: :reached_max_descendant_pipelines_depth) }

    it 'returns false' do
      expect(bridge.failure_reason).to eq('reached_max_descendant_pipelines_depth')
      expect(bridge.retryable?).to eq(false)
    end
  end

  describe '#tags' do
    it 'only has a bridge tag' do
      expect(bridge.tags).to eq [:bridge]
    end
  end

  describe '#detailed_status' do
    let(:user) { create(:user) }
    let(:status) { bridge.detailed_status(user) }

    it 'returns detailed status object' do
      expect(status).to be_a Gitlab::Ci::Status::Created
    end
  end

  describe '#scoped_variables' do
    it 'returns a hash representing variables' do
      variables = %w[
        CI_JOB_NAME CI_JOB_NAME_SLUG CI_JOB_STAGE CI_COMMIT_SHA
        CI_COMMIT_SHORT_SHA CI_COMMIT_BEFORE_SHA CI_COMMIT_REF_NAME
        CI_COMMIT_REF_SLUG CI_PROJECT_ID CI_PROJECT_NAME CI_PROJECT_PATH
        CI_PROJECT_PATH_SLUG CI_PROJECT_NAMESPACE CI_PROJECT_ROOT_NAMESPACE
        CI_PIPELINE_IID CI_CONFIG_PATH CI_PIPELINE_SOURCE CI_COMMIT_MESSAGE
        CI_COMMIT_TITLE CI_COMMIT_DESCRIPTION CI_COMMIT_REF_PROTECTED
        CI_COMMIT_TIMESTAMP CI_COMMIT_AUTHOR
      ]

      expect(bridge.scoped_variables.map { |v| v[:key] }).to include(*variables)
    end

    context 'when bridge has dependency which has dotenv variable in the same project' do
      let(:test) { create(:ci_build, pipeline: pipeline, stage_idx: 0) }
      let(:bridge) { create(:ci_bridge, pipeline: pipeline, stage_idx: 1, options: { dependencies: [test.name] }) }
      let!(:job_artifact) { create(:ci_job_artifact, :dotenv, job: test, accessibility: accessibility) }

      let!(:job_variable) { create(:ci_job_variable, :dotenv_source, job: test) }

      context 'includes inherited variable that is public' do
        let(:accessibility) { 'public' }

        it { expect(bridge.scoped_variables.to_hash).to include(job_variable.key => job_variable.value) }
      end

      context 'includes inherited variable that is private' do
        let(:accessibility) { 'private' }

        it { expect(bridge.scoped_variables.to_hash).to include(job_variable.key => job_variable.value) }
      end
    end

    context 'when bridge has dependency which has dotenv variable in a different project' do
      let(:test) { create(:ci_build, pipeline: pipeline, project: public_project, stage_idx: 0) }
      let(:bridge) { create(:ci_bridge, pipeline: pipeline, stage_idx: 1, options: { dependencies: [test.name] }) }
      let!(:job_artifact) { create(:ci_job_artifact, :dotenv, job: test, accessibility: accessibility) }

      let!(:job_variable) { create(:ci_job_variable, :dotenv_source, job: test) }

      context 'includes inherited variable that is public' do
        let(:accessibility) { 'public' }

        it { expect(bridge.scoped_variables.to_hash).to include(job_variable.key => job_variable.value) }
      end

      context 'does not include inherited variable that is private' do
        let(:accessibility) { 'private' }

        it { expect(bridge.scoped_variables.to_hash).not_to include(job_variable.key => job_variable.value) }
      end
    end
  end

  describe 'state machine events' do
    describe 'start_cancel!' do
      valid_statuses = Ci::HasStatus::CANCELABLE_STATUSES.map(&:to_sym) + [:manual]
      # Invalid statuses are statuses that are COMPLETED_STATUSES or already canceling
      invalid_statuses = Ci::HasStatus::AVAILABLE_STATUSES.map(&:to_sym) - valid_statuses

      valid_statuses.each do |status|
        it "transitions from #{status} to canceling" do
          bridge = create(:ci_bridge, status: status)

          bridge.start_cancel!

          expect(bridge.status).to eq('canceling')
        end
      end

      invalid_statuses.each do |status|
        it "does not transition from #{status} to canceling" do
          bridge = create(:ci_bridge, status: status)

          expect { bridge.start_cancel! }
            .to raise_error(StateMachines::InvalidTransition)
        end
      end
    end

    describe 'finish_cancel!' do
      valid_statuses = Ci::HasStatus::CANCELABLE_STATUSES.map(&:to_sym) + [:manual, :canceling]
      invalid_statuses = Ci::HasStatus::AVAILABLE_STATUSES.map(&:to_sym) - valid_statuses
      valid_statuses.each do |status|
        it "transitions from #{status} to canceling" do
          bridge = create(:ci_bridge, status: status)

          bridge.finish_cancel!

          expect(bridge.status).to eq('canceled')
        end
      end

      invalid_statuses.each do |status|
        it "does not transition from #{status} to canceling" do
          bridge = create(:ci_bridge, status: status)

          expect { bridge.finish_cancel! }
            .to raise_error(StateMachines::InvalidTransition)
        end
      end
    end
  end

  describe 'state machine transitions' do
    context 'when bridge points towards downstream' do
      %i[created manual].each do |status|
        it "schedules downstream pipeline creation when the status is #{status}" do
          bridge.status = status

          bridge.enqueue!

          expect(::Ci::CreateDownstreamPipelineWorker.jobs.last['args']).to eq([bridge.id])
        end
      end

      it "schedules downstream pipeline creation when the status is waiting for resource" do
        bridge.status = :waiting_for_resource

        bridge.enqueue_waiting_for_resource!

        expect(::Ci::CreateDownstreamPipelineWorker.jobs.last['args']).to match_array([bridge.id])
      end

      it 'raises error when the status is failed' do
        bridge.status = :failed

        expect { bridge.enqueue! }.to raise_error(StateMachines::InvalidTransition)
      end
    end
  end

  describe '#inherit_status_from_downstream!' do
    let(:downstream_pipeline) { build(:ci_pipeline, status: downstream_status) }

    before do
      bridge.status = 'pending'
      create(:ci_sources_pipeline, pipeline: downstream_pipeline, source_job: bridge)
    end

    subject { bridge.inherit_status_from_downstream!(downstream_pipeline) }

    context 'when status is not supported' do
      (::Ci::Pipeline::AVAILABLE_STATUSES - ::Ci::Pipeline::COMPLETED_STATUSES).map(&:to_s).each do |status|
        context "when status is #{status}" do
          let(:downstream_status) { status }

          it 'returns false' do
            expect(subject).to eq(false)
          end

          it 'does not change the bridge status' do
            expect { subject }.not_to change { bridge.status }.from('pending')
          end
        end
      end
    end

    context 'when status is supported' do
      using RSpec::Parameterized::TableSyntax

      where(:downstream_status, :upstream_status) do
        [
          %w[success success],
          %w[canceled canceled],
          %w[failed failed],
          %w[skipped failed]
        ]
      end

      with_them do
        it 'inherits the downstream status' do
          expect { subject }.to change { bridge.status }.from('pending').to(upstream_status)
        end
      end
    end

    Ci::HasStatus::COMPLETED_STATUSES.each do |bridge_starting_status|
      context "when initial bridge status is a completed status #{bridge_starting_status}" do
        before do
          bridge.status = bridge_starting_status
          create(:ci_sources_pipeline, pipeline: downstream_pipeline, source_job: bridge)
        end

        using RSpec::Parameterized::TableSyntax
        where(:downstream_status, :expected_bridge_status) do
          [
            %w[success success],
            %w[failed failed],
            %w[skipped failed]
          ]
        end

        with_them do
          it 'inherits the downstream status' do
            perform_transition = -> { subject }
            if bridge.status == expected_bridge_status
              expect { perform_transition.call }.not_to change { bridge.status }
            else
              expect { perform_transition.call }.to change { bridge.status }
                .from(bridge_starting_status)
                .to(expected_bridge_status)
            end
          end
        end
      end
    end
  end

  describe '#dependent?' do
    subject { bridge.dependent? }

    context 'when bridge has strategy depend' do
      let(:options) { { trigger: { project: 'my/project', strategy: 'depend' } } }

      it { is_expected.to be true }
    end

    context 'when bridge does not have strategy depend' do
      it { is_expected.to be false }
    end
  end

  describe '#yaml_variables' do
    it 'returns YAML variables' do
      expect(bridge.yaml_variables)
        .to include(key: 'BRIDGE', value: 'cross', public: true)
    end
  end

  describe '#downstream_variables' do
    # A new pipeline needs to be created in each test.
    # The pipeline #variables_builder is memoized. The builder internally also memoizes variables.
    # Having pipeline in a let_it_be might lead to flaky tests
    # because a test might expect new variables but the variables builder does not
    # return the new variables due to memoized results from previous tests.
    let(:pipeline) { create(:ci_pipeline, project: project) }

    subject(:downstream_variables) { bridge.downstream_variables }

    it 'returns variables that are going to be passed downstream' do
      expect(bridge.downstream_variables)
        .to contain_exactly(key: 'BRIDGE', value: 'cross')
    end

    context 'when using variables interpolation' do
      let(:yaml_variables) do
        [
          {
            key: 'EXPANDED',
            value: '$BRIDGE-bridge',
            public: true
          },
          {
            key: 'UPSTREAM_CI_PIPELINE_ID',
            value: '$CI_PIPELINE_ID',
            public: true
          },
          {
            key: 'UPSTREAM_CI_PIPELINE_URL',
            value: '$CI_PIPELINE_URL',
            public: true
          }
        ]
      end

      before do
        bridge.yaml_variables.concat(yaml_variables)
      end

      it 'correctly expands variables with interpolation' do
        expanded_values = pipeline
          .persisted_variables
          .to_hash
          .transform_keys { |key| "UPSTREAM_#{key}" }
          .map { |key, value| { key: key, value: value } }
          .push(key: 'EXPANDED', value: 'cross-bridge')

        expect(bridge.downstream_variables)
          .to match(a_collection_including(*expanded_values))
      end
    end

    context 'when using variables interpolation on file variables' do
      let(:yaml_variables) do
        [
          {
            key: 'EXPANDED_FILE',
            value: '$TEST_FILE_VAR'
          }
        ]
      end

      before do
        bridge.yaml_variables = yaml_variables
        create(:ci_variable, :file, project: bridge.pipeline.project, key: 'TEST_FILE_VAR', value: 'test-file-value')
      end

      it 'does not expand file variable and forwards the file variable' do
        expected_vars = [
          { key: 'EXPANDED_FILE', value: '$TEST_FILE_VAR' },
          { key: 'TEST_FILE_VAR', value: 'test-file-value', variable_type: :file }
        ]

        expect(bridge.downstream_variables).to contain_exactly(*expected_vars)
      end
    end

    context 'when recursive interpolation has been used' do
      before do
        bridge.yaml_variables = [{ key: 'EXPANDED', value: '$EXPANDED', public: true }]
      end

      it 'does not expand variable recursively' do
        expect(bridge.downstream_variables)
          .to contain_exactly(key: 'EXPANDED', value: '$EXPANDED')
      end
    end

    context 'forward variables' do
      using RSpec::Parameterized::TableSyntax

      where(:yaml_variables, :pipeline_variables, :variables) do
        nil   | nil   | %w[BRIDGE]
        nil   | false | %w[BRIDGE]
        nil   | true  | %w[BRIDGE PVAR1]
        false | nil   | %w[]
        false | false | %w[]
        false | true  | %w[PVAR1]
        true  | nil   | %w[BRIDGE]
        true  | false | %w[BRIDGE]
        true  | true  | %w[BRIDGE PVAR1]
      end

      with_them do
        let(:options) do
          {
            trigger: {
              project: 'my/project',
              branch: 'master',
              forward: { yaml_variables: yaml_variables,
                         pipeline_variables: pipeline_variables }.compact
            }
          }
        end

        before do
          create(:ci_pipeline_variable, pipeline: pipeline, key: 'PVAR1', value: 'PVAL1')
        end

        it 'returns variables according to the forward value' do
          expect(bridge.downstream_variables.map { |v| v[:key] }).to contain_exactly(*variables)
        end
      end

      context 'when sending a variable via both yaml and pipeline' do
        let(:options) do
          { trigger: { project: 'my/project', forward: { pipeline_variables: true } } }
        end

        before do
          bridge.yaml_variables = [{ key: 'SHARED_KEY', value: 'old_value' }]
          create(:ci_pipeline_variable, pipeline: pipeline, key: 'SHARED_KEY', value: 'new value')
        end

        it 'uses the pipeline variable' do
          expect(bridge.downstream_variables).to contain_exactly({ key: 'SHARED_KEY', value: 'new value' })
        end
      end

      context 'when sending a file variable from pipeline variable' do
        let(:options) do
          { trigger: { project: 'my/project', forward: { pipeline_variables: true } } }
        end

        before do
          bridge.yaml_variables = [{ key: 'FILE_VAR', value: 'old_value' }]
          create(:ci_pipeline_variable, :file, pipeline: pipeline, key: 'FILE_VAR', value: 'new value')
        end

        # The current behaviour forwards the file variable as an environment variable.
        # TODO: decide whether to forward as a file var in https://gitlab.com/gitlab-org/gitlab/-/issues/416334
        it 'forwards the pipeline file variable' do
          expect(bridge.downstream_variables).to contain_exactly({ key: 'FILE_VAR', value: 'new value' })
        end
      end

      context 'when a pipeline variable interpolates a scoped file variable' do
        let(:options) do
          { trigger: { project: 'my/project', forward: { pipeline_variables: true } } }
        end

        before do
          bridge.yaml_variables = [{ key: 'YAML_VAR', value: '$PROJECT_FILE_VAR' }]

          create(:ci_variable, :file, project: pipeline.project, key: 'PROJECT_FILE_VAR', value: 'project file')
          create(:ci_pipeline_variable, pipeline: pipeline, key: 'FILE_VAR', value: '$PROJECT_FILE_VAR')
        end

        it 'does not expand the scoped file variable and forwards the file variable' do
          expected_vars = [
            { key: 'FILE_VAR', value: '$PROJECT_FILE_VAR' },
            { key: 'YAML_VAR', value: '$PROJECT_FILE_VAR' },
            { key: 'PROJECT_FILE_VAR', value: 'project file', variable_type: :file }
          ]

          expect(bridge.downstream_variables).to contain_exactly(*expected_vars)
        end
      end

      context 'when the pipeline runs from a pipeline schedule' do
        let(:pipeline_schedule) { create(:ci_pipeline_schedule, :nightly, project: project) }
        let(:pipeline) { create(:ci_pipeline, pipeline_schedule: pipeline_schedule) }

        let(:options) do
          { trigger: { project: 'my/project', forward: { pipeline_variables: true } } }
        end

        before do
          pipeline_schedule.variables.create!(key: 'schedule_var_key', value: 'schedule var value')
        end

        it 'adds the schedule variable' do
          expected_vars = [
            { key: 'BRIDGE', value: 'cross' },
            { key: 'schedule_var_key', value: 'schedule var value' }
          ]

          expect(bridge.downstream_variables).to contain_exactly(*expected_vars)
        end
      end
    end

    context 'when sending a file variable from pipeline schedule' do
      let(:pipeline_schedule) { create(:ci_pipeline_schedule, :nightly, project: project) }
      let(:pipeline) { create(:ci_pipeline, pipeline_schedule: pipeline_schedule) }

      let(:options) do
        { trigger: { project: 'my/project', forward: { pipeline_variables: true } } }
      end

      before do
        bridge.yaml_variables = []
        pipeline_schedule.variables.create!(key: 'schedule_var_key', value: 'schedule var value', variable_type: :file)
      end

      # The current behaviour forwards the file variable as an environment variable.
      # TODO: decide whether to forward as a file var in https://gitlab.com/gitlab-org/gitlab/-/issues/416334
      it 'forwards the schedule file variable' do
        expect(bridge.downstream_variables).to contain_exactly({ key: 'schedule_var_key', value: 'schedule var value' })
      end
    end

    context 'when a pipeline schedule variable interpolates a scoped file variable' do
      let(:pipeline_schedule) { create(:ci_pipeline_schedule, :nightly, project: project) }
      let(:pipeline) { create(:ci_pipeline, pipeline_schedule: pipeline_schedule) }

      let(:options) do
        { trigger: { project: 'my/project', forward: { pipeline_variables: true } } }
      end

      before do
        bridge.yaml_variables = []
        create(:ci_variable, :file, project: pipeline.project, key: 'PROJECT_FILE_VAR', value: 'project file')
        pipeline_schedule.variables.create!(key: 'schedule_var_key', value: '$PROJECT_FILE_VAR')
      end

      it 'does not expand the scoped file variable and forwards the file variable' do
        expected_vars = [
          { key: 'schedule_var_key', value: '$PROJECT_FILE_VAR' },
          { key: 'PROJECT_FILE_VAR', value: 'project file', variable_type: :file }
        ]

        expect(bridge.downstream_variables).to contain_exactly(*expected_vars)
      end
    end

    context 'when using raw variables' do
      let(:options) do
        {
          trigger: {
            project: 'my/project',
            branch: 'master',
            forward: { yaml_variables: true,
                       pipeline_variables: true }.compact
          }
        }
      end

      let(:yaml_variables) do
        [
          {
            key: 'VAR6',
            value: 'value6 $VAR1'
          },
          {
            key: 'VAR7',
            value: 'value7 $VAR1',
            raw: true
          }
        ]
      end

      let(:pipeline_schedule) { create(:ci_pipeline_schedule, :nightly, project: project) }
      let(:pipeline) { create(:ci_pipeline, pipeline_schedule: pipeline_schedule) }

      before do
        create(:ci_pipeline_variable, pipeline: pipeline, key: 'VAR1', value: 'value1')
        create(:ci_pipeline_variable, pipeline: pipeline, key: 'VAR2', value: 'value2 $VAR1')
        create(:ci_pipeline_variable, pipeline: pipeline, key: 'VAR3', value: 'value3 $VAR1', raw: true)

        pipeline_schedule.variables.create!(key: 'VAR4', value: 'value4 $VAR1')
        pipeline_schedule.variables.create!(key: 'VAR5', value: 'value5 $VAR1', raw: true)

        bridge.yaml_variables.concat(yaml_variables)
      end

      it 'expands variables according to their raw attributes' do
        expect(downstream_variables).to contain_exactly(
          { key: 'BRIDGE', value: 'cross' },
          { key: 'VAR1', value: 'value1' },
          { key: 'VAR2', value: 'value2 value1' },
          { key: 'VAR3', value: 'value3 $VAR1', raw: true },
          { key: 'VAR4', value: 'value4 value1' },
          { key: 'VAR5', value: 'value5 $VAR1', raw: true },
          { key: 'VAR6', value: 'value6 value1' },
          { key: 'VAR7', value: 'value7 $VAR1', raw: true }
        )
      end
    end

    describe 'variables expansion' do
      let(:options) do
        {
          trigger: {
            project: 'my/project',
            branch: 'master',
            forward: { yaml_variables: true,
                       pipeline_variables: true }.compact
          }
        }
      end

      let(:yaml_variables) do
        [
          {
            key: 'EXPANDED_PROJECT_VAR6',
            value: 'project value6 $PROJECT_PROTECTED_VAR'
          },
          {
            key: 'EXPANDED_GROUP_VAR6',
            value: 'group value6 $GROUP_PROTECTED_VAR'
          },

          {
            key: 'VAR7',
            value: 'value7 $VAR1',
            raw: true
          }
        ]
      end

      let_it_be(:downstream_creator_user) { create(:user) }
      let_it_be(:bridge_creator_user) { create(:user) }

      let_it_be(:bridge_group) { create(:group) }
      let_it_be(:downstream_group) { create(:group) }
      let_it_be(:downstream_project) { create(:project, creator: downstream_creator_user, group: downstream_group) }
      let_it_be(:project) do
        create(:project, :repository, :in_group, creator: bridge_creator_user, group: bridge_group)
      end

      let(:ci_stage) { create(:ci_stage, pipeline: pipeline, project: pipeline.project) }
      let(:bridge) do
        build(:ci_bridge, :playable, pipeline: pipeline, downstream: downstream_project, ci_stage: ci_stage)
      end

      let!(:pipeline) { create(:ci_pipeline, project: project) }

      let!(:ci_variable) do
        create(:ci_variable,
          project: project,
          key: 'PROJECT_PROTECTED_VAR',
          value: 'this is a secret',
          protected: is_variable_protected?)
      end

      let!(:ci_group_variable) do
        create(:ci_group_variable,
          group: bridge_group,
          key: 'GROUP_PROTECTED_VAR',
          value: 'this is a secret',
          protected: is_variable_protected?)
      end

      before do
        bridge.yaml_variables = yaml_variables
        allow(bridge.project).to receive(:protected_for?).and_return(true)
      end

      shared_examples 'expands variables from a project downstream' do
        it do
          vars = bridge.downstream_variables
          expect(vars).to include({ key: 'EXPANDED_PROJECT_VAR6', value: 'project value6 this is a secret' })
        end
      end

      shared_examples 'expands variables from a group downstream' do
        it do
          vars = bridge.downstream_variables
          expect(vars).to include({ key: 'EXPANDED_GROUP_VAR6', value: 'group value6 this is a secret' })
        end
      end

      shared_examples 'expands project and group variables downstream' do
        it_behaves_like 'expands variables from a project downstream'

        it_behaves_like 'expands variables from a group downstream'
      end

      shared_examples 'does not expand variables from a project downstream' do
        it do
          vars = bridge.downstream_variables
          expect(vars).not_to include({ key: 'EXPANDED_PROJECT_VAR6', value: 'project value6 this is a secret' })
        end
      end

      shared_examples 'does not expand variables from a group downstream' do
        it do
          vars = bridge.downstream_variables
          expect(vars).not_to include({ key: 'EXPANDED_GROUP_VAR6', value: 'group value6 this is a secret' })
        end
      end

      shared_examples 'feature flag is disabled' do
        before do
          stub_feature_flags(exclude_protected_variables_from_multi_project_pipeline_triggers: false)
        end

        it_behaves_like 'expands project and group variables downstream'
      end

      shared_examples 'does not expand project and group variables downstream' do
        it_behaves_like 'does not expand variables from a project downstream'

        it_behaves_like 'does not expand variables from a group downstream'
      end

      context 'when they are protected' do
        let!(:is_variable_protected?) { true }

        context 'and downstream project group is different from bridge group' do
          it_behaves_like 'does not expand project and group variables downstream'

          it_behaves_like 'feature flag is disabled'
        end

        context 'and there is no downstream project' do
          let(:downstream_project) { nil }

          it_behaves_like 'expands project and group variables downstream'

          it_behaves_like 'feature flag is disabled'
        end

        context 'and downstream project equals bridge project' do
          let(:downstream_project) { project }

          it_behaves_like 'expands project and group variables downstream'

          it_behaves_like 'feature flag is disabled'
        end

        context 'and downstream project group is equal to bridge project group' do
          let_it_be(:downstream_project) { create(:project, creator: downstream_creator_user, group: bridge_group) }

          it_behaves_like 'expands variables from a group downstream'

          it_behaves_like 'does not expand variables from a project downstream'

          it_behaves_like 'feature flag is disabled'
        end

        context 'and downstream project has no group' do
          let_it_be(:downstream_project) { create(:project, creator: downstream_creator_user) }

          it_behaves_like 'does not expand project and group variables downstream'

          it_behaves_like 'feature flag is disabled'
        end
      end

      context 'when they are not protected' do
        let!(:is_variable_protected?) { false }

        context 'and downstream project group is different from bridge group' do
          it_behaves_like 'expands project and group variables downstream'

          it_behaves_like 'feature flag is disabled'
        end

        context 'and there is no downstream project' do
          let(:downstream_project) { nil }

          it_behaves_like 'expands project and group variables downstream'

          it_behaves_like 'feature flag is disabled'
        end

        context 'and downstream project equals bridge project' do
          let(:downstream_project) { project }

          it_behaves_like 'expands project and group variables downstream'

          it_behaves_like 'feature flag is disabled'
        end

        context 'and downstream project group is equal to bridge project group' do
          let_it_be(:downstream_project) { create(:project, creator: downstream_creator_user, group: bridge_group) }

          it_behaves_like 'expands project and group variables downstream'

          it_behaves_like 'feature flag is disabled'
        end

        context 'and downstream project has no group' do
          let_it_be(:downstream_project) { create(:project, creator: downstream_creator_user) }

          it_behaves_like 'expands project and group variables downstream'

          it_behaves_like 'feature flag is disabled'
        end
      end
    end
  end

  describe '#variables' do
    it 'returns bridge scoped variables and pipeline persisted variables' do
      expect(bridge.variables.to_hash)
        .to eq(bridge.scoped_variables.concat(bridge.pipeline.persisted_variables).to_hash)
    end
  end

  it_behaves_like 'a triggerable processable', :ci_bridge

  describe '#pipeline_variables' do
    it 'returns the pipeline variables' do
      expect(bridge.pipeline_variables).to eq(bridge.pipeline.variables)
    end
  end

  describe '#pipeline_schedule_variables' do
    context 'when pipeline is on a schedule' do
      let(:pipeline_schedule) { create(:ci_pipeline_schedule, project: project) }
      let(:pipeline) { create(:ci_pipeline, pipeline_schedule: pipeline_schedule) }

      it 'returns the pipeline schedule variables' do
        create(:ci_pipeline_schedule_variable, key: 'FOO', value: 'foo', pipeline_schedule: pipeline.pipeline_schedule)

        pipeline_schedule_variables = bridge.reload.pipeline_schedule_variables
        expect(pipeline_schedule_variables).to match_array([have_attributes({ key: 'FOO', value: 'foo' })])
      end
    end

    context 'when pipeline is not on a schedule' do
      it 'returns empty array' do
        expect(bridge.pipeline_schedule_variables).to eq([])
      end
    end
  end

  describe '#forward_yaml_variables?' do
    using RSpec::Parameterized::TableSyntax

    where(:forward, :result) do
      true | true
      false | false
      nil | true
    end

    with_them do
      let(:options) do
        {
          trigger: {
            project: 'my/project',
            branch: 'master',
            forward: { yaml_variables: forward }.compact
          }
        }
      end

      let(:bridge) { build(:ci_bridge, options: options) }

      it { expect(bridge.forward_yaml_variables?).to eq(result) }
    end
  end

  describe '#forward_pipeline_variables?' do
    using RSpec::Parameterized::TableSyntax

    where(:forward, :result) do
      true | true
      false | false
      nil | false
    end

    with_them do
      let(:options) do
        {
          trigger: {
            project: 'my/project',
            branch: 'master',
            forward: { pipeline_variables: forward }.compact
          }
        }
      end

      let(:bridge) { build(:ci_bridge, options: options) }

      it { expect(bridge.forward_pipeline_variables?).to eq(result) }
    end
  end

  describe 'metadata support' do
    it 'reads YAML variables from metadata' do
      expect(bridge.yaml_variables).not_to be_empty
      expect(bridge.metadata).to be_a Ci::BuildMetadata
      expect(bridge.read_attribute(:yaml_variables)).to be_nil
      expect(bridge.metadata.config_variables).to be bridge.yaml_variables
    end

    it 'reads options from metadata' do
      expect(bridge.options).not_to be_empty
      expect(bridge.metadata).to be_a Ci::BuildMetadata
      expect(bridge.read_attribute(:options)).to be_nil
      expect(bridge.metadata.config_options).to be bridge.options
    end
  end

  describe '#triggers_child_pipeline?' do
    subject { bridge.triggers_child_pipeline? }

    context 'when bridge defines a downstream YAML' do
      let(:options) do
        {
          trigger: {
            include: 'path/to/child.yml'
          }
        }
      end

      it { is_expected.to be_truthy }
    end

    context 'when bridge does not define a downstream YAML' do
      let(:options) do
        {
          trigger: {
            project: project.full_path
          }
        }
      end

      it { is_expected.to be_falsey }
    end
  end

  describe '#yaml_for_downstream' do
    subject { bridge.yaml_for_downstream }

    context 'when bridge defines a downstream YAML' do
      let(:options) do
        {
          trigger: {
            include: 'path/to/child.yml'
          }
        }
      end

      let(:yaml) do
        <<~EOY
          ---
          include: path/to/child.yml
        EOY
      end

      it { is_expected.to eq yaml }
    end

    context 'when bridge does not define a downstream YAML' do
      let(:options) { {} }

      it { is_expected.to be_nil }
    end
  end

  describe '#downstream_project_path' do
    context 'when trigger is defined' do
      context 'when using variable expansion' do
        let(:options) { { trigger: { project: 'my/$BRIDGE/project' } } }

        it 'correctly expands variables' do
          expect(bridge.downstream_project_path).to eq('my/cross/project')
        end
      end
    end
  end

  describe '#target_ref' do
    context 'when trigger is defined' do
      it 'returns a ref name' do
        expect(bridge.target_ref).to eq 'master'
      end

      context 'when using variable expansion' do
        let(:options) { { trigger: { project: 'my/project', branch: '$BRIDGE-master' } } }

        it 'correctly expands variables' do
          expect(bridge.target_ref).to eq('cross-master')
        end
      end
    end

    context 'when trigger does not have project defined' do
      let(:options) { nil }

      it 'returns nil' do
        expect(bridge.target_ref).to be_nil
      end
    end
  end

  describe '#play' do
    let(:downstream_project) { create(:project) }
    let(:user) { create(:user) }
    let(:bridge) { create(:ci_bridge, :playable, pipeline: pipeline, downstream: downstream_project) }

    subject { bridge.play(user) }

    before do
      project.add_maintainer(user)
      downstream_project.add_maintainer(user)
    end

    it 'enqueues the bridge' do
      subject

      expect(bridge).to be_pending
    end
  end

  describe '#playable?' do
    context 'when bridge is a manual action' do
      subject { build_stubbed(:ci_bridge, :manual).playable? }

      it { is_expected.to be_truthy }
    end

    context 'when build is not a manual action' do
      subject { build_stubbed(:ci_bridge, :created).playable? }

      it { is_expected.to be_falsey }
    end
  end

  describe '#action?' do
    context 'when bridge is a manual action' do
      subject { build_stubbed(:ci_bridge, :manual).action? }

      it { is_expected.to be_truthy }
    end

    context 'when build is not a manual action' do
      subject { build_stubbed(:ci_bridge, :created).action? }

      it { is_expected.to be_falsey }
    end
  end

  describe '#can_auto_cancel_pipeline_on_job_failure?' do
    subject { bridge.can_auto_cancel_pipeline_on_job_failure? }

    it { is_expected.to be true }
  end

  describe '#dependency_variables' do
    subject { bridge.dependency_variables }

    context 'when downloading from previous stages from the same project' do
      let!(:prepare1) { create(:ci_build, name: 'prepare1', pipeline: pipeline, stage_idx: 0) }
      let!(:bridge) { create(:ci_bridge, pipeline: pipeline, stage_idx: 1) }
      let!(:job_artifact) { create(:ci_job_artifact, :dotenv, job: prepare1, accessibility: accessibility) }

      let!(:job_variable_1) { create(:ci_job_variable, :dotenv_source, job: prepare1) }
      let!(:job_variable_2) { create(:ci_job_variable, job: prepare1) }

      context 'inherits dependent variables that are public' do
        let(:accessibility) { 'public' }

        it { expect(subject.to_hash).to eq(job_variable_1.key => job_variable_1.value) }
      end

      context 'inherits dependent variables that are private' do
        let(:accessibility) { 'private' }

        it { expect(subject.to_hash).to eq(job_variable_1.key => job_variable_1.value) }
      end
    end

    context 'when downloading from previous stages in a different project' do
      let!(:prepare1) { create(:ci_build, name: 'prepare1', pipeline: pipeline, project: public_project, stage_idx: 0) }
      let!(:bridge) { create(:ci_bridge, pipeline: pipeline, stage_idx: 1) }
      let!(:job_artifact) { create(:ci_job_artifact, :dotenv, job: prepare1, accessibility: accessibility) }

      let!(:job_variable_1) { create(:ci_job_variable, :dotenv_source, job: prepare1) }
      let!(:job_variable_2) { create(:ci_job_variable, job: prepare1) }

      context 'inherits dependent variables that are public' do
        let(:accessibility) { 'public' }

        it { expect(subject.to_hash).to eq(job_variable_1.key => job_variable_1.value) }
      end

      context 'does not inherit dependent variables that are private' do
        let(:accessibility) { 'private' }

        it { expect(subject.to_hash).not_to eq(job_variable_1.key => job_variable_1.value) }
      end
    end

    context 'when using needs within the same project' do
      let!(:prepare1) { create(:ci_build, name: 'prepare1', pipeline: pipeline, stage_idx: 0) }
      let!(:prepare2) { create(:ci_build, name: 'prepare2', pipeline: pipeline, stage_idx: 0) }
      let!(:prepare3) { create(:ci_build, name: 'prepare3', pipeline: pipeline, stage_idx: 0) }
      let!(:bridge) do
        create(
          :ci_bridge,
          pipeline: pipeline,
          stage_idx: 1,
          scheduling_type: 'dag',
          needs_attributes: [{ name: 'prepare1', artifacts: true }, { name: 'prepare2', artifacts: false }]
        )
      end

      let!(:job_artifact) { create(:ci_job_artifact, :dotenv, job: prepare1, accessibility: accessibility) }

      let!(:job_variable_1) { create(:ci_job_variable, :dotenv_source, job: prepare1) }
      let!(:job_variable_2) { create(:ci_job_variable, :dotenv_source, job: prepare2) }
      let!(:job_variable_3) { create(:ci_job_variable, :dotenv_source, job: prepare3) }

      context 'inherits only needs with artifacts variables that are public' do
        let(:accessibility) { 'public' }

        it { expect(subject.to_hash).to eq(job_variable_1.key => job_variable_1.value) }
      end

      context 'inherits needs with artifacts variables that are public' do
        let(:accessibility) { 'private' }

        it { expect(subject.to_hash).to eq(job_variable_1.key => job_variable_1.value) }
      end
    end

    context 'when using needs from different project' do
      let!(:prepare1) { create(:ci_build, name: 'prepare1', pipeline: pipeline, project: public_project, stage_idx: 0) }
      let!(:prepare2) { create(:ci_build, name: 'prepare2', pipeline: pipeline, stage_idx: 0) }
      let!(:prepare3) { create(:ci_build, name: 'prepare3', pipeline: pipeline, stage_idx: 0) }
      let!(:bridge) do
        create(
          :ci_bridge,
          pipeline: pipeline,
          stage_idx: 1,
          scheduling_type: 'dag',
          needs_attributes: [{ name: 'prepare1', artifacts: true }, { name: 'prepare2', artifacts: false }]
        )
      end

      let!(:job_artifact) { create(:ci_job_artifact, :dotenv, job: prepare1, accessibility: accessibility) }

      let!(:job_variable_1) { create(:ci_job_variable, :dotenv_source, job: prepare1) }
      let!(:job_variable_2) { create(:ci_job_variable, :dotenv_source, job: prepare2) }
      let!(:job_variable_3) { create(:ci_job_variable, :dotenv_source, job: prepare3) }

      context 'inherits only needs with artifacts variables that are public' do
        let(:accessibility) { 'public' }

        it { expect(subject.to_hash).to eq(job_variable_1.key => job_variable_1.value) }
      end

      context 'does not inherit needs with artifacts variables that are public' do
        let(:accessibility) { 'private' }

        it { expect(subject.to_hash).not_to eq(job_variable_1.key => job_variable_1.value) }
      end
    end
  end

  describe 'metadata partitioning' do
    let(:pipeline) do
      create(:ci_pipeline, project: project, partition_id: ci_testing_partition_id)
    end

    let(:ci_stage) { create(:ci_stage, pipeline: pipeline) }

    let(:bridge) do
      build(:ci_bridge, pipeline: pipeline, ci_stage: ci_stage)
    end

    it 'creates the metadata record and assigns its partition' do
      # The record is initialized by the factory calling metadatable setters
      bridge.metadata = nil

      expect(bridge.metadata).to be_nil

      expect(bridge.save!).to be_truthy

      expect(bridge.metadata).to be_present
      expect(bridge.metadata).to be_valid
      expect(bridge.metadata.partition_id).to eq(ci_testing_partition_id)
    end
  end

  describe '#deployment_job?' do
    subject { bridge.deployment_job? }

    it { is_expected.to eq(false) }
  end
end
