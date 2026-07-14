# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Partitions::CreateService, feature_category: :ci_scaling do
  let(:service) { described_class.new(ci_partition) }

  describe '.execute' do
    subject(:execute_service) { service.execute }

    shared_examples 'ci_partition not created' do
      it 'does not create the next ci_partition', :aggregate_failures do
        expect(Ci::Partition).not_to receive(:create_next!)

        expect { execute_service }.not_to change { Ci::Partition.count }
      end
    end

    context 'when the current partition has default headroom' do
      let_it_be_with_refind(:ci_partition) { create(:ci_partition, :current, id: 200) }

      it 'creates the next ci_partition' do
        expect { execute_service }.to change { Ci::Partition.count }.by(1)
      end

      context 'when no more headroom available' do
        before do
          create(:ci_partition, id: 201)
        end

        it_behaves_like 'ci_partition not created'
      end

      context 'when headroom creation is disabled' do
        before do
          stub_const("#{described_class}::HEADROOM_PARTITIONS", 0)
        end

        it_behaves_like 'ci_partition not created'
      end

      context 'when headroom is increased' do
        before do
          stub_const("#{described_class}::HEADROOM_PARTITIONS", described_class::HEADROOM_PARTITIONS + 1)
          create(:ci_partition, id: 201)
        end

        it 'creates the next ci_partition' do
          expect { execute_service }.to change { Ci::Partition.count }.by(1)
        end
      end
    end

    context 'when ci_partition is nil' do
      let(:ci_partition) { nil }

      it_behaves_like 'ci_partition not created'
    end

    context 'when the current partition is a static default partition' do
      let(:service) { described_class.new(Ci::Partition.find(current_id)) }

      where(:current_id) { Ci::Partition::DEFAULT_PARTITION_VALUES }

      with_them do
        before do
          Ci::Partition::DEFAULT_PARTITION_VALUES.each do |id|
            trait = id == current_id ? :current : :active
            create(:ci_partition, trait, id: id)
          end
        end

        it 'creates a partition past the last static one' do
          expect { execute_service }
            .to change { Ci::Partition.where('id > ?', Ci::Partition::LAST_STATIC_PARTITION_VALUE).count }
            .by(1)
        end

        context 'when a partition past the last static one already exists' do
          before do
            create(:ci_partition, :ready, id: 103)
          end

          it_behaves_like 'ci_partition not created'
        end
      end
    end
  end
end
