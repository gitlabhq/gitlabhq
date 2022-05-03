# frozen_string_literal: true
require 'fast_spec_helper'
require_relative '../../../../scripts/lib/glfm/shared'

RSpec.describe Glfm::Shared do
  describe '#output' do
    # NOTE: The #output method is normally always mocked, to prevent output while the specs are
    # running. However, in order to provide code coverage for the method, we have to invoke
    # it at least once.
    it 'has code coverage' do
      clazz = Class.new do
        include Glfm::Shared
      end
      instance = clazz.new
      allow(instance).to receive(:puts)
      instance.output('')
    end
  end
end
