# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::HierarchyRestriction do
  describe 'associations' do
    it { is_expected.to belong_to(:parent_type) }
    it { is_expected.to belong_to(:child_type) }
  end

  describe 'validations' do
    subject { build(:hierarchy_restriction) }

    it { is_expected.to validate_presence_of(:parent_type) }
    it { is_expected.to validate_presence_of(:child_type) }
    it { is_expected.to validate_uniqueness_of(:child_type).scoped_to(:parent_type_id) }
  end
end
