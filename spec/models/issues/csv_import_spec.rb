# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issues::CsvImport, feature_category: :importers do
  describe 'associations' do
    it { is_expected.to belong_to(:project).required }
    it { is_expected.to belong_to(:user).required }
  end
end
