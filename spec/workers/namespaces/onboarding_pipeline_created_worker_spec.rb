# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::OnboardingPipelineCreatedWorker, '#perform' do
  include AfterNextHelpers

  let_it_be(:ci_pipeline) { create(:ci_pipeline) }

  before do
    OnboardingProgress.onboard(ci_pipeline.project.namespace)
  end

  it 'registers an onboarding progress action' do
    expect_next(OnboardingProgressService, ci_pipeline.project.namespace)
      .to receive(:execute).with(action: :pipeline_created).and_call_original

    subject.perform(ci_pipeline.project.namespace_id)

    expect(OnboardingProgress.completed?(ci_pipeline.project.namespace, :pipeline_created)).to eq(true)
  end

  context "when a namespace doesn't exist" do
    it 'does not register an onboarding progress action' do
      expect_next(OnboardingProgressService, ci_pipeline.project.namespace).not_to receive(:execute)

      subject.perform(nil)

      expect(OnboardingProgress.completed?(ci_pipeline.project.namespace, :pipeline_created)).to eq(false)
    end
  end
end
