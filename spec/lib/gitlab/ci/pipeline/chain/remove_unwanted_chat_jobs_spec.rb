# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Pipeline::Chain::RemoveUnwantedChatJobs do
  let(:project) { create(:project, :repository) }

  let(:pipeline) do
    build(:ci_pipeline, project: project)
  end

  let(:command) do
    double(:command, project: project, chat_data: { command: 'echo' })
  end

  before do
    stub_ci_pipeline_yaml_file(YAML.dump(rspec: { script: 'rspec' }))
  end

  describe '#perform!' do
    it 'removes unwanted jobs for chat pipelines' do
      allow(pipeline).to receive(:chat?).and_return(true)

      pipeline.config_processor.jobs[:echo] = double(:job)

      described_class.new(pipeline, command).perform!

      expect(pipeline.config_processor.jobs.keys).to eq([:echo])
    end
  end

  it 'does not remove any jobs for non-chat pipelines' do
    described_class.new(pipeline, command).perform!

    expect(pipeline.config_processor.jobs.keys).to eq([:rspec])
  end
end
