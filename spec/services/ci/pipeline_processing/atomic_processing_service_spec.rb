# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_processing_service.rb'
require_relative 'shared_processing_service_tests_with_yaml.rb'

describe Ci::PipelineProcessing::AtomicProcessingService do
  before do
    stub_feature_flags(ci_atomic_processing: true)

    # This feature flag is implicit
    # Atomic Processing does not process statuses differently
    stub_feature_flags(ci_composite_status: true)
  end

  it_behaves_like 'Pipeline Processing Service'
  it_behaves_like 'Pipeline Processing Service Tests With Yaml'

  private

  def process_pipeline(initial_process: false)
    described_class.new(pipeline).execute
  end
end
