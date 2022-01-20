# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BaseJob, '#perform' do
  let(:connection) { double(:connection) }

  let(:test_job_class) { Class.new(described_class) }
  let(:test_job) { test_job_class.new(connection: connection) }

  describe '#perform' do
    it 'raises an error if not overridden by a subclass' do
      expect { test_job.perform }.to raise_error(NotImplementedError, /must implement perform/)
    end
  end
end
