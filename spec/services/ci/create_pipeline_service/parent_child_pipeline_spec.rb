# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CreatePipelineService, '#execute' do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let(:ref_name) { 'master' }

  let(:service) do
    params = { ref: ref_name,
               before: '00000000',
               after: project.commit.id,
               commits: [{ message: 'some commit' }] }

    described_class.new(project, user, params)
  end

  before do
    project.add_developer(user)
    stub_ci_pipeline_yaml_file(config)
  end

  shared_examples 'successful creation' do
    it 'creates bridge jobs correctly', :aggregate_failures do
      pipeline = create_pipeline!

      test = pipeline.statuses.find_by(name: 'test')
      bridge = pipeline.statuses.find_by(name: 'deploy')

      expect(pipeline).to be_persisted
      expect(test).to be_a Ci::Build
      expect(bridge).to be_a Ci::Bridge
      expect(bridge.stage).to eq 'deploy'
      expect(pipeline.statuses).to match_array [test, bridge]
      expect(bridge.options).to eq(expected_bridge_options)
      expect(bridge.yaml_variables)
        .to include(key: 'CROSS', value: 'downstream', public: true)
    end
  end

  shared_examples 'creation failure' do
    it 'returns errors' do
      pipeline = create_pipeline!

      expect(pipeline.errors.full_messages.first).to match(expected_error)
      expect(pipeline.failure_reason).to eq 'config_error'
      expect(pipeline).to be_persisted
      expect(pipeline.status).to eq 'failed'
    end
  end

  describe 'child pipeline triggers' do
    let(:config) do
      <<~YAML
      test:
        script: rspec
      deploy:
        variables:
          CROSS: downstream
        stage: deploy
        trigger:
          include:
            - local: path/to/child.yml
      YAML
    end

    it_behaves_like 'successful creation' do
      let(:expected_bridge_options) do
        {
          trigger: {
            include: [
              { local: 'path/to/child.yml' }
            ]
          }
        }
      end
    end

    context 'with resource group' do
      let(:config) do
        <<~YAML
        instrumentation_test:
          stage: test
          resource_group: iOS
          trigger:
            include: path/to/child.yml
            strategy: depend
        YAML
      end

      it 'creates bridge job with resource group', :aggregate_failures do
        pipeline = create_pipeline!
        Ci::InitialPipelineProcessWorker.new.perform(pipeline.id)

        test = pipeline.statuses.find_by(name: 'instrumentation_test')
        expect(pipeline).to be_created_successfully
        expect(pipeline.triggered_pipelines).not_to be_exist
        expect(project.resource_groups.count).to eq(1)
        expect(test).to be_a Ci::Bridge
        expect(test).to be_waiting_for_resource
        expect(test.resource_group.key).to eq('iOS')
      end

      context 'when sidekiq processes the job', :sidekiq_inline do
        it 'transitions to pending status and triggers a downstream pipeline' do
          pipeline = create_pipeline!

          test = pipeline.statuses.find_by(name: 'instrumentation_test')
          expect(test).to be_pending
          expect(pipeline.triggered_pipelines.count).to eq(1)
        end

        context 'when the resource is occupied by the other bridge' do
          before do
            resource_group = create(:ci_resource_group, project: project, key: 'iOS')
            resource_group.assign_resource_to(create(:ci_build, project: project))
          end

          it 'stays waiting for resource' do
            pipeline = create_pipeline!

            test = pipeline.statuses.find_by(name: 'instrumentation_test')
            expect(test).to be_waiting_for_resource
            expect(pipeline.triggered_pipelines.count).to eq(0)
          end
        end
      end
    end
  end

  describe 'child pipeline triggers' do
    context 'when YAML is valid' do
      let(:config) do
        <<~YAML
        test:
          script: rspec
        deploy:
          variables:
            CROSS: downstream
          stage: deploy
          trigger:
            include:
              - local: path/to/child.yml
        YAML
      end

      it_behaves_like 'successful creation' do
        let(:expected_bridge_options) do
          {
            trigger: {
              include: [
                { local: 'path/to/child.yml' }
              ]
            }
          }
        end
      end

      context 'when trigger:include is specified as a string' do
        let(:config) do
          <<~YAML
          test:
            script: rspec
          deploy:
            variables:
              CROSS: downstream
            stage: deploy
            trigger:
              include: path/to/child.yml
          YAML
        end

        it_behaves_like 'successful creation' do
          let(:expected_bridge_options) do
            {
              trigger: {
                include: 'path/to/child.yml'
              }
            }
          end
        end
      end

      context 'when trigger:include is specified as array of strings' do
        let(:config) do
          <<~YAML
          test:
            script: rspec
          deploy:
            variables:
              CROSS: downstream
            stage: deploy
            trigger:
              include:
                - path/to/child.yml
                - path/to/child2.yml
          YAML
        end

        it_behaves_like 'successful creation' do
          let(:expected_bridge_options) do
            {
              trigger: {
                include: ['path/to/child.yml', 'path/to/child2.yml']
              }
            }
          end
        end
      end
    end

    context 'when limit of includes is reached' do
      let(:config) do
        YAML.dump({
          test: { script: 'rspec' },
          deploy: {
            trigger: { include: included_files }
          }
        })
      end

      let(:included_files) do
        Array.new(include_max_size + 1) do |index|
          { local: "file#{index}.yml" }
        end
      end

      let(:include_max_size) do
        Gitlab::Ci::Config::Entry::Trigger::ComplexTrigger::SameProjectTrigger::INCLUDE_MAX_SIZE
      end

      it_behaves_like 'creation failure' do
        let(:expected_error) { /trigger:include config is too long/ }
      end
    end

    context 'when including configs from artifact' do
      context 'when specified dependency is in the wrong order' do
        let(:config) do
          <<~YAML
          test:
            trigger:
              include:
                - job: generator
                  artifact: 'generated.yml'
          generator:
            stage: 'deploy'
            script: 'generator'
          YAML
        end

        it_behaves_like 'creation failure' do
          let(:expected_error) { /test job: dependency generator is not defined in prior stages/ }
        end
      end

      context 'when specified dependency is missing :job key' do
        let(:config) do
          <<~YAML
          test:
            trigger:
              include:
                - artifact: 'generated.yml'
          YAML
        end

        it_behaves_like 'creation failure' do
          let(:expected_error) do
            /include config must specify the job where to fetch the artifact from/
          end
        end
      end
    end

    context 'when including configs from a project' do
      context 'when specifying all attributes' do
        let(:config) do
          <<~YAML
          test:
            script: rspec
          deploy:
            variables:
              CROSS: downstream
            stage: deploy
            trigger:
              include:
                - project: my-namespace/my-project
                  file: 'path/to/child.yml'
                  ref: 'master'
          YAML
        end

        it_behaves_like 'successful creation' do
          let(:expected_bridge_options) do
            {
              trigger: {
                include: [
                  {
                    file: 'path/to/child.yml',
                    project: 'my-namespace/my-project',
                    ref: 'master'
                  }
                ]
              }
            }
          end
        end
      end

      context 'without specifying file' do
        let(:config) do
          <<~YAML
          test:
            script: rspec
          deploy:
            variables:
              CROSS: downstream
            stage: deploy
            trigger:
              include:
                - project: my-namespace/my-project
                  ref: 'master'
          YAML
        end

        it_behaves_like 'creation failure' do
          let(:expected_error) do
            /include config must specify the file where to fetch the config from/
          end
        end
      end

      context 'when specifying multiple files' do
        let(:config) do
          <<~YAML
          test:
            script: rspec
          deploy:
            variables:
              CROSS: downstream
            stage: deploy
            trigger:
              include:
                - project: my-namespace/my-project
                  file:
                    - 'path/to/child1.yml'
                    - 'path/to/child2.yml'
          YAML
        end

        it_behaves_like 'successful creation' do
          let(:expected_bridge_options) do
            {
              trigger: {
                include: [
                  {
                    file: ["path/to/child1.yml", "path/to/child2.yml"],
                    project: 'my-namespace/my-project'
                  }
                ]
              }
            }
          end
        end
      end
    end
  end

  def create_pipeline!
    service.execute(:push)
  end
end
