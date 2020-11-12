# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Tracker, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:entity).required }
  end

  describe 'validations' do
    before do
      create(:bulk_import_tracker)
    end

    it { is_expected.to validate_presence_of(:relation) }
    it { is_expected.to validate_uniqueness_of(:relation).scoped_to(:bulk_import_entity_id) }

    context 'when has_next_page is true' do
      it "validates presence of `next_page`" do
        tracker = build(:bulk_import_tracker, has_next_page: true)

        expect(tracker).not_to be_valid
        expect(tracker.errors).to include(:next_page)
      end
    end
  end
end
