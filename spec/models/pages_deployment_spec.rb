# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PagesDeployment do
  describe 'associations' do
    it { is_expected.to belong_to(:project).required }
    it { is_expected.to belong_to(:ci_build).optional }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:file) }
    it { is_expected.to validate_presence_of(:size) }
    it { is_expected.to validate_numericality_of(:size).only_integer.is_greater_than(0) }
    it { is_expected.to validate_inclusion_of(:file_store).in_array(ObjectStorage::SUPPORTED_STORES) }

    it 'is valid when created from the factory' do
      expect(create(:pages_deployment)).to be_valid
    end
  end
end
