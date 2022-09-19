# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe BulkImports::RetryPipelineError do
  describe '#retry_delay' do
    it 'returns retry_delay' do
      exception = described_class.new('Error!', 60)

      expect(exception.retry_delay).to eq(60)
    end
  end
end
