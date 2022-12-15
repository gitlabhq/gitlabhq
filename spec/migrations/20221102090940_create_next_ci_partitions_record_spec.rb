# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CreateNextCiPartitionsRecord, migration: :gitlab_ci, feature_category: :continuous_integration do
  let(:migration) { described_class.new }
  let(:partitions) { table(:ci_partitions) }

  describe '#up' do
    context 'when on sass' do
      before do
        allow(Gitlab).to receive(:com?).and_return(true)
      end

      it 'creates next partitions record and resets the sequence' do
        expect { migrate! }
          .to change { partitions.where(id: 101).any? }
          .from(false).to(true)

        expect { partitions.create! }.not_to raise_error
      end
    end

    context 'when self-managed' do
      before do
        allow(Gitlab).to receive(:com?).and_return(false)
      end

      it 'does not create records' do
        expect { migrate! }.not_to change(partitions, :count)
      end
    end
  end

  describe '#down' do
    context 'when on sass' do
      before do
        allow(Gitlab).to receive(:com?).and_return(true)
      end

      it 'removes the record' do
        migrate!

        expect { migration.down }
          .to change { partitions.where(id: 101).any? }
          .from(true).to(false)
      end
    end

    context 'when self-managed' do
      before do
        allow(Gitlab).to receive(:com?).and_return(true, false)
      end

      it 'does not remove the record' do
        expect { migrate! }.to change(partitions, :count).by(1)

        expect { migration.down }.not_to change(partitions, :count)
      end
    end
  end
end
