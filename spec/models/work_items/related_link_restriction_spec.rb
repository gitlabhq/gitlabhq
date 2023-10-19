# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::RelatedLinkRestriction, feature_category: :portfolio_management do
  describe 'associations' do
    it { is_expected.to belong_to(:source_type) }
    it { is_expected.to belong_to(:target_type) }
  end

  describe 'validations' do
    before do
      # delete seeded records to prevent non-unique record error
      described_class.delete_all
    end

    subject { build(:related_link_restriction) }

    it { is_expected.to validate_presence_of(:source_type) }
    it { is_expected.to validate_presence_of(:target_type) }
    it { is_expected.to validate_uniqueness_of(:target_type).scoped_to([:source_type_id, :link_type]) }
  end

  describe '.link_type' do
    it { is_expected.to define_enum_for(:link_type).with_values(relates_to: 0, blocks: 1) }
  end
end
