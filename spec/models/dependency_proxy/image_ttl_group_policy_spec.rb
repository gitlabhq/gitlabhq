# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DependencyProxy::ImageTtlGroupPolicy, type: :model do
  describe 'relationships' do
    it { is_expected.to belong_to(:group) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:group) }

    describe '#ttl' do
      it { is_expected.to validate_numericality_of(:ttl).allow_nil.is_greater_than(0) }
    end
  end

  describe '.enabled' do
    it 'returns policies that are enabled' do
      enabled_policy = create(:image_ttl_group_policy)
      create(:image_ttl_group_policy, :disabled)

      expect(described_class.enabled).to contain_exactly(enabled_policy)
    end
  end
end
