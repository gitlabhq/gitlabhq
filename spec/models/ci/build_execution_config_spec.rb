# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::BuildExecutionConfig, type: :model, feature_category: :pipeline_composition do
  let_it_be(:execution_config) { create(:ci_builds_execution_configs) }

  it { is_expected.to belong_to(:pipeline).class_name('Ci::Pipeline').inverse_of(:build_execution_configs) }
  it { is_expected.to belong_to(:project) }
  it { is_expected.to have_many(:builds).class_name('Ci::Build').inverse_of(:execution_config) }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:run_steps) }
  end

  describe 'run_steps' do
    it { is_expected.not_to allow_value("string").for(:run_steps) }
    it { is_expected.not_to allow_value(1.0).for(:run_steps) }
    it { is_expected.not_to allow_value(nil).for(:run_steps) }

    context 'with step keyword' do
      it 'allows valid step with step keyword' do
        is_expected.to allow_value(
          [
            {
              'name' => 'step1',
              'step' => 'echo',
              'inputs' => { 'message' => 'Hello, World!' }
            }
          ]
        ).for(:run_steps)
      end

      it 'allows step with string reference' do
        is_expected.to allow_value(
          [
            {
              'name' => 'step1',
              'step' => 'my-function'
            }
          ]
        ).for(:run_steps)
      end

      it 'allows step with git reference' do
        is_expected.to allow_value(
          [
            {
              'name' => 'step1',
              'step' => {
                'git' => {
                  'url' => 'https://gitlab.com/example/repo.git',
                  'rev' => 'main',
                  'file' => 'func.yml'
                }
              }
            }
          ]
        ).for(:run_steps)
      end

      it 'allows step with OCI reference' do
        is_expected.to allow_value(
          [
            {
              'name' => 'step1',
              'step' => {
                'oci' => {
                  'registry' => 'registry.gitlab.com',
                  'repository' => 'my_group/my_project/image',
                  'tag' => 'latest'
                }
              }
            }
          ]
        ).for(:run_steps)
      end
    end

    context 'with func keyword' do
      it 'allows valid step with func keyword' do
        is_expected.to allow_value(
          [
            {
              'name' => 'step1',
              'func' => 'my-function'
            }
          ]
        ).for(:run_steps)
      end

      it 'allows func with git reference' do
        is_expected.to allow_value(
          [
            {
              'name' => 'step1',
              'func' => {
                'git' => {
                  'url' => 'https://gitlab.com/example/repo.git',
                  'rev' => 'main'
                }
              }
            }
          ]
        ).for(:run_steps)
      end

      it 'allows func with OCI reference' do
        is_expected.to allow_value(
          [
            {
              'name' => 'step1',
              'func' => {
                'oci' => {
                  'registry' => 'registry.gitlab.com',
                  'repository' => 'my_group/my_project/image',
                  'tag' => '1.0'
                }
              }
            }
          ]
        ).for(:run_steps)
      end
    end

    context 'with script keyword' do
      it 'allows valid step with script' do
        is_expected.to allow_value(
          [
            {
              'name' => 'step1',
              'script' => 'echo "Hello, World!"'
            }
          ]
        ).for(:run_steps)
      end

      it 'allows step with script and env' do
        is_expected.to allow_value(
          [
            {
              'name' => 'step1',
              'script' => 'echo $MESSAGE',
              'env' => { 'MESSAGE' => 'Hello' }
            }
          ]
        ).for(:run_steps)
      end
    end

    context 'when step has both step and func keywords' do
      it 'rejects step with both step and func keywords' do
        is_expected.not_to allow_value(
          [
            {
              'name' => 'step1',
              'step' => 'function1',
              'func' => 'function2'
            }
          ]
        ).for(:run_steps)
      end
    end

    context 'when step is missing step, func, or script' do
      it 'rejects step without step, func, or script' do
        is_expected.not_to allow_value(
          [
            {
              'name' => 'step1'
            }
          ]
        ).for(:run_steps)
      end
    end

    context 'when step has both script and step keywords' do
      it 'rejects step with both script and step keywords' do
        is_expected.not_to allow_value(
          [
            {
              'name' => 'step1',
              'script' => 'echo test',
              'step' => 'function1'
            }
          ]
        ).for(:run_steps)
      end
    end

    context 'when step is missing name' do
      it 'rejects step without name' do
        is_expected.not_to allow_value(
          [
            {
              'script' => 'echo test'
            }
          ]
        ).for(:run_steps)
      end
    end
  end

  describe 'partitioning' do
    include Ci::PartitioningHelpers

    let(:pipeline) { create(:ci_pipeline) }
    let(:execution_config) { FactoryBot.build(:ci_builds_execution_configs, pipeline: pipeline) }

    before do
      stub_current_partition_id(ci_testing_partition_id)
    end

    it 'assigns partition id to execution config' do
      execution_config.save!

      expect(execution_config.partition_id).to eq(ci_testing_partition_id)
    end
  end
end
