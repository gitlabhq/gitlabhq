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
end
