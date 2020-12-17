# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Failure, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:entity).required }
  end

  describe 'validations' do
    before do
      create(:bulk_import_failure)
    end

    it { is_expected.to validate_presence_of(:entity) }
  end
end
