# frozen_string_literal: true

require 'spec_helper'
RSpec.describe Ci::Workloads::Workload, feature_category: :continuous_integration do
  subject(:workload) { described_class.new }

  describe '#job' do
    it 'needs to be implemented' do
      expect { workload.job }.to raise_error(RuntimeError, "not implemented")
    end
  end
end
