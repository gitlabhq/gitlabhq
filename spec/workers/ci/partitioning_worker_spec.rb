# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PartitioningWorker, feature_category: :continuous_integration do
  describe '#perform' do
    subject(:execute_worker) { described_class.new.perform }

    it 'calls setup default service' do
      expect(Ci::Partitions::SetupDefaultService).to receive_message_chain(:new, :execute)

      execute_worker
    end
  end
end
