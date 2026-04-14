# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Chain::NoPipeline, feature_category: :pipeline_composition do
  let_it_be(:project)  { create(:project) }
  let_it_be(:user)     { create(:user) }
  let(:pipeline) { build(:ci_pipeline, project: project) }
  let(:push_options) do
    Ci::PipelineCreation::PushOptions.new({})
  end

  let(:command) do
    Gitlab::Ci::Pipeline::Chain::Command.new(
      project: project,
      current_user: user,
      push_options: push_options,
      origin_ref: project.default_branch_or_main)
  end

  let(:step) { described_class.new(pipeline, command) }

  context 'when feature flag ci_no_pipeline_push_option is enabled' do
    context 'when pipeline has been skipped by push with ci.no_pipeline option' do
      let(:push_options) do
        Ci::PipelineCreation::PushOptions.new({ 'ci' => { 'no_pipeline' => true } })
      end

      before do
        step.perform!
      end

      it 'does not save the pipeline' do
        expect(pipeline).not_to be_persisted
      end

      it 'breaks the chain' do
        expect(step.break?).to be true
      end

      it 'pipeline is failed' do
        expect(pipeline).to be_failed
      end
    end

    context 'when pipeline has not been skipped by push with option' do
      before do
        step.perform!
      end

      it 'does not skip the pipeline' do
        expect(pipeline).not_to be_persisted
        expect(pipeline).not_to be_skipped
      end
    end
  end

  context 'when feature flag ci_no_pipeline_push_option is disabled' do
    before do
      stub_feature_flags(ci_no_pipeline_push_option: false)
    end

    context 'when commit is pushed with ci.no_pipeline option' do
      before do
        allow(command).to receive(:push_options).and_return({ 'ci' => { 'no_pipeline' => true } })
        step.perform!
      end

      it 'breaks the chain' do
        expect(step.break?).to be false
      end

      it 'does not skip the pipeline' do
        expect(pipeline).not_to be_persisted
        expect(pipeline).not_to be_skipped
      end
    end

    context 'when pipeline has not been skipped by push with option' do
      before do
        allow(command).to receive(:push_options).and_return({})
        step.perform!
      end

      it 'does not skip the pipeline' do
        expect(pipeline).not_to be_persisted
        expect(pipeline).not_to be_skipped
      end
    end
  end
end
