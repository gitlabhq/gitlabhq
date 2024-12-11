# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CreateDownstreamPipelineService, '#execute', feature_category: :continuous_integration do
  include Ci::SourcePipelineHelpers
  include Ci::PipelineMessageHelpers

  # Using let_it_be on user and projects for these specs can cause
  # spec-ordering failures due to the project-based permissions
  # associating them. They should be recreated every time.
  let(:user) { create(:user) }
  let(:upstream_project) { create(:project, :repository) }
  let(:downstream_project) { create(:project, :repository) }

  let!(:upstream_pipeline) do
    create(:ci_pipeline, :created, project: upstream_project)
  end

  let(:trigger) do
    {
      trigger: {
        project: downstream_project.full_path,
        branch: 'feature'
      }
    }
  end

  let(:bridge) do
    create(
      :ci_bridge,
      status: :pending,
      user: user,
      options: trigger,
      pipeline: upstream_pipeline
    )
  end

  let(:service) { described_class.new(upstream_project, user) }
  let(:pipeline) { subject.payload }

  before do
    upstream_project.add_developer(user)
  end

  subject { service.execute(bridge) }

  context 'when downstream project has not been found' do
    let(:trigger) do
      { trigger: { project: 'unknown/project' } }
    end

    it 'does not create a pipeline' do
      expect { subject }
        .not_to change { Ci::Pipeline.count }
      expect(subject).to be_error
      expect(subject.message).to eq("Pre-conditions not met")
    end

    it 'changes pipeline bridge job status to failed' do
      subject

      expect(bridge.reload).to be_failed
      expect(bridge.failure_reason)
        .to eq 'downstream_bridge_project_not_found'
    end
  end

  context 'when user can not access downstream project' do
    it 'does not create a new pipeline' do
      expect { subject }
        .not_to change { Ci::Pipeline.count }
      expect(subject).to be_error
      expect(subject.message).to eq("Pre-conditions not met")
    end

    it 'changes status of the bridge build to failed' do
      subject

      expect(bridge.reload).to be_failed
      expect(bridge.failure_reason)
        .to eq 'downstream_bridge_project_not_found'
    end
  end

  context 'when user does not have access to create pipeline' do
    before do
      downstream_project.add_guest(user)
    end

    it 'does not create a new pipeline' do
      expect { subject }
        .not_to change { Ci::Pipeline.count }
      expect(subject).to be_error
      expect(subject.message).to eq("Pre-conditions not met")
    end

    it 'changes status of the bridge build to failed' do
      subject

      expect(bridge.reload).to be_failed
      expect(bridge.failure_reason).to eq 'insufficient_bridge_permissions'
    end
  end

  context 'when user can create pipeline in a downstream project' do
    let(:stub_config) { true }

    before do
      downstream_project.add_developer(user)
      stub_ci_pipeline_yaml_file(YAML.dump(rspec: { script: 'rspec' })) if stub_config
    end

    it 'creates only one new pipeline' do
      expect { subject }
        .to change { Ci::Pipeline.count }.by(1)
      expect(subject).to be_success
    end

    it 'creates a new pipeline in a downstream project' do
      expect(pipeline.user).to eq bridge.user
      expect(pipeline.project).to eq downstream_project
      expect(bridge.reload.sourced_pipeline.pipeline).to eq pipeline
      expect(pipeline.triggered_by_pipeline).to eq upstream_pipeline
      expect(pipeline.source_bridge).to eq bridge
      expect(pipeline.source_bridge).to be_a ::Ci::Bridge
    end

    it_behaves_like 'logs downstream pipeline creation' do
      let(:downstream_pipeline) { pipeline }
      let(:expected_root_pipeline) { upstream_pipeline }
      let(:expected_hierarchy_size) { 2 }
      let(:expected_downstream_relationship) { :multi_project }
    end

    it 'updates bridge status when downstream pipeline gets processed' do
      expect(pipeline.reload).to be_created
      expect(bridge.reload).to be_success
    end

    it 'returns and tracks an error for invalid status transitions' do
      allow(bridge).to receive(:success!).and_raise(
        StateMachines::InvalidTransition.new(
          bridge,
          Ci::Bridge.state_machines[:status],
          'success'
        )
      )

      expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
        instance_of(Ci::Bridge::InvalidTransitionError),
        { bridge_id: bridge.id, downstream_pipeline_id: anything }
      ) do |error|
        expect(error.backtrace).to be_present
      end

      expect(subject).to be_error
    end

    it 'triggers the upstream pipeline duration calculation', :sidekiq_inline do
      expect { subject }
        .to change { upstream_pipeline.reload.duration }.from(nil).to(an_instance_of(Integer))
    end

    context 'when bridge job has already any downstream pipeline' do
      before do
        bridge.create_sourced_pipeline!(
          source_pipeline: bridge.pipeline,
          source_project: bridge.project,
          project: bridge.project,
          pipeline: create(:ci_pipeline, project: bridge.project)
        )
      end

      it 'logs an error and exits' do
        expect(Gitlab::ErrorTracking)
          .to receive(:track_exception)
          .with(
            instance_of(described_class::DuplicateDownstreamPipelineError),
            bridge_id: bridge.id, project_id: bridge.project.id)
          .and_call_original
        expect(Ci::CreatePipelineService).not_to receive(:new)
        expect(subject).to be_error
        expect(subject.message).to eq("Already has a downstream pipeline")
      end
    end

    context 'when target ref is not specified' do
      let(:trigger) do
        { trigger: { project: downstream_project.full_path } }
      end

      it 'is using default branch name' do
        expect(pipeline.ref).to eq 'master'
      end
    end

    context 'when downstream pipeline has yaml configuration error' do
      before do
        stub_ci_pipeline_yaml_file(YAML.dump(job: { invalid: 'yaml' }))
      end

      it 'creates only one new pipeline' do
        expect { subject }
          .to change { Ci::Pipeline.count }.by(1)
        expect(subject).to be_error
        expect(subject.message)
          .to match_array(["jobs job config should implement the script:, run:, or trigger: keyword"])
      end

      it 'creates a new pipeline in a downstream project' do
        expect(pipeline.user).to eq bridge.user
        expect(pipeline.project).to eq downstream_project
        expect(bridge.reload.sourced_pipeline.pipeline).to eq pipeline
        expect(pipeline.triggered_by_pipeline).to eq upstream_pipeline
        expect(pipeline.source_bridge).to eq bridge
        expect(pipeline.source_bridge).to be_a ::Ci::Bridge
      end

      it 'updates the bridge status when downstream pipeline gets processed' do
        expect(pipeline.reload).to be_failed
        expect(bridge.reload).to be_failed
      end
    end

    context 'when downstream project is the same as the upstream project' do
      let(:trigger) do
        { trigger: { project: upstream_project.full_path } }
      end

      context 'detects a circular dependency' do
        it 'does not create a new pipeline' do
          expect { subject }
            .not_to change { Ci::Pipeline.count }
          expect(subject).to be_error
          expect(subject.message).to eq("Pre-conditions not met")
        end

        it 'changes status of the bridge build' do
          subject

          expect(bridge.reload).to be_failed
          expect(bridge.failure_reason).to eq 'invalid_bridge_trigger'
        end
      end

      context 'when "include" is provided' do
        let(:file_content) do
          YAML.dump(
            rspec: { script: 'rspec' },
            echo: { script: 'echo' })
        end

        shared_examples 'creates a child pipeline' do
          it 'creates only one new pipeline' do
            expect { subject }
              .to change { Ci::Pipeline.count }.by(1)
            expect(subject).to be_success
          end

          it 'creates a child pipeline in the same project' do
            expect(pipeline.builds.map(&:name)).to match_array(%w[rspec echo])
            expect(pipeline.user).to eq bridge.user
            expect(pipeline.project).to eq bridge.project
            expect(bridge.reload.sourced_pipeline.pipeline).to eq pipeline
            expect(pipeline.triggered_by_pipeline).to eq upstream_pipeline
            expect(pipeline.source_bridge).to eq bridge
            expect(pipeline.source_bridge).to be_a ::Ci::Bridge
          end

          it 'updates bridge status when downstream pipeline gets processed' do
            expect(pipeline.reload).to be_created
            expect(bridge.reload).to be_success
          end

          it 'propagates parent pipeline settings to the child pipeline' do
            expect(pipeline.ref).to eq(upstream_pipeline.ref)
            expect(pipeline.sha).to eq(upstream_pipeline.sha)
            expect(pipeline.source_sha).to eq(upstream_pipeline.source_sha)
            expect(pipeline.target_sha).to eq(upstream_pipeline.target_sha)
            expect(pipeline.target_sha).to eq(upstream_pipeline.target_sha)

            expect(pipeline.trigger_requests.last).to eq(bridge.trigger_request)
          end
        end

        before do
          upstream_project.repository.create_file(
            user, 'child-pipeline.yml', file_content, message: 'message', branch_name: 'master')

          upstream_pipeline.update!(sha: upstream_project.commit.id)
        end

        let(:stub_config) { false }

        let(:trigger) do
          {
            trigger: { include: 'child-pipeline.yml' }
          }
        end

        it_behaves_like 'creates a child pipeline'

        it_behaves_like 'logs downstream pipeline creation' do
          let(:downstream_pipeline) { pipeline }
          let(:expected_root_pipeline) { upstream_pipeline }
          let(:expected_hierarchy_size) { 2 }
          let(:expected_downstream_relationship) { :parent_child }
        end

        it 'updates the bridge job to success' do
          expect { subject }.to change { bridge.status }.to 'success'
          expect(subject).to be_success
        end

        context 'when bridge uses "depend" strategy' do
          let(:trigger) do
            {
              trigger: { include: 'child-pipeline.yml', strategy: 'depend' }
            }
          end

          it 'update the bridge job to running status' do
            expect { subject }.to change { bridge.status }.from('pending').to('running')
            expect(subject).to be_success
          end
        end

        context 'when latest sha for the ref changed in the meantime' do
          before do
            upstream_project.repository.create_file(
              user, 'another-change', 'test', message: 'message', branch_name: 'master')
          end

          # it does not auto-cancel pipelines from the same family
          it_behaves_like 'creates a child pipeline'
        end

        context 'when the parent is a merge request pipeline' do
          let(:merge_request) { create(:merge_request, source_project: bridge.project, target_project: bridge.project) }
          let(:file_content) do
            YAML.dump(
              workflow: { rules: [{ if: '$CI_MERGE_REQUEST_ID' }] },
              rspec: { script: 'rspec' },
              echo: { script: 'echo' })
          end

          before do
            bridge.pipeline.update!(source: :merge_request_event, merge_request: merge_request)
          end

          it_behaves_like 'creates a child pipeline'

          it 'propagates the merge request to the child pipeline' do
            expect(pipeline.merge_request).to eq(merge_request)
            expect(pipeline).to be_merge_request
          end
        end

        context 'when upstream pipeline has a parent pipeline' do
          before do
            create(:ci_sources_pipeline,
              source_pipeline: create(:ci_pipeline, project: upstream_pipeline.project),
              pipeline: upstream_pipeline
            )
          end

          it 'creates the pipeline' do
            expect { subject }
              .to change { Ci::Pipeline.count }.by(1)
            expect(subject).to be_success

            expect(bridge.reload).to be_success
          end

          it_behaves_like 'logs downstream pipeline creation' do
            let(:downstream_pipeline) { pipeline }
            let(:expected_root_pipeline) { upstream_pipeline.parent_pipeline }
            let(:expected_hierarchy_size) { 3 }
            let(:expected_downstream_relationship) { :parent_child }
          end
        end

        context 'when upstream pipeline has a parent pipeline, which has a parent pipeline' do
          before do
            parent_of_upstream_pipeline = create(:ci_pipeline, project: upstream_pipeline.project)

            create(:ci_sources_pipeline,
              source_pipeline: create(:ci_pipeline, project: upstream_pipeline.project),
              pipeline: parent_of_upstream_pipeline
            )

            create(:ci_sources_pipeline,
              source_pipeline: parent_of_upstream_pipeline,
              pipeline: upstream_pipeline
            )
          end

          it 'does not create a second descendant pipeline' do
            expect { subject }
              .not_to change { Ci::Pipeline.count }

            expect(bridge.reload).to be_failed
            expect(bridge.failure_reason).to eq 'reached_max_descendant_pipelines_depth'
          end
        end

        context 'when upstream pipeline has two level upstream pipelines from different projects' do
          before do
            upstream_of_upstream_of_upstream_pipeline = create(:ci_pipeline)
            upstream_of_upstream_pipeline = create(:ci_pipeline)

            create(:ci_sources_pipeline,
              source_pipeline: upstream_of_upstream_of_upstream_pipeline,
              pipeline: upstream_of_upstream_pipeline
            )

            create(:ci_sources_pipeline,
              source_pipeline: upstream_of_upstream_pipeline,
              pipeline: upstream_pipeline
            )
          end

          it 'create the pipeline' do
            expect { subject }.to change { Ci::Pipeline.count }.by(1)
            expect(subject).to be_success
          end
        end

        context 'when downstream project does not allow user-defined variables for child pipelines' do
          before do
            bridge.yaml_variables = [{ key: 'BRIDGE', value: '$PIPELINE_VARIABLE-var', public: true }]

            upstream_pipeline.project.update!(restrict_user_defined_variables: true,
              ci_pipeline_variables_minimum_override_role: :maintainer)
          end

          it 'creates a new pipeline allowing variables to be passed downstream' do
            expect { subject }.to change { Ci::Pipeline.count }.by(1)
            expect(subject).to be_success
          end

          it 'passes variables downstream from the bridge' do
            pipeline.variables.map(&:key).tap do |variables|
              expect(variables).to include 'BRIDGE'
            end
          end
        end

        context 'when multi-project pipeline runs from child pipelines bridge job' do
          before do
            stub_ci_pipeline_yaml_file(YAML.dump(rspec: { script: 'rspec' }))
          end

          # instantiate new service, to clear memoized values from child pipeline run
          subject(:execute_with_trigger_project_bridge) do
            described_class.new(upstream_project, user).execute(trigger_project_bridge)
          end

          let!(:child_pipeline) do
            service.execute(bridge)
            bridge.downstream_pipeline
          end

          let!(:trigger_downstream_project) do
            {
              trigger: {
                project: downstream_project.full_path,
                branch: 'feature'
              }
            }
          end

          let!(:trigger_project_bridge) do
            create(
              :ci_bridge, status: :pending, user: user, options: trigger_downstream_project, pipeline: child_pipeline
            )
          end

          it 'creates a new pipeline' do
            expect { execute_with_trigger_project_bridge }
              .to change { Ci::Pipeline.count }.by(1)

            new_pipeline = trigger_project_bridge.downstream_pipeline

            expect(new_pipeline.child?).to eq(false)
            expect(new_pipeline.triggered_by_pipeline).to eq child_pipeline
            expect(trigger_project_bridge.reload).not_to be_failed
          end
        end
      end
    end

    describe 'cyclical dependency detection' do
      shared_examples 'detects cyclical pipelines' do
        it 'does not create a new pipeline' do
          expect { subject }
            .not_to change { Ci::Pipeline.count }
          expect(subject).to be_error
          expect(subject.message).to eq("Pre-conditions not met")
        end

        it 'changes status of the bridge build' do
          subject

          expect(bridge.reload).to be_failed
          expect(bridge.failure_reason).to eq 'pipeline_loop_detected'
        end
      end

      shared_examples 'passes cyclical pipeline precondition' do
        it 'creates a new pipeline' do
          expect { subject }
            .to change { Ci::Pipeline.count }
          expect(subject).to be_success
        end

        it 'expect bridge build not to be failed' do
          subject

          expect(bridge.reload).not_to be_failed
        end
      end

      context 'when pipeline ancestry contains 2 cycles of dependencies' do
        before do
          # A(push on master) -> B(pipeline on master) -> A(push on master) ->
          #   B(pipeline on master) -> A(push on master)
          pipeline_1 = create(:ci_pipeline, project: upstream_project, source: :push)
          pipeline_2 = create(:ci_pipeline, project: downstream_project, source: :pipeline)
          pipeline_3 = create(:ci_pipeline, project: upstream_project, source: :push)
          pipeline_4 = create(:ci_pipeline, project: downstream_project, source: :pipeline)

          create_source_pipeline(pipeline_1, pipeline_2)
          create_source_pipeline(pipeline_2, pipeline_3)
          create_source_pipeline(pipeline_3, pipeline_4)
          create_source_pipeline(pipeline_4, upstream_pipeline)
        end

        it_behaves_like 'detects cyclical pipelines'
      end

      context 'when source in the ancestry differ' do
        before do
          # A(push on master) -> B(pipeline on master) -> A(pipeline on master)
          pipeline_1 = create(:ci_pipeline, project: upstream_project, source: :push)
          pipeline_2 = create(:ci_pipeline, project: downstream_project, source: :pipeline)
          upstream_pipeline.update!(source: :pipeline)

          create_source_pipeline(pipeline_1, pipeline_2)
          create_source_pipeline(pipeline_2, upstream_pipeline)
        end

        it_behaves_like 'passes cyclical pipeline precondition'
      end

      context 'when ref in the ancestry differ' do
        before do
          # A(push on master) -> B(pipeline on master) -> A(push on feature-1)
          pipeline_1 = create(:ci_pipeline, ref: 'master', project: upstream_project, source: :push)
          pipeline_2 = create(:ci_pipeline, ref: 'master', project: downstream_project, source: :pipeline)
          upstream_pipeline.update!(ref: 'feature-1')

          create_source_pipeline(pipeline_1, pipeline_2)
          create_source_pipeline(pipeline_2, upstream_pipeline)
        end

        it_behaves_like 'passes cyclical pipeline precondition'
      end

      context 'when only 1 cycle is detected' do
        before do
          # A(push on master) -> B(pipeline on master) -> A(push on master)
          pipeline_1 = create(:ci_pipeline, ref: 'master', project: upstream_project, source: :push)
          pipeline_2 = create(:ci_pipeline, ref: 'master', project: downstream_project, source: :pipeline)

          create_source_pipeline(pipeline_1, pipeline_2)
          create_source_pipeline(pipeline_2, upstream_pipeline)
        end

        it_behaves_like 'passes cyclical pipeline precondition'
      end
    end

    context 'when downstream pipeline creation errors out' do
      let(:stub_config) { false }

      before do
        stub_ci_pipeline_yaml_file(YAML.dump(invalid: { yaml: 'error' }))
      end

      it 'creates only one new pipeline' do
        expect { subject }
          .to change { Ci::Pipeline.count }.by(1)
        expect(subject).to be_error
        expect(subject.message)
          .to match_array(["jobs invalid config should implement the script:, run:, or trigger: keyword"])
      end

      it 'creates a new pipeline in the downstream project' do
        expect(pipeline.user).to eq bridge.user
        expect(pipeline.project).to eq downstream_project
      end

      it 'drops the bridge' do
        expect(pipeline.reload).to be_failed
        expect(bridge.reload).to be_failed
        expect(bridge.failure_reason).to eq('downstream_pipeline_creation_failed')
      end
    end

    context 'when bridge job status update raises state machine errors' do
      let(:stub_config) { false }

      before do
        stub_ci_pipeline_yaml_file(YAML.dump(invalid: { yaml: 'error' }))
        bridge.drop!
      end

      it 'returns the error' do
        expect { subject }.not_to change(downstream_project.ci_pipelines, :count)
        expect(subject).to be_error
        expect(subject.message).to eq('Can not run the bridge')
      end
    end

    context 'when bridge job has YAML variables defined' do
      before do
        bridge.yaml_variables = [{ key: 'BRIDGE', value: 'var', public: true }]
        downstream_project.update!(ci_pipeline_variables_minimum_override_role: :developer)
      end

      it 'passes bridge variables to downstream pipeline' do
        expect(pipeline.variables.first)
          .to have_attributes(key: 'BRIDGE', value: 'var')
      end
    end

    context 'when pipeline variables are defined' do
      before do
        upstream_pipeline.variables.create!(key: 'PIPELINE_VARIABLE', value: 'my-value')
      end

      it 'does not pass pipeline variables directly downstream' do
        pipeline.variables.map(&:key).tap do |variables|
          expect(variables).not_to include 'PIPELINE_VARIABLE'
        end
      end

      context 'when using YAML variables interpolation' do
        before do
          bridge.yaml_variables = [{ key: 'BRIDGE', value: '$PIPELINE_VARIABLE-var', public: true }]
          downstream_project.update!(ci_pipeline_variables_minimum_override_role: :developer)
        end

        it 'makes it possible to pass pipeline variable downstream' do
          pipeline.variables.find_by(key: 'BRIDGE').tap do |variable|
            expect(variable.value).to eq 'my-value-var'
          end
        end

        context 'when downstream project does not allow user-defined variables for multi-project pipelines' do
          before do
            downstream_project.update!(restrict_user_defined_variables: true,
              ci_pipeline_variables_minimum_override_role: :maintainer)
          end

          it 'does not create a new pipeline' do
            expect { subject }
              .not_to change { Ci::Pipeline.count }
            expect(subject).to be_error
            expect(subject.message).to match_array(["Insufficient permissions to set pipeline variables"])
          end

          it 'ignores variables passed downstream from the bridge' do
            pipeline.variables.map(&:key).tap do |variables|
              expect(variables).not_to include 'BRIDGE'
            end
          end

          it 'sets errors', :aggregate_failures do
            subject

            expect(bridge.reload).to be_failed
            expect(bridge.failure_reason).to eq('downstream_pipeline_creation_failed')
            expect(bridge.options[:downstream_errors]).to eq(['Insufficient permissions to set pipeline variables'])
          end
        end
      end
    end

    # TODO: Move this context into a feature spec that uses
    # multiple pipeline processing services. Location TBD in:
    # https://gitlab.com/gitlab-org/gitlab/issues/36216
    context 'when configured with bridge job rules', :sidekiq_inline do
      before do
        stub_ci_pipeline_yaml_file(config)
        downstream_project.add_maintainer(upstream_project.first_owner)
      end

      let(:config) do
        <<-EOY
          hello:
            script: echo world

          bridge-job:
            rules:
              - if: $CI_COMMIT_REF_NAME == "master"
            trigger:
              project: #{downstream_project.full_path}
              branch: master
        EOY
      end

      let(:primary_pipeline) do
        Ci::CreatePipelineService.new(upstream_project, upstream_project.first_owner, { ref: 'master' })
          .execute(:push, save_on_errors: false)
          .payload
      end

      let(:bridge)  { primary_pipeline.processables.find_by(name: 'bridge-job') }
      let(:service) { described_class.new(upstream_project, upstream_project.first_owner) }

      context 'that include the bridge job' do
        it 'creates the downstream pipeline' do
          expect { subject }
            .to change(downstream_project.ci_pipelines, :count).by(1)
          expect(subject).to be_error
          expect(subject.message).to eq("Already has a downstream pipeline")
        end
      end
    end

    context 'when user does not have access to push protected branch of downstream project' do
      before do
        create(:protected_branch, :maintainers_can_push, project: downstream_project, name: 'feature')
      end

      it 'changes status of the bridge build' do
        subject

        expect(bridge.reload).to be_failed
        expect(bridge.failure_reason).to eq 'insufficient_bridge_permissions'
      end
    end

    context 'when there is no such branch in downstream project' do
      let(:trigger) do
        {
          trigger: {
            project: downstream_project.full_path,
            branch: 'invalid_branch'
          }
        }
      end

      it 'does not create a pipeline and drops the bridge' do
        expect { subject }.not_to change(downstream_project.ci_pipelines, :count)
        expect(subject).to be_error
        expect(subject.message).to match_array(["Reference not found"])

        expect(bridge.reload).to be_failed
        expect(bridge.failure_reason).to eq('downstream_pipeline_creation_failed')
        expect(bridge.options[:downstream_errors]).to eq(['Reference not found'])
      end
    end

    context 'when downstream pipeline has a branch rule and does not satisfy' do
      before do
        stub_ci_pipeline_yaml_file(config)
      end

      let(:config) do
        <<-EOY
          hello:
            script: echo world
            only:
              - invalid_branch
        EOY
      end

      it 'does not create a pipeline and drops the bridge' do
        expect { subject }.not_to change(downstream_project.ci_pipelines, :count)
        expect(subject).to be_error
        expect(subject.message).to match_array([sanitize_message(Ci::Pipeline.rules_failure_message)])

        expect(bridge.reload).to be_failed
        expect(bridge.failure_reason).to eq('downstream_pipeline_creation_failed')
        expect(bridge.options[:downstream_errors]).to match_array(
          [sanitize_message(Ci::Pipeline.rules_failure_message)])
      end
    end

    context 'when downstream pipeline has invalid YAML' do
      before do
        stub_ci_pipeline_yaml_file(config)
      end

      let(:config) do
        <<-EOY
          test:
            stage: testx
            script: echo 1
        EOY
      end

      it 'creates the pipeline but drops the bridge' do
        expect { subject }.to change(downstream_project.ci_pipelines, :count).by(1)
        expect(subject).to be_error
        expect(subject.message).to eq(
          ["test job: chosen stage testx does not exist; available stages are .pre, build, test, deploy, .post"]
        )

        expect(bridge.reload).to be_failed
        expect(bridge.failure_reason).to eq('downstream_pipeline_creation_failed')
        expect(bridge.options[:downstream_errors]).to eq(
          ['test job: chosen stage testx does not exist; available stages are .pre, build, test, deploy, .post']
        )
      end
    end

    context 'when downstream pipeline has workflow rule' do
      before do
        stub_ci_pipeline_yaml_file(config)
        downstream_project.update!(ci_pipeline_variables_minimum_override_role: :developer)
      end

      let(:config) do
        <<-EOY
          workflow:
            rules:
              - if: $my_var

          regular-job:
            script: 'echo Hello, World!'
        EOY
      end

      context 'when passing the required variable' do
        before do
          bridge.yaml_variables = [{ key: 'my_var', value: 'var', public: true }]
        end

        it 'creates the pipeline' do
          expect { subject }.to change(downstream_project.ci_pipelines, :count).by(1)
          expect(subject).to be_success

          expect(bridge.reload).to be_success
        end
      end

      context 'when not passing the required variable' do
        it 'does not create the pipeline' do
          expect { subject }.not_to change(downstream_project.ci_pipelines, :count)
        end
      end
    end

    context 'when a downstream pipeline has sibling pipelines' do
      it_behaves_like 'logs downstream pipeline creation' do
        let(:downstream_pipeline) { pipeline }
        let(:expected_root_pipeline) { upstream_pipeline }
        let(:expected_downstream_relationship) { :multi_project }

        # New downstream, plus upstream, plus two children of upstream created below
        let(:expected_hierarchy_size) { 4 }

        before do
          create_list(:ci_pipeline, 2, child_of: upstream_pipeline)
        end
      end
    end

    context 'when the pipeline tree is too large' do
      let_it_be(:parent)     { create(:ci_pipeline) }
      let_it_be(:child)      { create(:ci_pipeline, child_of: parent) }
      let_it_be(:sibling)    { create(:ci_pipeline, child_of: parent) }

      let(:project) { create(:project, :repository) }
      let(:bridge) do
        create(:ci_bridge, status: :pending, user: user, options: trigger, pipeline: child, project: project)
      end

      context 'when limit was specified by admin' do
        before do
          project.actual_limits.update!(pipeline_hierarchy_size: 3)
        end

        it 'does not create a new pipeline' do
          expect { subject }.not_to change { Ci::Pipeline.count }
        end

        it 'drops the trigger job with an explanatory reason' do
          subject

          expect(bridge.reload).to be_failed
          expect(bridge.failure_reason).to eq('reached_max_pipeline_hierarchy_size')
        end
      end

      context 'when there was no limit specified by admin' do
        before do
          allow(bridge.pipeline).to receive(:complete_hierarchy_count).and_return(1000)
        end

        context 'when pipeline count reaches the default limit of 1000' do
          it 'does not create a new pipeline' do
            expect { subject }.not_to change { Ci::Pipeline.count }
            expect(subject).to be_error
            expect(subject.message).to eq("Pre-conditions not met")
          end

          it 'drops the trigger job with an explanatory reason' do
            subject

            expect(bridge.reload).to be_failed
            expect(bridge.failure_reason).to eq('reached_max_pipeline_hierarchy_size')
          end
        end
      end
    end
  end

  context 'when downstream pipeline creation fails with unexpected errors', :aggregate_failures do
    before do
      downstream_project.add_developer(user)

      allow(::Ci::CreatePipelineService).to receive(:new)
        .and_raise(RuntimeError, 'undefined failure')
    end

    it 'drops the bridge without creating a pipeline' do
      expect { subject }
        .to raise_error(RuntimeError, /undefined failure/)
        .and change { Ci::Pipeline.count }.by(0)

      expect(bridge.reload).to be_failed
      expect(bridge.failure_reason).to eq('data_integrity_failure')
    end
  end
end
