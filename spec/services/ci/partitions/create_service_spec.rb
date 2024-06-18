# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Partitions::CreateService, feature_category: :ci_scaling do
  let_it_be(:ci_partition) { create(:ci_partition, :current) }
  let(:service) { described_class.new(ci_partition) }

  describe '.execute' do
    subject(:execute_service) { service.execute }

    shared_examples 'ci_partition not created' do
      it 'does not create the next ci_partition', :aggregate_failures do
        expect(Ci::Partition).not_to receive(:create_next!)

        expect { execute_service }.not_to change { Ci::Partition.count }
      end
    end

    context 'when ci_partitioning_automation is disabled' do
      before do
        stub_feature_flags(ci_partitioning_automation: false)
      end

      it_behaves_like 'ci_partition not created'
    end

    context 'when ci_partition is nil' do
      let(:ci_partition) { nil }

      it_behaves_like 'ci_partition not created'
    end

    context 'when all conditions are satistied' do
      before do
        allow(service).to receive(:should_create_next?).and_return(true)
      end

      it 'creates the next ci_partition' do
        expect { execute_service }.to change { Ci::Partition.count }.by(1)
      end
    end

    context 'when database_partition sizes are not above the threshold' do
      it_behaves_like 'ci_partition not created'
    end

    context 'when database_partition sizes are above the threshold' do
      before do
        stub_const("Ci::Partition::MAX_PARTITION_SIZE", 1.byte)
      end

      context 'when no more headroom available' do
        before do
          stub_const("#{described_class}::HEADROOM_PARTITIONS", 1)
          create(:ci_partition)
        end

        it_behaves_like 'ci_partition not created'
      end
    end
  end
end
