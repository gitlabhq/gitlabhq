# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Onboarding::PipelineCreatedWorker, '#perform', feature_category: :onboarding do
  let_it_be(:ci_pipeline) { create(:ci_pipeline) }

  it_behaves_like 'records an onboarding progress action', :pipeline_created do
    let(:namespace) { ci_pipeline.project.namespace }

    subject { described_class.new.perform(ci_pipeline.project.namespace_id) }
  end

  it_behaves_like 'does not record an onboarding progress action' do
    subject { described_class.new.perform(nil) }
  end
end
