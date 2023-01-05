# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Reindexing::ReindexAction, feature_category: :database do
  include Database::DatabaseHelpers

  let(:index) { create(:postgres_index) }

  before_all do
    swapout_view_for_table(:postgres_indexes, connection: ApplicationRecord.connection)
  end

  it { is_expected.to be_a Gitlab::Database::SharedModel }

  describe '.create_for' do
    subject { described_class.create_for(index) }

    it 'creates a new record for the given index' do
      freeze_time do
        record = subject

        expect(record.index_identifier).to eq(index.identifier)
        expect(record.action_start).to eq(Time.zone.now)
        expect(record.ondisk_size_bytes_start).to eq(index.ondisk_size_bytes)
        expect(subject.bloat_estimate_bytes_start).to eq(index.bloat_size)

        expect(record).to be_persisted
      end
    end
  end

  describe '#finish' do
    subject { action.finish }

    let(:action) { build(:reindex_action, index: index) }

    it 'sets #action_end' do
      freeze_time do
        subject

        expect(action.action_end).to eq(Time.zone.now)
      end
    end

    it 'sets #ondisk_size_bytes_end after reloading the index record' do
      new_size = 4711
      expect(action.index).to receive(:reload).ordered
      expect(action.index).to receive(:ondisk_size_bytes).and_return(new_size).ordered

      subject

      expect(action.ondisk_size_bytes_end).to eq(new_size)
    end

    context 'setting #state' do
      it 'sets #state to finished if not given' do
        action.state = nil

        subject

        expect(action).to be_finished
      end

      it 'sets #state to finished if not set to started' do
        action.state = :started

        subject

        expect(action).to be_finished
      end

      it 'does not change state if set to failed' do
        action.state = :failed

        expect { subject }.not_to change { action.state }
      end
    end

    it 'saves the record' do
      expect(action).to receive(:save!)

      subject
    end
  end
end
