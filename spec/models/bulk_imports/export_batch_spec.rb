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
end
