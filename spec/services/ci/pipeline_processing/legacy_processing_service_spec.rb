# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_processing_service.rb'

describe Ci::PipelineProcessing::LegacyProcessingService do
  it_behaves_like 'Pipeline Processing Service'
end
