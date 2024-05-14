# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Chain::SeedBlock do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user, developer_of: project) }
  let(:seeds_block) {}

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

    subject(:run_chain) do
      [
        Gitlab::Ci::Pipeline::Chain::Config::Content.new(pipeline, command),
        Gitlab::Ci::Pipeline::Chain::Config::Process.new(pipeline, command)
      ].map(&:perform!)

      described_class.new(pipeline, command).perform!
    end

    let(:config) do
      { rspec: { script: 'rake' } }
    end

    context 'when there is not seeds_block' do
      it 'does nothing' do
        expect { run_chain }.not_to raise_error
      end
    end

    context 'when there is seeds_block' do
      let(:seeds_block) do
        ->(pipeline) { pipeline.variables.build(key: 'VAR', value: '123') }
      end

      it 'executes the block' do
        run_chain

        expect(pipeline.variables.size).to eq(1)
      end
    end

    context 'when the seeds_block tries to save the pipelie' do
      let(:seeds_block) do
        ->(pipeline) { pipeline.save! }
      end

      it 'raises error' do
        expect { run_chain }.to raise_error('Pipeline cannot be persisted by `seeds_block`')
      end
    end
  end
end
