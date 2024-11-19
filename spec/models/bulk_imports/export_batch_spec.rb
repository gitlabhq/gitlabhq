# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::ExportBatch, type: :model, feature_category: :importers do
  describe 'associations' do
    it { is_expected.to belong_to(:export) }
    it { is_expected.to have_one(:upload) }
  end

  describe 'validations' do
    subject { build(:bulk_import_export_batch) }

    it { is_expected.to validate_presence_of(:batch_number) }
    it { is_expected.to validate_uniqueness_of(:batch_number).scoped_to(:export_id) }
  end

  describe 'scopes' do
    describe '.in_progress' do
      it 'returns only batches that are in progress' do
        created = create(:bulk_import_export_batch, :created)
        started = create(:bulk_import_export_batch, :started)
        create(:bulk_import_export_batch, :finished)
        create(:bulk_import_export_batch, :failed)

        expect(described_class.in_progress).to contain_exactly(created, started)
      end
    end
  end

  describe '.started_and_not_timed_out' do
    subject(:started_and_not_timed_out) { described_class.started_and_not_timed_out }

    let_it_be(:recently_started_export_batch) { create(:bulk_import_export_batch, :started, updated_at: 1.minute.ago) }
    let_it_be(:old_started_export_batch) { create(:bulk_import_export_batch, :started, updated_at: 2.hours.ago) }
    let_it_be(:recently_finished_export_batch) do
      create(:bulk_import_export_batch, :finished, updated_at: 1.minute.ago)
    end

    it 'returns records with status started, which were last updated less that 1 hour ago' do
      is_expected.to contain_exactly(recently_started_export_batch)
    end
  end
end
