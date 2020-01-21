# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_processing_service.rb'

describe Ci::PipelineProcessing::LegacyProcessingService do
  before do
    stub_feature_flags(ci_atomic_processing: false)
  end

  it_behaves_like 'Pipeline Processing Service'
end
