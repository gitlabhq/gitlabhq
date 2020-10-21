# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Configuration, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:bulk_import).required }
  end

  describe 'validations' do
    it { is_expected.to validate_length_of(:url).is_at_most(255) }
    it { is_expected.to validate_length_of(:access_token).is_at_most(255) }

    it { is_expected.to validate_presence_of(:url) }
    it { is_expected.to validate_presence_of(:access_token) }
  end
end
