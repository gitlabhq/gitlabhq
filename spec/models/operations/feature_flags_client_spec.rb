# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Operations::FeatureFlagsClient do
  subject { create(:operations_feature_flags_client) }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
  end

  describe '#token' do
    it "ensures that token is always set" do
      expect(subject.token).not_to be_empty
    end
  end
end
