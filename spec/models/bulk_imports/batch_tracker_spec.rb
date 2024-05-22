# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::BatchTracker, type: :model, feature_category: :importers do
  describe 'associations' do
    it { is_expected.to belong_to(:tracker) }
  end

  describe 'validations' do
    subject { build(:bulk_import_batch_tracker) }

    it { is_expected.to validate_presence_of(:batch_number) }
    it { is_expected.to validate_uniqueness_of(:batch_number).scoped_to(:tracker_id) }
  end

  describe 'scopes' do
    describe '.in_progress' do
      it 'returns only batches that are in progress' do
        created = create(:bulk_import_batch_tracker, :created)
        started = create(:bulk_import_batch_tracker, :started)
        create(:bulk_import_batch_tracker, :finished)
        create(:bulk_import_batch_tracker, :timeout)
        create(:bulk_import_batch_tracker, :failed)
        create(:bulk_import_batch_tracker, :skipped)

        expect(described_class.in_progress).to contain_exactly(created, started)
      end
    end
  end

  describe 'batch canceling' do
    it 'marks batch as canceled' do
      batch = create(:bulk_import_batch_tracker, :created)

      batch.cancel!

      expect(batch.reload.canceled?).to eq(true)
    end
  end
end
