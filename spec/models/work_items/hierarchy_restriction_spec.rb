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

  describe '#clear_parent_type_cache!' do
    subject(:hierarchy_restriction) { build(:hierarchy_restriction) }

    context 'when a hierarchy restriction is saved' do
      it 'calls #clear_reactive_cache! on parent type' do
        expect(hierarchy_restriction.parent_type).to receive(:clear_reactive_cache!).once

        hierarchy_restriction.save!
      end
    end

    context 'when a hierarchy restriction is destroyed' do
      it 'calls #clear_reactive_cache! on parent type' do
        expect(hierarchy_restriction.parent_type).to receive(:clear_reactive_cache!).once

        hierarchy_restriction.destroy!
      end
    end
  end
end
