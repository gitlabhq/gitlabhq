# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::SchemaValidation::SchemaInconsistency, type: :model, feature_category: :database do
  it { is_expected.to be_a ApplicationRecord }

  describe 'associations' do
    it { is_expected.to belong_to(:issue) }
  end

  describe "Validations" do
    it { is_expected.to validate_presence_of(:object_name) }
    it { is_expected.to validate_presence_of(:valitador_name) }
    it { is_expected.to validate_presence_of(:table_name) }
  end
end
