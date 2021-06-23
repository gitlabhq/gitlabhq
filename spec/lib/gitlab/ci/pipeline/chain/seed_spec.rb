# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Chain::Seed do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user, developer_projects: [project]) }

  let(:seeds_block) { }
  let(:command) { initialize_command }
  let(:pipeline) { build(:ci_pipeline, project: project) }

  describe '#perform!' do
    before do
      stub_ci_pipeline_yaml_file(YAML.dump(config))
    end

    let(:config) do
      { rspec: { script: 'rake' } }
    end

    subject(:run_chain) do
      run_previous_chain(pipeline, command)
      perform_seed(pipeline, command)
    end

    it 'allocates next IID' do
      run_chain

      expect(pipeline.iid).to be_present
    end

    it 'ensures ci_ref' do
      run_chain

      expect(pipeline.ci_ref).to be_present
    end

    it 'sets the seeds in the command object' do
      run_chain

      expect(command.pipeline_seed).to be_a(Gitlab::Ci::Pipeline::Seed::Pipeline)
      expect(command.pipeline_seed.size).to eq 1
    end

    context 'when no ref policy is specified' do
      let(:config) do
        {
          production: { stage: 'deploy', script: 'cap prod' },
          rspec: { stage: 'test', script: 'rspec' },
          spinach: { stage: 'test', script: 'spinach' }
        }
      end

      it 'correctly fabricates stages and builds' do
        run_chain

        seed = command.pipeline_seed

        expect(seed.stages.size).to eq 2
        expect(seed.size).to eq 3
        expect(seed.stages.first.name).to eq 'test'
        expect(seed.stages.second.name).to eq 'deploy'
        expect(seed.stages[0].statuses[0].name).to eq 'rspec'
        expect(seed.stages[0].statuses[1].name).to eq 'spinach'
        expect(seed.stages[1].statuses[0].name).to eq 'production'
      end
    end

    context 'when refs policy is specified' do
      let(:pipeline) do
        build(:ci_pipeline, project: project, ref: 'feature', tag: true)
      end

      let(:config) do
        {
          production: { stage: 'deploy', script: 'cap prod', only: ['master'] },
          spinach: { stage: 'test', script: 'spinach', only: ['tags'] }
        }
      end

      it 'returns pipeline seed with jobs only assigned to master' do
        run_chain

        seed = command.pipeline_seed

        expect(seed.size).to eq 1
        expect(seed.stages.first.name).to eq 'test'
        expect(seed.stages[0].statuses[0].name).to eq 'spinach'
      end
    end

    context 'when source policy is specified' do
      let(:pipeline) { create(:ci_pipeline, source: :schedule) }

      let(:config) do
        {
          production: { stage: 'deploy', script: 'cap prod', only: ['triggers'] },
          spinach: { stage: 'test', script: 'spinach', only: ['schedules'] }
        }
      end

      it 'returns pipeline seed with jobs only assigned to schedules' do
        run_chain

        seed = command.pipeline_seed

        expect(seed.size).to eq 1
        expect(seed.stages.first.name).to eq 'test'
        expect(seed.stages[0].statuses[0].name).to eq 'spinach'
      end
    end

    context 'when kubernetes policy is specified' do
      let(:config) do
        {
          spinach: { stage: 'test', script: 'spinach' },
          production: {
            stage: 'deploy',
            script: 'cap',
            only: { kubernetes: 'active' }
          }
        }
      end

      context 'when kubernetes is active' do
        context 'when user configured kubernetes from CI/CD > Clusters' do
          let!(:cluster) { create(:cluster, :project, :provided_by_gcp) }
          let(:project) { cluster.project }
          let(:pipeline) { build(:ci_pipeline, project: project) }

          it 'returns seeds for kubernetes dependent job' do
            run_chain

            seed = command.pipeline_seed

            expect(seed.size).to eq 2
            expect(seed.stages[0].statuses[0].name).to eq 'spinach'
            expect(seed.stages[1].statuses[0].name).to eq 'production'
          end
        end
      end

      context 'when kubernetes is not active' do
        it 'does not return seeds for kubernetes dependent job' do
          run_chain

          seed = command.pipeline_seed

          expect(seed.size).to eq 1
          expect(seed.stages[0].statuses[0].name).to eq 'spinach'
        end
      end
    end

    context 'when variables policy is specified' do
      let(:config) do
        {
          unit: { script: 'minitest', only: { variables: ['$CI_PIPELINE_SOURCE'] } },
          feature: { script: 'spinach', only: { variables: ['$UNDEFINED'] } }
        }
      end

      it 'returns stage seeds only when variables expression is truthy' do
        run_chain

        seed = command.pipeline_seed

        expect(seed.size).to eq 1
        expect(seed.stages[0].statuses[0].name).to eq 'unit'
      end
    end

    context 'when there is seeds_block' do
      let(:seeds_block) do
        ->(pipeline) { pipeline.variables.build(key: 'VAR', value: '123') }
      end

      it 'does not execute the block' do
        run_chain

        expect(pipeline.variables.size).to eq(0)
      end
    end

    describe '#root_variables' do
      let(:config) do
        {
          variables: { VAR1: 'var 1' },
          workflow: {
            rules: [{ if: '$CI_PIPELINE_SOURCE',
                      variables: { VAR1: 'overridden var 1' } },
                    { when: 'always' }]
          },
          rspec: { script: 'rake' }
        }
      end

      let(:rspec_variables) { command.pipeline_seed.stages[0].statuses[0].variables.to_hash }

      it 'sends root variable with overridden by rules' do
        run_chain

        expect(rspec_variables['VAR1']).to eq('overridden var 1')
      end
    end

    context 'N+1 queries' do
      it 'avoids N+1 queries when calculating variables of jobs', :use_sql_query_cache do
        warm_up_pipeline, warm_up_command = prepare_pipeline1
        perform_seed(warm_up_pipeline, warm_up_command)

        pipeline1, command1 = prepare_pipeline1
        pipeline2, command2 = prepare_pipeline2

        control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
          perform_seed(pipeline1, command1)
        end

        expect { perform_seed(pipeline2, command2) }.not_to exceed_all_query_limit(
          control.count + expected_extra_queries
        )
      end

      private

      def prepare_pipeline1
        config1 = { build: { stage: 'build', script: 'build' } }
        stub_ci_pipeline_yaml_file(YAML.dump(config1))
        pipeline1 = build(:ci_pipeline, project: project)
        command1 = initialize_command

        run_previous_chain(pipeline1, command1)

        [pipeline1, command1]
      end

      def prepare_pipeline2
        config2 = { build1: { stage: 'build', script: 'build1' },
                    build2: { stage: 'build', script: 'build2' },
                    test: { stage: 'build', script: 'test' } }
        stub_ci_pipeline_yaml_file(YAML.dump(config2))
        pipeline2 = build(:ci_pipeline, project: project)
        command2 = initialize_command

        run_previous_chain(pipeline2, command2)

        [pipeline2, command2]
      end

      def expected_extra_queries
        extra_jobs = 2
        non_handled_sql_queries = 2

        # 1. Ci::InstanceVariable Load => `Ci::InstanceVariable#cached_data` => already cached with `fetch_memory_cache`
        # 2. Ci::Variable Load => `Project#ci_variables_for` => already cached with `Gitlab::SafeRequestStore`

        extra_jobs * non_handled_sql_queries
      end
    end

    private

    def run_previous_chain(pipeline, command)
      [
        Gitlab::Ci::Pipeline::Chain::Config::Content.new(pipeline, command),
        Gitlab::Ci::Pipeline::Chain::Config::Process.new(pipeline, command),
        Gitlab::Ci::Pipeline::Chain::EvaluateWorkflowRules.new(pipeline, command)
      ].map(&:perform!)
    end

    def perform_seed(pipeline, command)
      described_class.new(pipeline, command).perform!
    end
  end

  private

  def initialize_command
    Gitlab::Ci::Pipeline::Chain::Command.new(
      project: project,
      current_user: user,
      origin_ref: 'master',
      seeds_block: seeds_block
    )
  end
end
