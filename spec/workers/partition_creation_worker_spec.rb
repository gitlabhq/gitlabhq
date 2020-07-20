# frozen_string_literal: true

require "spec_helper"

RSpec.describe PartitionCreationWorker do
  describe '#perform' do
    let(:creator) { double(create_partitions: nil) }

    before do
      allow(Gitlab::Database::Partitioning::PartitionCreator).to receive(:new).and_return(creator)
    end

    it 'delegates to PartitionCreator' do
      expect(creator).to receive(:create_partitions)

      described_class.new.perform
    end
  end
end
