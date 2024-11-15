# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Partitions::SetupDefaultService, feature_category: :ci_scaling do
  let(:service) { described_class.new }

  before do
    FactoryBot.rewind_sequences
  end

  describe '.execute' do
    subject(:execute) { service.execute }

    context 'when current ci_partition exists' do
      let!(:current_partition) { create(:ci_partition, :current) }

      it 'does not set up default values for ci_partitions' do
        expect(service).not_to receive(:setup_default_partitions)

        execute
      end
    end

    context 'when default ci_partitions do not exist' do
      it 'creates the default partitions', :aggregate_failures do
        expect { execute }.to change { Ci::Partition.count }.by(3)
      end
    end

    context 'when default partitions exist with incorrect statuses' do
      let(:status_active) { Ci::Partition.statuses[:active] }
      let(:status_current) { Ci::Partition.statuses[:current] }

      before do
        create_list(:ci_partition, 3)
      end

      it 'returns success and update statuses for ci_partitions', :aggregate_failures do
        expect { execute }.not_to change { Ci::Partition.count }
        expect(Ci::Partition.first.status).to eq(status_current)
        expect(Ci::Partition.last(2).pluck(:status)).to contain_exactly(status_active, status_active)
      end
    end
  end
end
