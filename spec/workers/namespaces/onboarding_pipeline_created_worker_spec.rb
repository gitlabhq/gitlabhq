# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::OnboardingPipelineCreatedWorker, '#perform' do
  include AfterNextHelpers

  let_it_be(:ci_pipeline) { create(:ci_pipeline) }

  it 'records the event' do
    expect_next(OnboardingProgressService, ci_pipeline.project.namespace)
      .to receive(:execute).with(action: :pipeline_created).and_call_original

    expect do
      subject.perform(ci_pipeline.project.namespace_id)
    end.to change(NamespaceOnboardingAction, :count).by(1)
  end

  context "when a namespace doesn't exist" do
    it "does nothing" do
      expect_next(OnboardingProgressService, ci_pipeline.project.namespace).not_to receive(:execute)

      expect { subject.perform(nil) }.not_to change(NamespaceOnboardingAction, :count)
    end
  end
end
