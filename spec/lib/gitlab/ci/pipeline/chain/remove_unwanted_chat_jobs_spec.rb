# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Ci::Pipeline::Chain::RemoveUnwantedChatJobs do
  let(:project) { create(:project) }

  let(:pipeline) do
    build(:ci_pipeline, project: project)
  end

  let(:command) do
    double(:command,
      yaml_processor_result: double(:processor,
        jobs: { echo: double(:job_echo), rspec: double(:job_rspec) }),
      project: project,
      chat_data: { command: 'echo' })
  end

  describe '#perform!' do
    subject { described_class.new(pipeline, command).perform! }

    it 'removes unwanted jobs for chat pipelines' do
      expect(pipeline).to receive(:chat?).and_return(true)

      subject

      expect(command.yaml_processor_result.jobs.keys).to eq([:echo])
    end

    it 'does not remove any jobs for non chat-pipelines' do
      expect(pipeline).to receive(:chat?).and_return(false)

      subject

      expect(command.yaml_processor_result.jobs.keys).to eq([:echo, :rspec])
    end
  end
end
