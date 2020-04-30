# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_processing_service.rb'
# require_relative 'shared_processing_service_tests_with_yaml.rb'

describe Ci::PipelineProcessing::AtomicProcessingService do
  before do
    stub_feature_flags(ci_atomic_processing: true)
  end

  it_behaves_like 'Pipeline Processing Service'
  # TODO: This needs to be enabled. There is a different behavior when using `needs` depending on
  # a `manual` job. More info: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/29405#note_327520605
  # it_behaves_like 'Pipeline Processing Service Tests With Yaml'

  private

  def process_pipeline(initial_process: false)
    described_class.new(pipeline).execute
  end
end
