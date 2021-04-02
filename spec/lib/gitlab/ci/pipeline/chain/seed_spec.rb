# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Chain::Seed do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user, developer_projects: [project]) }
  let(:seeds_block) { }

  let(:command) do
    Gitlab::Ci::Pipeline::Chain::Command.new(
      project: project,
      current_user: user,
      origin_ref: 'master',
      seeds_block: seeds_block)
  end

  let(:pipeline) { build(:ci_pipeline, project: project) }

  describe '#perform!' do
    before do
      stub_ci_pipeline_yaml_file(YAML.dump(config))
    end

    let(:config) do
      { rspec: { script: 'rake' } }
    end

    subject(:run_chain) do
      [
        Gitlab::Ci::Pipeline::Chain::Config::Content.new(pipeline, command),
        Gitlab::Ci::Pipeline::Chain::Config::Process.new(pipeline, command),
        Gitlab::Ci::Pipeline::Chain::EvaluateWorkflowRules.new(pipeline, command)
      ].map(&:perform!)

      described_class.new(pipeline, command).perform!
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

      context 'when the FF ci_workflow_rules_variables is disabled' do
        before do
          stub_feature_flags(ci_workflow_rules_variables: false)
        end

        it 'sends root variable' do
          run_chain

          expect(rspec_variables['VAR1']).to eq('var 1')
        end
      end
    end
  end
end
