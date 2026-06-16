# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Chain::Skip, feature_category: :pipeline_composition do
  let_it_be_with_reload(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:pipeline) { create(:ci_pipeline, project: project) }

  let(:command) do
    Gitlab::Ci::Pipeline::Chain::Command.new(
      project: project,
      current_user: user,
      ignore_skip_ci: false,
      save_incompleted: true,
      origin_ref: project.default_branch_or_main
    )
  end

  let(:step) { described_class.new(pipeline, command) }

  context 'when pipeline has been skipped by a user' do
    before do
      allow(pipeline).to receive(:git_commit_message)
        .and_return('commit message [ci skip]')
    end

    it 'breaks the chain' do
      step.perform!

      expect(step.break?).to be true
    end

    it 'skips the pipeline' do
      step.perform!

      expect(pipeline.reload).to be_skipped
    end

    it 'calls ensure_project_iid explicitly' do
      expect(pipeline).to receive(:ensure_project_iid!)

      step.perform!
    end

    context 'when pipeline is readonly' do
      before do
        pipeline.readonly!
      end

      it 'breaks the chain' do
        step.perform!

        expect(step.break?).to be true

        expect(pipeline).not_to receive(:skip)
        expect(pipeline).not_to receive(:ensure_project_iid!)
      end

      it 'does not raise error' do
        expect { step.perform! }.not_to raise_error
      end
    end
  end

  context 'when pipeline has not been skipped' do
    before do
      step.perform!
    end

    it 'does not break the chain' do
      expect(step.break?).to be false
    end

    it 'does not skip a pipeline chain' do
      expect(pipeline.reload).not_to be_skipped
    end
  end

  context 'when [ci skip] should be ignored' do
    let(:command) do
      Gitlab::Ci::Pipeline::Chain::Command.new(
        project: project,
        current_user: user,
        ignore_skip_ci: true,
        save_incompleted: true,
        origin_ref: project.default_branch_or_main
      )
    end

    it 'does not break the chain' do
      step.perform!

      expect(step.break?).to be false
    end
  end

  context 'when pipeline should be skipped but not persisted' do
    let(:command) do
      Gitlab::Ci::Pipeline::Chain::Command.new(
        project: project,
        current_user: user,
        ignore_skip_ci: false,
        save_incompleted: false,
        origin_ref: project.default_branch_or_main
      )
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

  context 'when skipping a project without CI config' do
    before do
      allow(pipeline).to receive(:git_commit_message)
        .and_return('commit message [ci skip]')
    end

    context 'when config does not exist' do
      before do
        allow_next_instance_of(Gitlab::Ci::ProjectConfig) do |instance|
          allow(instance).to receive(:exists?).and_return(false)
        end
      end

      it 'breaks the chain without skipping pipeline' do
        step.perform!

        expect(step.break?).to be true
        expect(pipeline).not_to be_skipped
      end
    end

    context 'when config exists' do
      before do
        allow_next_instance_of(Gitlab::Ci::ProjectConfig) do |instance|
          allow(instance).to receive(:exists?).and_return(true)
        end
      end

      it 'proceeds with normal skip behavior' do
        step.perform!

        expect(step.break?).to be true
        expect(pipeline.errors).to be_empty
      end
    end
  end
end
