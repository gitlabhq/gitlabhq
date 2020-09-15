# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::DuplicateJobs::Strategies::None do
  let(:fake_duplicate_job) do
    instance_double(Gitlab::SidekiqMiddleware::DuplicateJobs::DuplicateJob)
  end

  subject(:strategy) { described_class.new(fake_duplicate_job) }

  describe '#schedule' do
    it 'yields without checking for duplicates', :aggregate_failures do
      expect(fake_duplicate_job).not_to receive(:scheduled?)
      expect(fake_duplicate_job).not_to receive(:duplicate?)
      expect(fake_duplicate_job).not_to receive(:check!)

      expect { |b| strategy.schedule({}, &b) }.to yield_control
    end
  end

  describe '#perform' do
    it 'does not delete any locks before executing', :aggregate_failures do
      expect(fake_duplicate_job).not_to receive(:delete!)

      expect { |b| strategy.perform({}, &b) }.to yield_control
    end
  end
end
