# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_processing_service'
require_relative 'shared_processing_service_tests_with_yaml'

RSpec.describe Ci::PipelineProcessing::AtomicProcessingService do
  it_behaves_like 'Pipeline Processing Service'
  it_behaves_like 'Pipeline Processing Service Tests With Yaml'

  private

  def process_pipeline
    described_class.new(pipeline).execute
  end
end
