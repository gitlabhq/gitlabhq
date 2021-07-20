# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CreateDownstreamPipelineService, '#execute' do
  include Ci::SourcePipelineHelpers

  let_it_be(:user) { create(:user) }
  let(:upstream_project) { create(:project, :repository) }
  let_it_be(:downstream_project, refind: true) { create(:project, :repository) }

  let!(:upstream_pipeline) do
    create(:ci_pipeline, :running, project: upstream_project)
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
    create(:ci_bridge, status: :pending,
                       user: user,
                       options: trigger,
                       pipeline: upstream_pipeline)
  end

  let(:service) { described_class.new(upstream_project, user) }

  before do
    upstream_project.add_developer(user)
  end

  context 'when downstream project has not been found' do
    let(:trigger) do
      { trigger: { project: 'unknown/project' } }
    end

    it 'does not create a pipeline' do
      expect { service.execute(bridge) }
        .not_to change { Ci::Pipeline.count }
    end

    it 'changes pipeline bridge job status to failed' do
      service.execute(bridge)

      expect(bridge.reload).to be_failed
      expect(bridge.failure_reason)
        .to eq 'downstream_bridge_project_not_found'
    end
  end

  context 'when user can not access downstream project' do
    it 'does not create a new pipeline' do
      expect { service.execute(bridge) }
        .not_to change { Ci::Pipeline.count }
    end

    it 'changes status of the bridge build' do
      service.execute(bridge)

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
      expect { service.execute(bridge) }
        .not_to change { Ci::Pipeline.count }
    end

    it 'changes status of the bridge build' do
      service.execute(bridge)

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
      expect { service.execute(bridge) }
        .to change { Ci::Pipeline.count }.by(1)
    end

    it 'creates a new pipeline in a downstream project' do
      pipeline = service.execute(bridge)

      expect(pipeline.user).to eq bridge.user
      expect(pipeline.project).to eq downstream_project
      expect(bridge.sourced_pipelines.first.pipeline).to eq pipeline
      expect(pipeline.triggered_by_pipeline).to eq upstream_pipeline
      expect(pipeline.source_bridge).to eq bridge
      expect(pipeline.source_bridge).to be_a ::Ci::Bridge
    end

    it 'updates bridge status when downstream pipeline gets processed' do
      pipeline = service.execute(bridge)

      expect(pipeline.reload).to be_created
      expect(bridge.reload).to be_success
    end

    context 'when bridge job has already any downstream pipelines' do
      before do
        bridge.sourced_pipelines.create!(
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
        expect(service.execute(bridge)).to eq({ message: "Already has a downstream pipeline", status: :error })
      end
    end

    context 'when target ref is not specified' do
      let(:trigger) do
        { trigger: { project: downstream_project.full_path } }
      end

      it 'is using default branch name' do
        pipeline = service.execute(bridge)

        expect(pipeline.ref).to eq 'master'
      end
    end

    context 'when downstream pipeline has yaml configuration error' do
      before do
        stub_ci_pipeline_yaml_file(YAML.dump(job: { invalid: 'yaml' }))
      end

      it 'creates only one new pipeline' do
        expect { service.execute(bridge) }
          .to change { Ci::Pipeline.count }.by(1)
      end

      it 'creates a new pipeline in a downstream project' do
        pipeline = service.execute(bridge)

        expect(pipeline.user).to eq bridge.user
        expect(pipeline.project).to eq downstream_project
        expect(bridge.sourced_pipelines.first.pipeline).to eq pipeline
        expect(pipeline.triggered_by_pipeline).to eq upstream_pipeline
        expect(pipeline.source_bridge).to eq bridge
        expect(pipeline.source_bridge).to be_a ::Ci::Bridge
      end

      it 'updates the bridge status when downstream pipeline gets processed' do
        pipeline = service.execute(bridge)

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
          expect { service.execute(bridge) }
            .not_to change { Ci::Pipeline.count }
        end

        it 'changes status of the bridge build' do
          service.execute(bridge)

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
            expect { service.execute(bridge) }
              .to change { Ci::Pipeline.count }.by(1)
          end

          it 'creates a child pipeline in the same project' do
            pipeline = service.execute(bridge)
            pipeline.reload

            expect(pipeline.builds.map(&:name)).to match_array(%w[rspec echo])
            expect(pipeline.user).to eq bridge.user
            expect(pipeline.project).to eq bridge.project
            expect(bridge.sourced_pipelines.first.pipeline).to eq pipeline
            expect(pipeline.triggered_by_pipeline).to eq upstream_pipeline
            expect(pipeline.source_bridge).to eq bridge
            expect(pipeline.source_bridge).to be_a ::Ci::Bridge
          end

          it 'updates bridge status when downstream pipeline gets processed' do
            pipeline = service.execute(bridge)

            expect(pipeline.reload).to be_created
            expect(bridge.reload).to be_success
          end

          it 'propagates parent pipeline settings to the child pipeline' do
            pipeline = service.execute(bridge)
            pipeline.reload

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

        it 'updates the bridge job to success' do
          expect { service.execute(bridge) }.to change { bridge.status }.to 'success'
        end

        context 'when bridge uses "depend" strategy' do
          let(:trigger) do
            {
              trigger: { include: 'child-pipeline.yml', strategy: 'depend' }
            }
          end

          it 'does not update the bridge job status' do
            expect { service.execute(bridge) }.not_to change { bridge.status }
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
            pipeline = service.execute(bridge)

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
            expect { service.execute(bridge) }
              .to change { Ci::Pipeline.count }.by(1)

            expect(bridge.reload).to be_success
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
            expect { service.execute(bridge) }
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
            expect { service.execute(bridge) }.to change { Ci::Pipeline.count }.by(1)
          end
        end

        context 'when downstream project does not allow user-defined variables for child pipelines' do
          before do
            bridge.yaml_variables = [{ key: 'BRIDGE', value: '$PIPELINE_VARIABLE-var', public: true }]

            upstream_pipeline.project.update!(restrict_user_defined_variables: true)
          end

          it 'creates a new pipeline allowing variables to be passed downstream' do
            expect { service.execute(bridge) }.to change { Ci::Pipeline.count }.by(1)
          end

          it 'passes variables downstream from the bridge' do
            pipeline = service.execute(bridge)

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
              :ci_bridge, status: :pending,
              user: user,
              options: trigger_downstream_project,
              pipeline: child_pipeline
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

    context 'when relationship between pipelines is cyclical' do
      before do
        pipeline_a = create(:ci_pipeline, project: upstream_project)
        pipeline_b = create(:ci_pipeline, project: downstream_project)
        pipeline_c = create(:ci_pipeline, project: upstream_project)

        create_source_pipeline(pipeline_a, pipeline_b)
        create_source_pipeline(pipeline_b, pipeline_c)
        create_source_pipeline(pipeline_c, upstream_pipeline)
      end

      it 'does not create a new pipeline' do
        expect { service.execute(bridge) }
          .not_to change { Ci::Pipeline.count }
      end

      it 'changes status of the bridge build' do
        service.execute(bridge)

        expect(bridge.reload).to be_failed
        expect(bridge.failure_reason).to eq 'pipeline_loop_detected'
      end

      context 'when ci_drop_cyclical_triggered_pipelines is not enabled' do
        before do
          stub_feature_flags(ci_drop_cyclical_triggered_pipelines: false)
        end

        it 'creates a new pipeline' do
          expect { service.execute(bridge) }
            .to change { Ci::Pipeline.count }
        end

        it 'expect bridge build not to be failed' do
          service.execute(bridge)

          expect(bridge.reload).not_to be_failed
        end
      end
    end

    context 'when downstream pipeline creation errors out' do
      let(:stub_config) { false }

      before do
        stub_ci_pipeline_yaml_file(YAML.dump(invalid: { yaml: 'error' }))
      end

      it 'creates only one new pipeline' do
        expect { service.execute(bridge) }
          .to change { Ci::Pipeline.count }.by(1)
      end

      it 'creates a new pipeline in the downstream project' do
        pipeline = service.execute(bridge)

        expect(pipeline.user).to eq bridge.user
        expect(pipeline.project).to eq downstream_project
      end

      it 'drops the bridge' do
        pipeline = service.execute(bridge)

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

      it 'tracks the exception' do
        expect(Gitlab::ErrorTracking)
          .to receive(:track_exception)
          .with(
            instance_of(Ci::Bridge::InvalidTransitionError),
            bridge_id: bridge.id,
            downstream_pipeline_id: kind_of(Numeric))

        service.execute(bridge)
      end
    end

    context 'when bridge job has YAML variables defined' do
      before do
        bridge.yaml_variables = [{ key: 'BRIDGE', value: 'var', public: true }]
      end

      it 'passes bridge variables to downstream pipeline' do
        pipeline = service.execute(bridge)

        expect(pipeline.variables.first)
          .to have_attributes(key: 'BRIDGE', value: 'var')
      end
    end

    context 'when pipeline variables are defined' do
      before do
        upstream_pipeline.variables.create!(key: 'PIPELINE_VARIABLE', value: 'my-value')
      end

      it 'does not pass pipeline variables directly downstream' do
        pipeline = service.execute(bridge)

        pipeline.variables.map(&:key).tap do |variables|
          expect(variables).not_to include 'PIPELINE_VARIABLE'
        end
      end

      context 'when using YAML variables interpolation' do
        before do
          bridge.yaml_variables = [{ key: 'BRIDGE', value: '$PIPELINE_VARIABLE-var', public: true }]
        end

        it 'makes it possible to pass pipeline variable downstream' do
          pipeline = service.execute(bridge)

          pipeline.variables.find_by(key: 'BRIDGE').tap do |variable|
            expect(variable.value).to eq 'my-value-var'
          end
        end

        context 'when downstream project does not allow user-defined variables for multi-project pipelines' do
          before do
            downstream_project.update!(restrict_user_defined_variables: true)
          end

          it 'does not create a new pipeline' do
            expect { service.execute(bridge) }
              .not_to change { Ci::Pipeline.count }
          end

          it 'ignores variables passed downstream from the bridge' do
            pipeline = service.execute(bridge)

            pipeline.variables.map(&:key).tap do |variables|
              expect(variables).not_to include 'BRIDGE'
            end
          end

          it 'sets errors', :aggregate_failures do
            service.execute(bridge)

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
    context 'when configured with bridge job rules' do
      before do
        stub_ci_pipeline_yaml_file(config)
        downstream_project.add_maintainer(upstream_project.owner)
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
        Ci::CreatePipelineService.new(upstream_project, upstream_project.owner, { ref: 'master' })
          .execute(:push, save_on_errors: false)
          .payload
      end

      let(:bridge)  { primary_pipeline.processables.find_by(name: 'bridge-job') }
      let(:service) { described_class.new(upstream_project, upstream_project.owner) }

      context 'that include the bridge job' do
        it 'creates the downstream pipeline' do
          expect { service.execute(bridge) }
            .to change(downstream_project.ci_pipelines, :count).by(1)
        end
      end
    end

    context 'when user does not have access to push protected branch of downstream project' do
      before do
        create(:protected_branch, :maintainers_can_push,
               project: downstream_project, name: 'feature')
      end

      it 'changes status of the bridge build' do
        service.execute(bridge)

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
        expect { service.execute(bridge) }.not_to change(downstream_project.ci_pipelines, :count)

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
        expect { service.execute(bridge) }.not_to change(downstream_project.ci_pipelines, :count)

        expect(bridge.reload).to be_failed
        expect(bridge.failure_reason).to eq('downstream_pipeline_creation_failed')
        expect(bridge.options[:downstream_errors]).to eq(['No stages / jobs for this pipeline.'])
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
        expect { service.execute(bridge) }.to change(downstream_project.ci_pipelines, :count).by(1)

        expect(bridge.reload).to be_failed
        expect(bridge.failure_reason).to eq('downstream_pipeline_creation_failed')
        expect(bridge.options[:downstream_errors]).to eq(
          ['test job: chosen stage does not exist; available stages are .pre, build, test, deploy, .post']
        )
      end
    end

    context 'when downstream pipeline has workflow rule' do
      before do
        stub_ci_pipeline_yaml_file(config)
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
          expect { service.execute(bridge) }.to change(downstream_project.ci_pipelines, :count).by(1)

          expect(bridge.reload).to be_success
        end
      end

      context 'when not passing the required variable' do
        it 'does not create the pipeline' do
          expect { service.execute(bridge) }.not_to change(downstream_project.ci_pipelines, :count)
        end
      end
    end
  end
end
