# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_processing_service.rb'
require_relative 'shared_processing_service_tests_with_yaml.rb'

describe Ci::PipelineProcessing::LegacyProcessingService do
  before do
    stub_feature_flags(ci_atomic_processing: false)
  end

  context 'when ci_composite_status is enabled' do
    before do
      stub_feature_flags(ci_composite_status: true)
    end

    it_behaves_like 'Pipeline Processing Service'
    it_behaves_like 'Pipeline Processing Service Tests With Yaml'
  end

  context 'when ci_composite_status is disabled' do
    before do
      stub_feature_flags(ci_composite_status: false)
    end

    it_behaves_like 'Pipeline Processing Service'
    it_behaves_like 'Pipeline Processing Service Tests With Yaml'
  end

  private

  def process_pipeline(initial_process: false)
    described_class.new(pipeline).execute(initial_process: initial_process)
  end
end
