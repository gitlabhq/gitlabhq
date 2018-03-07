require 'spec_helper'

describe Gitlab::Ci::Pipeline::Chain::Skip do
  set(:project) { create(:project) }
  set(:user) { create(:user) }
  set(:pipeline) { create(:ci_pipeline, project: project) }

  let(:command) do
    Gitlab::Ci::Pipeline::Chain::Command.new(
      project: project,
      current_user: user,
      ignore_skip_ci: false,
      save_incompleted: true)
  end

  let(:step) { described_class.new(pipeline, command) }

  context 'when pipeline has been skipped by a user' do
    before do
      allow(pipeline).to receive(:git_commit_message)
        .and_return('commit message [ci skip]')

      step.perform!
    end

    it 'should break the chain' do
      expect(step.break?).to be true
    end

    it 'skips the pipeline' do
      expect(pipeline.reload).to be_skipped
    end
  end

  context 'when pipeline has not been skipped' do
    before do
      step.perform!
    end

    it 'should not break the chain' do
      expect(step.break?).to be false
    end

    it 'should not skip a pipeline chain' do
      expect(pipeline.reload).not_to be_skipped
    end
  end

  context 'when [ci skip] should be ignored' do
    let(:command) do
      double('command', project: project,
                        current_user: user,
                        ignore_skip_ci: true)
    end

    it 'does not break the chain' do
      step.perform!

      expect(step.break?).to be false
    end
  end

  context 'when pipeline should be skipped but not persisted' do
    let(:command) do
      double('command', project: project,
                        current_user: user,
                        ignore_skip_ci: false,
                        save_incompleted: false)
    end

    before do
      allow(pipeline).to receive(:git_commit_message)
        .and_return('commit message [ci skip]')

      step.perform!
    end

    it 'breaks the chain' do
      expect(step.break?).to be true
    end

    it 'does not skip pipeline' do
      expect(pipeline.reload).not_to be_skipped
    end
  end
end
