# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'notify/pipeline_failed_email.text.erb', feature_category: :continuous_integration do
  context 'when pipeline has a name attribute' do
    before do
      build_stubbed(:ci_pipeline_metadata, pipeline: pipeline, name: "My Pipeline")
    end

    let(:title) { "Pipeline #{pipeline.name} has failed!" }
    let(:status) { :failed }

    it_behaves_like 'pipeline status changes email'
  end

  context 'when pipeline does not have a name attribute' do
    let(:title) { "Pipeline ##{pipeline.id} has failed!" }
    let(:status) { :failed }

    it_behaves_like 'pipeline status changes email'
  end
end
