# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Chain::Pipeline::Process do
  let_it_be(:project) { build(:project) }
  let_it_be(:user) { build(:user) }
  let_it_be(:pipeline) { build(:ci_pipeline, project: project, id: 42) }

  let_it_be(:command) do
    Gitlab::Ci::Pipeline::Chain::Command.new(project: project, current_user: user)
  end

  let(:step) { described_class.new(pipeline, command) }

  describe '#perform!' do
    subject(:perform) { step.perform! }

    it 'schedules a job to process the pipeline' do
      expect(Ci::InitialPipelineProcessWorker)
        .to receive(:perform_async)
        .with(42)

      perform
    end
  end

  describe '#break?' do
    it { expect(step.break?).to be_falsey }
  end
end
