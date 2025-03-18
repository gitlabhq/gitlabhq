# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Import::ImportFileCleanupWorker, feature_category: :importers do
  subject(:worker) { described_class.new }

  describe '#perform' do
    it_behaves_like 'an idempotent worker'

    it 'executes Import::ImportFileCleanupService' do
      expect_next_instance_of(Import::ImportFileCleanupService) do |service|
        expect(service).to receive(:execute)
      end

      worker.perform
    end
  end
end
