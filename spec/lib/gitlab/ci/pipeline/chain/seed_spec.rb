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
        Gitlab::Ci::Pipeline::Chain::Config::Process.new(pipeline, command)
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

      expect(command.stage_seeds).to all(be_a Gitlab::Ci::Pipeline::Seed::Base)
      expect(command.stage_seeds.count).to eq 1
    end

    context 'when no ref policy is specified' do
      let(:config) do
        {
          production: { stage: 'deploy', script: 'cap prod' },
          rspec: { stage: 'test', script: 'rspec' },
          spinach: { stage: 'test', script: 'spinach' }
        }
      end

      it 'correctly fabricates a stage seeds object' do
        run_chain

        seeds = command.stage_seeds
        expect(seeds.size).to eq 2
        expect(seeds.first.attributes[:name]).to eq 'test'
        expect(seeds.second.attributes[:name]).to eq 'deploy'
        expect(seeds.dig(0, 0, :name)).to eq 'rspec'
        expect(seeds.dig(0, 1, :name)).to eq 'spinach'
        expect(seeds.dig(1, 0, :name)).to eq 'production'
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

      it 'returns stage seeds only assigned to master' do
        run_chain

        seeds = command.stage_seeds

        expect(seeds.size).to eq 1
        expect(seeds.first.attributes[:name]).to eq 'test'
        expect(seeds.dig(0, 0, :name)).to eq 'spinach'
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

      it 'returns stage seeds only assigned to schedules' do
        run_chain

        seeds = command.stage_seeds

        expect(seeds.size).to eq 1
        expect(seeds.first.attributes[:name]).to eq 'test'
        expect(seeds.dig(0, 0, :name)).to eq 'spinach'
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

            seeds = command.stage_seeds

            expect(seeds.size).to eq 2
            expect(seeds.dig(0, 0, :name)).to eq 'spinach'
            expect(seeds.dig(1, 0, :name)).to eq 'production'
          end
        end
      end

      context 'when kubernetes is not active' do
        it 'does not return seeds for kubernetes dependent job' do
          run_chain

          seeds = command.stage_seeds

          expect(seeds.size).to eq 1
          expect(seeds.dig(0, 0, :name)).to eq 'spinach'
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

        seeds = command.stage_seeds

        expect(seeds.size).to eq 1
        expect(seeds.dig(0, 0, :name)).to eq 'unit'
      end
    end

    context 'when there is seeds_block' do
      let(:seeds_block) do
        ->(pipeline) { pipeline.variables.build(key: 'VAR', value: '123') }
      end

      context 'when FF ci_seed_block_run_before_workflow_rules is enabled' do
        it 'does not execute the block' do
          run_chain

          expect(pipeline.variables.size).to eq(0)
        end
      end

      context 'when FF ci_seed_block_run_before_workflow_rules is disabled' do
        before do
          stub_feature_flags(ci_seed_block_run_before_workflow_rules: false)
        end

        it 'executes the block' do
          run_chain

          expect(pipeline.variables.size).to eq(1)
        end
      end
    end
  end
end
